import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/network/dio_client.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/repositories/study_repository.dart';

/// Le fil tel que le serveur le tient.
final class RemoteStudyRepository implements StudyRepository {
  const RemoteStudyRepository(this._source);

  final UrimRemoteDataSource _source;

  @override
  Future<Result<List<StudySummary>>> listMine() async {
    try {
      return Result.success(await _source.listStudies());
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }
}

/// Le fil de démonstration, projeté depuis le magasin en mémoire.
///
/// Il existe pour que l'application compilée reste parcourable sans serveur —
/// même raison que les identifiants de démonstration. Ce qu'il ne fait pas :
/// inventer un vocabulaire. Il traduit les états de la maquette vers ceux du
/// moteur, et laisse vide ce que le moteur ne sait pas dire.
final class MockStudyRepository implements StudyRepository {
  const MockStudyRepository(this._preparations);

  final InMemoryPreparationRepository _preparations;

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

/// Qui tient le fil : le serveur, ou le magasin de démonstration.
///
/// Même bascule que le parcours d'entrée, et c'est voulu : un build qui ne
/// parle à personne pour entrer ne peut pas non plus lire un fil.
final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  final config = ref.watch(appConfigProvider);

  if (config.useMockAuth) {
    return MockStudyRepository(ref.watch(preparationRepositoryProvider));
  }

  return RemoteStudyRepository(UrimRemoteDataSource(ref.watch(dioProvider)));
});
