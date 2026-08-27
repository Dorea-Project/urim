import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/network/dio_client.dart';
import 'package:urim/core/result/cached.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/data/datasources/pending_gestures_local_data_source.dart';
import 'package:urim/data/datasources/turn_cache_local_data_source.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/data/repositories/demo_urim_engine.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/preparation/gesture_outcome.dart';
import 'package:urim/domain/entities/preparation/pending_gesture.dart';
import 'package:urim/domain/entities/bible/passage_detail.dart';
import 'package:urim/domain/entities/preparation/articulation.dart';
import 'package:urim/domain/entities/preparation/preached.dart';
import 'package:urim/domain/entities/preparation/deliverable.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/repositories/study_repository.dart';

/// Le moteur tel que le serveur le tient.
final class RemoteStudyRepository implements StudyRepository {
  const RemoteStudyRepository(
    this._source,
    this._cache,
    this._file,
    this._ids,
  );

  final UrimRemoteDataSource _source;
  final TurnCacheLocalDataSource _cache;
  final PendingGesturesLocalDataSource _file;

  /// Tire les clés d'idempotence des paroles.
  final IdGenerator _ids;

  @override
  Future<Cached<Study>?> cachedById(String studyId) async {
    final garde = await _cache.readStudy(studyId);
    if (garde == null) return null;

    try {
      return Cached.at(
        studyFromWire(garde.body as Map<String, dynamic>),
        garde.at,
      );
    } catch (_) {
      // Un tour garde par une version plus ancienne du contrat : on repart du
      // serveur plutot que de rendre un ecran de travers.
      return null;
    }
  }

  @override
  Future<Cached<List<StudySummary>>?> cachedFeed() async {
    final garde = await _cache.readFeed();
    if (garde == null) return null;

    try {
      return Cached.at(feedFromWire(garde.body as List<dynamic>), garde.at);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<List<StudySummary>>> listMine() =>
      _guard(_source.listStudies);

  @override
  Future<Result<Study>> open({
    required String rawInput,
    DateTime? serviceDate,
  }) =>
      _guard(() => _source.open(rawInput: rawInput, serviceDate: serviceDate));

  @override
  Future<Result<Study>> getById(String studyId) =>
      _guard(() => _source.getStudy(studyId));

  @override
  Future<Result<Study>> setElements({
    required String studyId,
    required List<PlanElement> elements,
  }) =>
      _guard(() => _source.setElements(studyId: studyId, elements: elements));

  @override
  Future<Result<Study>> setSupports({
    required String studyId,
    required List<String> supports,
  }) =>
      _guard(() => _source.setSupports(studyId: studyId, supports: supports));

  @override
  Future<Result<Study>> promote({
    required String studyId,
    required String entryId,
    String? elementCode,
    int? ordinal,
  }) =>
      _guard(
        () => _source.promote(
          studyId: studyId,
          entryId: entryId,
          elementCode: elementCode,
          ordinal: ordinal,
        ),
      );

  @override
  Future<Result<Articulation>> articulate({
    required String studyId,
    required String elementCode,
    required int ordinal,
  }) =>
      _guard(
        () => _source.articulate(
          studyId: studyId,
          elementCode: elementCode,
          ordinal: ordinal,
        ),
      );

  @override
  Future<Result<PreachedSermon>> markPreached({
    required String studyId,
    DateTime? preachedOn,
  }) =>
      _guard(
        () => _source.markPreached(studyId: studyId, preachedOn: preachedOn),
      );

  @override
  Future<Result<PreachedSermon>> recordPreached({
    required String reference,
    required DateTime preachedOn,
    String? axisCode,
    String? theme,
  }) =>
      _guard(
        () => _source.recordPreached(
          reference: reference,
          preachedOn: preachedOn,
          axisCode: axisCode,
          theme: theme,
        ),
      );

  @override
  Future<Result<List<PreachedSermon>>> listPreached() =>
      _guard(_source.listPreached);

  @override
  Future<Result<PreachingCoverage>> preachingCoverage() =>
      _guard(_source.preachingCoverage);

  @override
  Future<Result<Deliverable>> submitDeliverable({
    required String studyId,
    required String kind,
    List<Slide> slides = const [],
  }) =>
      _guard(
        () => _source.submitDeliverable(
          studyId: studyId,
          kind: kind,
          slides: slides,
        ),
      );

  @override
  Future<Result<DeliverableFile>> downloadDeliverable(String deliverableId) =>
      _guard(() => _source.downloadDeliverable(deliverableId));

  @override
  Future<Result<PassageDetail>> explorePassage(String reference) =>
      _guard(() => _source.explorePassage(reference));

  @override
  Future<Result<Concordance>> concordance(String lemma) =>
      _guard(() => _source.concordance(lemma));

  @override
  Future<Result<GestureOutcome>> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
    String label = '',
  }) =>
      _geste(
        studyId,
        PendingGesture(
          kind: PendingGestureKind.decide,
          stageCode: stageCode,
          optionCode: optionCode,
          label: label,
        ),
      );

