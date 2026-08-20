import 'package:dio/dio.dart';
import 'package:urim/core/network/dio_error_mapper.dart';
import 'package:urim/data/datasources/turn_cache_local_data_source.dart';
import 'package:urim/domain/entities/bible/passage_detail.dart';
import 'package:urim/domain/entities/preparation/deliverable.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/entities/preparation/turn.dart';

/// Le moteur Urim, canal mobile : `/api/mobile/urim`.
///
/// Les noms de champs sont ceux du serveur (`raw_input`, `last_outcome`,
/// `stage_code`, `decide_stage`) : la conversion vers le vocabulaire du domaine
/// se fait ici, et nulle part ailleurs.
final class UrimRemoteDataSource {
  const UrimRemoteDataSource(this._dio, {TurnCacheLocalDataSource? cache})
      : _cache = cache;

  final Dio _dio;

  /// Le magasin local, quand il y en a un. C'est **ici** que l'écriture a lieu,
  /// et nulle part ailleurs : c'est le seul endroit qui voit le JSON brut, et
  /// garder le brut plutôt que l'objet analysé évite d'avoir un second code de
  /// sérialisation à tenir d'accord avec le contrat.
  final TurnCacheLocalDataSource? _cache;

  /// `GET /urim/studies` — le fil, sans rejouer le moteur.
  ///
  /// Ce que la réponse ne contient pas : aucune phrase d'Urim. Le serveur s'y
  /// refuse pour ne pas rejouer son pipeline vingt fois, et l'application n'a
  /// donc rien à en attendre.
  Future<List<StudySummary>> listStudies() async {
    final rows = await _get<List<dynamic>>('/urim/studies') ?? const [];
    await _cache?.writeFeed(rows);
    return feedFromWire(rows);
  }

  /// `POST /urim/studies` — une préparation **personnelle**, sans église.
  ///
  /// La route sous `/tenants/{id}` existe aussi et n'est pas dépréciée : elle
  /// dit « je prépare dans l'espace de cette assemblée ». Deux gestes
  /// différents, deux URL ; l'application ne sert que le premier tant qu'elle
  /// ne sait pas rattacher un travail à une église.
  Future<Study> open({required String rawInput, DateTime? serviceDate}) async =>
      _study(await _post('/urim/studies', {
        'raw_input': rawInput,
        if (serviceDate != null) 'service_date': _dayOf(serviceDate),
      }));

  /// `GET /urim/studies/{id}` — la trace est rejouée, jamais relue.
  Future<Study> getStudy(String studyId) async =>
      _study(await _get<Map<String, dynamic>>('/urim/studies/$studyId'));

