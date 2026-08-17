import 'package:dio/dio.dart';
import 'package:urim/core/network/dio_error_mapper.dart';
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
  const UrimRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /urim/studies` — le fil, sans rejouer le moteur.
  ///
  /// Ce que la réponse ne contient pas : aucune phrase d'Urim. Le serveur s'y
  /// refuse pour ne pas rejouer son pipeline vingt fois, et l'application n'a
  /// donc rien à en attendre.
  Future<List<StudySummary>> listStudies() async =>
      feedFromWire(await _get<List<dynamic>>('/urim/studies') ?? const []);

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
  Future<Study> say({
    required String studyId,
    required String rawInput,
  }) async =>
      _study(await _post('/urim/studies/$studyId/turns', {
        'raw_input': rawInput,
      }));

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
}

Study _study(Map<String, dynamic>? json) {
  if (json == null) {
    throw const FormatException('Le serveur n\'a rendu aucune préparation.');
  }
  return studyFromWire(json);
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