  @override
  Future<Result<GestureOutcome>> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) =>
      _geste(
        studyId,
        PendingGesture(
          kind: PendingGestureKind.dismiss,
          stageCode: stageCode,
          optionCode: optionCode,
        ),
      );

  @override
  Future<List<PendingGesture>> pending(String studyId) => _file.read(studyId);

  /// Envoie, ou note.
  ///
  /// ⚠️ **Seul un manque de reseau est mis en file.** Un refus du serveur — un
  /// etage qui n'attend plus, une option inconnue — est un jugement, pas un
  /// contretemps : le renvoyer plus tard ne le rendrait pas acceptable, et
  /// l'accumuler ferait une file qui ne se videra jamais.
  Future<Result<GestureOutcome>> _geste(
    String studyId,
    PendingGesture geste,
  ) async {
    // Ce qui attendait part d'abord : l'ordre d'emission est ce qui rend le
    // rejeu equivalent a une seance en ligne.
    if (await flush(studyId) case Failed(:final failure)) {
      if (failure is NetworkFailure) {
        await _file.append(studyId, geste);
        return const Result.success(Queued());
      }
      return Result.failed(failure);
    }

    final envoi = await _guard(() => _envoyer(studyId, geste));

    return envoi.fold(
      onSuccess: (study) => Result.success(Served(study)),
      onFailure: (failure) async {
        if (failure is! NetworkFailure) return Result.failed(failure);
        await _file.append(studyId, geste);
        return const Result.success(Queued());
      },
    );
  }

  Future<Study> _envoyer(String studyId, PendingGesture geste) =>
      switch (geste.kind) {
        PendingGestureKind.decide => _source.decide(
            studyId: studyId,
            stageCode: geste.stageCode,
            optionCode: geste.optionCode,
          ),
        PendingGestureKind.dismiss => _source.dismiss(
            studyId: studyId,
            stageCode: geste.stageCode,
            optionCode: geste.optionCode,
          ),
        PendingGestureKind.say => _source.say(
            studyId: studyId,
            rawInput: geste.text,
            idempotencyKey: geste.key,
          ),
      };

  @override
  Future<Result<Study>?> flush(String studyId) async {
    final file = await _file.read(studyId);
    if (file.isEmpty) return null;

    Study? dernier;
    final reste = [...file];

    for (final geste in file) {
      final envoi = await _guard(() => _envoyer(studyId, geste));

      if (envoi case Failed(:final failure)) {
        // Ce qui est parti ne doit pas repartir ; ce qui reste attend.
        await _remplacer(studyId, reste);
        return Result.failed(failure);
      }

      dernier = envoi.valueOrNull;
      reste.removeAt(0);
    }

    await _file.clear(studyId);
    return dernier == null ? null : Result.success(dernier);
  }

  Future<void> _remplacer(String studyId, List<PendingGesture> reste) async {
    await _file.clear(studyId);
    for (final geste in reste) {
      await _file.append(studyId, geste);
    }
  }

  @override
  Future<Result<GestureOutcome>> say({
    required String studyId,
    required String rawInput,
  }) =>
      _geste(
        studyId,
        PendingGesture(
          kind: PendingGestureKind.say,
          text: rawInput,
          // ⚠️ Tirée **maintenant**, et gardée avec le geste. La tirer à
          // l'envoi la rendrait différente à chaque tentative, donc inutile.
          key: 'urim-${_ids.newId()}',
        ),
      );
}

/// Le moteur de démonstration, adossé au magasin en mémoire.
///
/// Il existe pour que l'application compilée reste parcourable sans serveur —
/// même raison que les identifiants de démonstration. Le magasin tient le fil,
/// [DemoUrimEngine] tient les tours ; les deux se rejoignent sur l'identifiant
/// de la préparation.
final class MockStudyRepository implements StudyRepository {
  MockStudyRepository(this._preparations);

  /// Le mannequin ne garde rien, et c'est juste : son magasin **est** en
  /// memoire. Rendre nul dit « rien de garde », et l'ecran passe par le chemin
  /// normal — instantane de toute facon.
  @override
  Future<Cached<Study>?> cachedById(String studyId) async => null;

  @override
  Future<Cached<List<StudySummary>>?> cachedFeed() async => null;

  final InMemoryPreparationRepository _preparations;
  final DemoUrimEngine _engine = DemoUrimEngine();