  /// `POST /urim/studies/{id}/decisions`
  Future<Study> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) async =>
      _study(await _post('/urim/studies/$studyId/decisions', {
        'stage_code': stageCode,
        'option_code': optionCode,
      }));

  /// `POST /urim/studies/{id}/dismissals`
  Future<Study> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) async =>
      _study(await _post('/urim/studies/$studyId/dismissals', {
        'stage_code': stageCode,
        'option_code': optionCode,
      }));

  /// `POST /urim/studies/{id}/turns` — une phrase libre.
  ///
  /// [idempotencyKey] rend la parole rejouable : le serveur qui l'a déjà vue
  /// rend l'état courant sans repasser par son répondeur — donc sans un second
  /// appel de modèle, et sans risquer une autre phrase que celle que le pasteur
  /// a déjà lue.
  Future<Study> say({
    required String studyId,
    required String rawInput,
    String? idempotencyKey,
  }) async =>
      _study(await _post('/urim/studies/$studyId/turns', {
        'raw_input': rawInput,
        'idempotency_key': ?idempotencyKey,
      }));

  /// `PUT /urim/studies/{id}/supports` — la chaîne de textes.
  ///
  /// On envoie **les saisies brutes**, dans la notation du pasteur : `Hb 2v29`,
  /// `Jn14v28`. C'est le serveur qui les lit, parce que c'est lui qui a le
  /// corpus — et une saisie illisible n'interrompt rien, elle revient avec son
  /// motif.
  Future<Study> setSupports({
    required String studyId,
    required List<String> supports,
  }) async =>
      _study(await _put('/urim/studies/$studyId/supports', {
        'supports': supports,
      }));

  /// `PUT /urim/studies/{id}/elements` — le squelette homilétique.
  ///
  /// **L'envoi remplace l'ensemble.** Le serveur n'a pas de geste « effacer une
  /// section » : ne pas envoyer une section, c'est l'effacer. C'est ce qui rend
  /// l'écran simple — il envoie ce qu'il montre — et c'est aussi le piège :
  /// envoyer une liste partielle perdrait le reste du plan.
  Future<Study> setElements({
    required String studyId,
    required List<PlanElement> elements,
  }) async =>
      _study(await _put('/urim/studies/$studyId/elements', {
        'elements': [
          for (final element in elements)
            {
              'element_code': element.code,
              'ordinal': element.ordinal,
              'body': element.body,
            },
        ],
      }));

  /// `POST /urim/studies/{id}/deliverable` — soumettre ce qui sortira.
  ///
  /// **Aucun fichier n'existe encore.** Le contrôle est en amont, parce qu'un
  /// fichier produit est un fichier qui circule : le serveur juge chaque
  /// citation contre toutes les versions détenues, puis dit `conforme` ou
  /// `rejete`. Un rejet revient en 201 avec ses verdicts — c'est ce que le
  /// produit veut montrer, pas une erreur.
  Future<Deliverable> submitDeliverable({
    required String studyId,
    required String kind,
    List<Slide> slides = const [],
  }) async =>
      _deliverable(await _post('/urim/studies/$studyId/deliverable', {
        'kind': kind,
        'diapositives': [
          for (final slide in slides)
            {
              'titre': slide.title,
              'reference': slide.reference,
              'texte_projete': slide.projectedText,
            },
        ],
      }));

  /// `GET /urim/deliverables/{id}/fichier` — les octets.
  ///
  /// Le serveur ne les range nulle part : il les produit à la demande. Un
  /// livrable rejeté rend 409, et c'est le seul endroit où le contrôle devient
  /// un refus — demander les octets de ce qui a été rejeté, c'est demander
  /// précisément ce que le contrôle existe pour ne pas produire.
  Future<DeliverableFile> downloadDeliverable(String deliverableId) async {
    try {
      final reponse = await _dio.get<List<int>>(
        '/urim/deliverables/$deliverableId/fichier',
        options: Options(responseType: ResponseType.bytes),
      );

      return DeliverableFile(
        bytes: reponse.data ?? const [],
        filename: _nomDuFichier(reponse.headers.value('content-disposition')) ??
            'preparation-$deliverableId',
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// `GET /urim/passages?ref=…` — en savoir plus sur un passage.
  ///
  /// Lecture pure : aucune écriture, aucune réservation, aucun appel de
  /// modèle. On peut l'appeler six fois de suite sans conséquence, et c'est ce
  /// qui la distingue d'une ouverture de préparation.
  Future<PassageDetail> explorePassage(String reference) async {
    final json = await _get<Map<String, dynamic>>(
      '/urim/passages?ref=${Uri.encodeQueryComponent(reference)}',
    );

    return _passage(json ?? const {});
  }

  /// `GET /urim/lemmes?lemme=…` — la concordance.
  Future<Concordance> concordance(String lemma) async {
    final json = await _get<Map<String, dynamic>>(
      '/urim/lemmes?lemme=${Uri.encodeQueryComponent(lemma)}',
    );

    final charge = json ?? const {};

    return Concordance(
      lemma: charge['lemma'] as String? ?? lemma,
      language: charge['language'] as String? ?? '',
      total: (charge['total'] as num?)?.toInt() ?? 0,
      occurrences: [
        for (final o in charge['occurrences'] as List<dynamic>? ?? const [])
          Occurrence(
            reference: (o as Map<String, dynamic>)['reference'] as String? ?? '',
            text: o['text'] as String? ?? '',
            surface: o['surface'] as String? ?? '',
            morphology: o['morphology'] as String? ?? '',
          ),
      ],
    );
  }

  PassageDetail _passage(Map<String, dynamic> json) => PassageDetail(
        reference: json['reference'] as String? ?? '',
        units: [
          for (final u in json['units'] as List<dynamic>? ?? const [])
            UnitRef(
              id: (u as Map<String, dynamic>)['id'] as String? ?? '',
              label: u['label'] as String? ?? '',
              reference: u['reference'] as String? ?? '',
              rationale: u['rationale'] as String? ?? '',
            ),
        ],
        pericopeLabel: json['pericope_label'] as String?,
        pericopeRationale: json['pericope_rationale'] as String?,
        reviewedBy: json['reviewed_by'] as String?,
        verses: [
          for (final v in json['verses'] as List<dynamic>? ?? const [])
            ServedVerse(
              reference: (v as Map<String, dynamic>)['reference'] as String? ?? '',
              text: v['text'] as String? ?? '',
            ),
        ],
        bearings: [
          for (final b in json['bearings'] as List<dynamic>? ?? const [])
            AxisBearing(
              axisCode: (b as Map<String, dynamic>)['axis_code'] as String? ?? '',
              label: b['label'] as String? ?? '',
              strength: b['strength'] as String? ?? '',
              rationale: b['rationale'] as String? ?? '',
            ),
        ],
        caveats: [
          for (final c in json['caveats'] as List<dynamic>? ?? const [])
            c as String,
        ],
        context: [
          for (final c in json['context'] as List<dynamic>? ?? const [])
            ContextNote(
              kind: (c as Map<String, dynamic>)['kind'] as String? ?? '',
              body: c['body'] as String? ?? '',
              sourceRef: c['source_ref'] as String? ?? '',
            ),
        ],
        variants: [
          for (final v in json['variants'] as List<dynamic>? ?? const [])
            TextualVariant(
              reference: (v as Map<String, dynamic>)['reference'] as String? ?? '',
              body: v['body'] as String? ?? '',
            ),
        ],
      );

  Future<T?> _get<T>(String path) async {
    try {
      return (await _dio.get<T>(path)).data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      return (await _dio.post<Map<String, dynamic>>(path, data: body)).data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Deliverable _deliverable(Map<String, dynamic>? json) {
    final charge = json ?? const {};

    return Deliverable(
      id: charge['id'] as String? ?? '',
      kind: charge['kind'] as String? ?? '',
      format: charge['format'] as String? ?? '',
      validation: charge['validation'] as String? ?? '',
      controls: [
        for (final c in charge['controles'] as List<dynamic>? ?? const [])
          CitationCheck(
            slideNo: ((c as Map<String, dynamic>)['slide_no'] as num?)?.toInt() ?? 0,
            reference: c['reference'] as String? ?? '',
            projectedText: c['projected_text'] as String? ?? '',
            verdict: c['verdict'] as String? ?? '',
            rationale: c['rationale'] as String? ?? '',
          ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      return (await _dio.put<Map<String, dynamic>>(path, data: body)).data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Analyse la réponse, et **garde le brut au passage**.
  ///
  /// Tous les gestes passent ici — ouvrir, relire, décider, écarter, parler —
  /// donc le tour gardé est toujours le dernier reçu, quel que soit le geste
  /// qui l'a obtenu. C'était la raison de faire de cette fonction une méthode.
  Future<Study> _study(Map<String, dynamic>? json) async {
    if (json == null) {
      throw const FormatException('Le serveur n\'a rendu aucune préparation.');
    }

    final etude = studyFromWire(json);
    await _cache?.writeStudy(etude.id, json);
    return etude;
  }
}

/// L'analyse d'une préparation, séparée du transport.
///
/// Publique pour une raison précise : les tests d'écran sont nourris par des
/// **charges réelles capturées** contre le moteur, et un test de widget
/// contrôle le temps — y attendre une requête, même simulée, ne se termine
/// jamais. Les faire passer par une autre porte que celle-ci reviendrait à
/// éprouver un décodage qui n'est pas celui de production.
Study studyFromWire(Map<String, dynamic> json) => _studyFromJson(json);

/// Le fil, même raison.
List<StudySummary> feedFromWire(List<dynamic> rows) => [
      for (final row in rows) _summaryFromJson(row as Map<String, dynamic>),
    ];

// ---------------------------------------------------------------------------
// Le fil
// ---------------------------------------------------------------------------

StudySummary _summaryFromJson(Map<String, dynamic> json) {
  final lastTurn = _dateFrom(json['last_turn_at']);
  final opened = _dateFrom(json['opened_at']);

  return StudySummary(
    id: json['id'] as String,
    rawInput: json['raw_input'] as String? ?? '',
    pericopeLabel: json['pericope_label'] as String?,
    theme: json['theme'] as String?,
    serviceDate: _dateFrom(json['service_date']),
    lastOutcome: TurnOutcome.fromWire(json['last_outcome'] as String?),
    // Le dernier tour, à défaut l'ouverture : une préparation créée à
    // l'instant n'a pas de tour, et tomberait en fin de fil alors qu'elle
    // vient de naître. Le serveur trie déjà ainsi ; on le redit ici parce que
    // le regroupement par récence s'appuie dessus.
    lastActivity: lastTurn ?? opened ?? DateTime.now(),
    isClosed: json['status'] == 'close',
    // Le moteur ne connaît que les préparations écrites : sa capture est
    // verrouillée à l'étape 1. Tout ce qui vient du serveur est donc écrit.
    origin: PreparationOrigin.written,
  );
}

// ---------------------------------------------------------------------------
// La préparation et son tour
// ---------------------------------------------------------------------------

Study _studyFromJson(Map<String, dynamic> json) => Study(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'ouverte',
      rawInput: json['raw_input'] as String? ?? '',
      outcome: TurnOutcome.fromWire(json['outcome'] as String?),
      theme: json['theme'] as String?,
      pericopeLabel: json['pericope_label'] as String?,
      axisCode: json['axis_code'] as String?,
      boundsOverridden: json['bounds_overridden'] == true,
      corpusDrifted: json['corpus_drifted'] == true,
      verses: [
        for (final v in json['verses'] as List<dynamic>? ?? const [])
          ServedVerse(
            reference: (v as Map<String, dynamic>)['reference'] as String? ?? '',
            text: v['text'] as String? ?? '',
          ),
      ],
      context: [
        for (final c in json['context'] as List<dynamic>? ?? const [])
          ContextNote(
            kind: (c as Map<String, dynamic>)['kind'] as String? ?? '',
            body: c['body'] as String? ?? '',
            sourceRef: c['source_ref'] as String? ?? '',
          ),
      ],
      elements: [
        for (final e in json['elements'] as List<dynamic>? ?? const [])
          PlanElement(
            code: (e as Map<String, dynamic>)['element_code'] as String? ?? '',
            ordinal: (e['ordinal'] as num?)?.toInt() ?? 0,
            body: e['body'] as String?,
          ),
      ],
      supports: [
        for (final s in json['supports'] as List<dynamic>? ?? const [])
          SupportText(
            raw: (s as Map<String, dynamic>)['raw'] as String? ?? '',
            reference: s['reference'] as String? ?? '',
            text: s['text'] as String? ?? '',
            verdict: s['verdict'] as String? ?? '',
          ),
      ],
      turn: switch (json['turn']) {
        final Map<String, dynamic> turn => _turnFromJson(turn),
        _ => null,
      },
    );

Turn _turnFromJson(Map<String, dynamic> json) => Turn(
      say: json['say'] as String? ?? '',
      why: json['why'] as String? ?? '',
      ask: json['ask'] as String? ?? '',
      expects: TurnExpects.fromWire(json['expects'] as String?),
      stageCode: json['stage_code'] as String? ?? '',
      signature: json['signature'] as String?,
      speaks: json['speaks'] as String? ?? '',
      blocks: [
        for (final block in json['blocks'] as List<dynamic>? ?? const [])
          _blockFromJson(block as Map<String, dynamic>),
      ],
    );

/// Un `kind` inconnu devient [UnknownBlock] plutôt qu'une exception : le moteur
/// gagne des étages, une application installée ne les gagne pas en même temps.
/// Le reste du tour doit rester lisible.
TurnBlock _blockFromJson(Map<String, dynamic> json) =>
    switch (json['kind'] as String? ?? '') {
      'chips' => ChipsBlock(_chips(json['items'])),
      'units' => UnitsBlock([
          for (final group in json['groups'] as List<dynamic>? ?? const [])
            _groupFromJson(group as Map<String, dynamic>),
        ]),
      'bounds' => BoundsBlock(
          items: _chips(json['items']),
          consequence: json['consequence'] as String? ?? '',
        ),
      'bearings' => BearingsBlock(
          items: [
            for (final item in json['items'] as List<dynamic>? ?? const [])
              _bearingFromJson(item as Map<String, dynamic>),
          ],
          caveats: [
            for (final caveat in json['caveats'] as List<dynamic>? ?? const [])
              caveat as String,
          ],
          decideStage: json['decide_stage'] as String? ?? 'bear_axes',
        ),
      'feasibility' => FeasibilityBlock([
          for (final item in json['items'] as List<dynamic>? ?? const [])
            _feasibilityFromJson(item as Map<String, dynamic>),
        ]),
      'theme' => ThemeBlock(json['body'] as String? ?? ''),
      'actions' => ActionsBlock([
          for (final item in json['items'] as List<dynamic>? ?? const [])
            _actionFromJson(item as Map<String, dynamic>),
        ]),
      final String kind => UnknownBlock(kind),
    };

List<ChipItem> _chips(Object? items) => [
      for (final item in items as List<dynamic>? ?? const [])
        _chipFromJson(item as Map<String, dynamic>),
    ];

ChipItem _chipFromJson(Map<String, dynamic> json) => ChipItem(
      code: json['code'] as String,
      label: json['label'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      origin: json['origin'] as String? ?? 'moteur',
      selected: json['selected'] == true,
      signature: json['signature'] as String?,
    );

UnitGroup _groupFromJson(Map<String, dynamic> json) => UnitGroup(
      role: json['role'] as String? ?? '',
      heading: json['heading'] as String? ?? '',
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          _unitFromJson(item as Map<String, dynamic>),
      ],
    );

UnitItem _unitFromJson(Map<String, dynamic> json) => UnitItem(
      code: json['code'] as String,
      label: json['label'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      rationale: json['rationale'] as String? ?? '',
    );

BearingItem _bearingFromJson(Map<String, dynamic> json) => BearingItem(
      axisCode: json['axis_code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      rationale: json['rationale'] as String? ?? '',
      selected: json['selected'] == true,
      selectable: json['selectable'] == true,
    );

FeasibilityItem _feasibilityFromJson(Map<String, dynamic> json) =>
    FeasibilityItem(
      planSource: json['plan_source'] as String? ?? '',
      subjectMatter: json['subject_matter'] as String? ?? '',
      feasible: json['feasible'] == true,
      risk: json['risk'] as String? ?? '',
      rationale: json['rationale'] as String? ?? '',
    );

ActionItem _actionFromJson(Map<String, dynamic> json) => ActionItem(
      code: json['code'] as String,
      label: json['label'] as String? ?? '',
      enabled: json['enabled'] == true,
      unavailableReason: json['unavailable_reason'] as String? ?? '',
    );

DateTime? _dateFrom(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// Une date de culte est un **jour**, pas un instant : l'envoyer avec une heure
/// la déplacerait d'un fuseau à l'autre.
String _dayOf(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Le nom que le serveur donne au fichier, lu dans `Content-Disposition`.
///
/// Il porte l'extension réelle — et c'est elle qui compte : le serveur peut
/// servir le format natif quand la conversion PDF échoue, *aucun mur un
/// vendredi soir*. Le client lit donc ce qu'il reçoit, jamais ce qu'il a
/// demandé.
String? _nomDuFichier(String? disposition) {
  if (disposition == null) return null;

  final trouve = RegExp('filename="([^"]+)"').firstMatch(disposition);

  return trouve?.group(1);
}
