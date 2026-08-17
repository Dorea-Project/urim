import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/network/dio_client.dart';
import 'package:urim/core/result/cached.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/data/datasources/turn_cache_local_data_source.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/data/repositories/demo_urim_engine.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/repositories/study_repository.dart';

/// Le moteur tel que le serveur le tient.
final class RemoteStudyRepository implements StudyRepository {
  const RemoteStudyRepository(this._source, this._cache);

  final UrimRemoteDataSource _source;
  final TurnCacheLocalDataSource _cache;

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
  Future<Result<Study>> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) =>
      _guard(() => _source.decide(
            studyId: studyId,
            stageCode: stageCode,
            optionCode: optionCode,
          ));

  @override
  Future<Result<Study>> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) =>
      _guard(() => _source.dismiss(
            studyId: studyId,
            stageCode: stageCode,
            optionCode: optionCode,
          ));

  @override
  Future<Result<Study>> say({
    required String studyId,
    required String rawInput,
  }) =>
      _guard(() => _source.say(studyId: studyId, rawInput: rawInput));
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
  Future<Result<Study>> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) =>
      _avec(studyId, (titre) => _engine.decide(studyId, titre, optionCode));

  @override
  Future<Result<Study>> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) =>
      _avec(studyId, (titre) => _engine.dismiss(studyId, titre, optionCode));

  @override
  Future<Result<Study>> say({
    required String studyId,
    required String rawInput,
  }) =>
      _avec(studyId, (titre) => _engine.say(studyId, titre, rawInput));

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
  );
});