  @override
  Future<Result<List<StudySummary>>> listMine() async {
    // La première émission suffit : le fil se relit sur demande, il ne
    // s'abonne pas. C'est le contrat que le serveur peut tenir.
    final result = await _preparations.watchPreparations().first;

    return result.fold(
      onSuccess: (preparations) =>
          Result.success(preparations.map(_project).toList()),
      onFailure: (failure) => Result.failed(failure),
    );
  }

  @override
  Future<Result<Study>> open({
    required String rawInput,
    DateTime? serviceDate,
  }) async {
    final result = await _preparations.open(
      text: rawInput,
      serviceDate: serviceDate,
    );

    return result.fold(
      onSuccess: (preparation) =>
          Result.success(_engine.open(preparation.id, rawInput.trim())),
      onFailure: (failure) => Result.failed(failure),
    );
  }

  @override
  Future<Result<Study>> getById(String studyId) =>
      _avec(studyId, (titre) => _engine.read(studyId, titre));

  @override
  Future<Result<Study>> setElements({
    required String studyId,
    required List<PlanElement> elements,
  }) =>
      _avec(studyId, (titre) => _engine.setElements(studyId, titre, elements));

  /// Le mannequin n'a pas de corpus : il ne peut ni résoudre une référence ni
  /// dire qu'elle n'existe pas. Il garde les saisies telles quelles.
  @override
  Future<Result<Study>> setSupports({
    required String studyId,
    required List<String> supports,
  }) =>
      _avec(studyId, (titre) => _engine.read(studyId, titre));

  /// Le mannequin ne produit **aucun document** : il n'a ni corpus à
  /// confronter, ni écrivain de fichier. Dire non est la seule réponse vraie —
  /// fabriquer un `.docx` de démonstration ferait croire à un contrôle qui n'a
  /// pas eu lieu.
  /// Le mannequin n'a pas de fil persisté : il n'y a rien à promouvoir.
  @override
  Future<Result<Study>> promote({
    required String studyId,
    required String entryId,
    String? elementCode,
    int? ordinal,
  }) async =>
      const Result.failed(
        ServerFailure(message: 'Le mode démonstration ne garde pas le fil.'),
      );

  /// Le mannequin n'a pas de modèle, et le dire est **la bonne réponse** :
  /// `disponible: false` est un état de production, pas une panne. Rendre une
  /// `Failure` ferait apparaître un écran d'erreur là où le produit promet que
  /// l'atelier fonctionne sans.
  @override
  Future<Result<Articulation>> articulate({
    required String studyId,
    required String elementCode,
    required int ordinal,
  }) async =>
      const Result.success(Articulation.indisponible());

  // -- l'archive ---------------------------------------------------------
  //
  // ⚠️ **Vide, jamais en échec.** Le mannequin n'a pas d'archive : rendre une
  // panne ferait afficher un écran d'erreur là où il n'y a qu'une absence, et
  // le build de démonstration montrerait un défaut qui n'existe pas. Une
  // archive vide est la vérité — ce pasteur-là n'a rien prêché.

  @override
  Future<Result<PreachedSermon>> markPreached({
    required String studyId,
    DateTime? preachedOn,
  }) async =>
      Result.success(
        PreachedSermon(
          id: 'demo-preche-$studyId',
          preachedOn: preachedOn ?? DateTime.now(),
          reference: '',
          preparationId: studyId,
          captureKind: 'saisie',
        ),
      );

  @override
  Future<Result<PreachedSermon>> recordPreached({
    required String reference,
    required DateTime preachedOn,
    String? axisCode,
    String? theme,
  }) async =>
      Result.success(
        PreachedSermon(
          id: 'demo-preche-manuel',
          preachedOn: preachedOn,
          reference: reference,
          axisCode: axisCode,
          theme: theme,
          captureKind: 'import',
        ),
      );

  @override
  Future<Result<List<PreachedSermon>>> listPreached() async =>
      const Result.success([]);

  @override
  Future<Result<PreachingCoverage>> preachingCoverage() async =>
      const Result.success(
        PreachingCoverage(books: [], axes: [], booksUntouched: 0),
      );

  @override
  Future<Result<Deliverable>> submitDeliverable({
    required String studyId,
    required String kind,
    List<Slide> slides = const [],
  }) async =>
      const Result.failed(
        ServerFailure(message: 'Le mode démonstration ne produit pas de document.'),
      );

  @override
  Future<Result<DeliverableFile>> downloadDeliverable(String deliverableId) async =>
      const Result.failed(
        ServerFailure(message: 'Le mode démonstration ne produit pas de document.'),
      );

  /// Le mannequin n'a **pas de corpus**. Rendre un passage inventé serait
  /// exactement ce que D18 interdit : le verset ne vient jamais du modèle.
  @override
  Future<Result<PassageDetail>> explorePassage(String reference) async =>
      const Result.failed(
        ServerFailure(message: 'Le mode démonstration ne porte aucun corpus.'),
      );

  @override
  Future<Result<Concordance>> concordance(String lemma) async =>
      const Result.failed(
        ServerFailure(message: 'Le mode démonstration ne porte aucun corpus.'),
      );

  @override
  Future<Result<GestureOutcome>> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
    String label = '',
  }) async =>
      (await _avec(studyId, (titre) => _engine.decide(studyId, titre, optionCode)))
          .fold(
        onSuccess: (study) => Result.success(Served(study)),
        onFailure: (failure) => Result.failed(failure),
      );

  @override
  Future<Result<GestureOutcome>> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) async =>
      (await _avec(studyId, (titre) => _engine.dismiss(studyId, titre, optionCode)))
          .fold(
        onSuccess: (study) => Result.success(Served(study)),
        onFailure: (failure) => Result.failed(failure),
      );

  /// Le mannequin repond toujours : il n'y a jamais rien en attente.
  @override
  Future<List<PendingGesture>> pending(String studyId) async => const [];

  @override
  Future<Result<Study>?> flush(String studyId) async => null;

  @override
  Future<Result<GestureOutcome>> say({
    required String studyId,
    required String rawInput,
  }) async =>
      (await _avec(studyId, (titre) => _engine.say(studyId, titre, rawInput)))
          .fold(
        onSuccess: (study) => Result.success(Served(study)),
        onFailure: (failure) => Result.failed(failure),
      );

  /// Le titre vient du magasin, le tour du mannequin. Une préparation absente
  /// est une erreur du magasin, pas du moteur : c'est lui qui répond.
  Future<Result<Study>> _avec(
    String studyId,
    Study Function(String rawInput) rendre,
  ) async {
    final result = await _preparations.getById(studyId);

    return result.fold(
      onSuccess: (preparation) {
        // À l'étage où le fil l'annonce, et une seule fois : ce que le pasteur
        // a décidé depuis prime sur l'état d'origine.
        _engine.ensure(preparation.id, outcome: _outcomeOf(preparation.state));
        return Result.success(rendre(_rawInputOf(preparation)));
      },
      onFailure: (failure) => Result.failed(failure),
    );
  }
}

/// Ce que le pasteur a écrit en ouvrant.
///
/// Le magasin de démonstration n'a pas de champ pour cela — il garde un titre
/// tiré des premiers mots. La phrase entière est dans le premier bloc, là où
/// les maquettes l'avaient mise ; le serveur, lui, a un `raw_input`.
String _rawInputOf(Preparation preparation) => switch (
    preparation.blocks.whereType<UserBlock>().firstOrNull) {
      final UserBlock premier => premier.text,
      _ => preparation.title,
    };

Future<Result<T>> _guard<T>(Future<T> Function() action) async {
  try {
    return Result.success(await action());
  } on AppException catch (e) {
    return Result.failed(e.toFailure());
  } catch (e) {
    return Result.failed(UnexpectedFailure(message: e.toString()));
  }
}

StudySummary _project(Preparation preparation) => StudySummary(
      id: preparation.id,
      rawInput: preparation.title,
      theme: preparation.summary.isEmpty ? null : preparation.summary,
      serviceDate: preparation.serviceDate,
      lastOutcome: _outcomeOf(preparation.state),
      lastActivity: preparation.updatedAt,
      origin: preparation.origin,
    );

/// La maquette vers le moteur.
///
/// `feedbackReady` — « Retour disponible » sur une prédication déjà prêchée —
/// n'a **pas** d'équivalent : il ne vient pas du moteur de préparation mais de
/// la branche transcription, qui reste une maquette. Le traduire de force
/// remettrait dans le fil l'état inventé qu'on vient d'en retirer.
TurnOutcome? _outcomeOf(PreparationState state) => switch (state) {
      PreparationState.handsBack => TurnOutcome.handsBack,
      PreparationState.served => TurnOutcome.kept,
      PreparationState.refused => TurnOutcome.refused,
      PreparationState.feedbackReady => null,
    };

/// Qui tient le moteur : le serveur, ou le mannequin de démonstration.
///
/// Même bascule que le parcours d'entrée, et c'est voulu : un build qui ne
/// parle à personne pour entrer ne peut pas non plus lire un fil.
final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  final config = ref.watch(appConfigProvider);

  if (config.useMockAuth) {
    // Le mannequin garde l'état des préparations en cours : le libérer parce
    // que plus personne ne l'écoute effacerait le travail de la session.
    ref.keepAlive();
    return MockStudyRepository(ref.watch(preparationRepositoryProvider));
  }

  final cache = ref.watch(turnCacheProvider);
  return RemoteStudyRepository(
    UrimRemoteDataSource(ref.watch(dioProvider), cache: cache),
    cache,
    ref.watch(pendingGesturesProvider),
    ref.watch(idGeneratorProvider),
  );
});
