import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/turn.dart';
import 'package:urim/domain/repositories/study_repository.dart';
import 'package:urim/presentation/home/home_view_model.dart';

/// Ce qui s'affiche dans le fil.
///
/// **Le serveur n'a pas d'historique de conversation, et n'en aura pas.** Le
/// moteur rejoue son pipeline à chaque lecture : ce qu'une préparation garde,
/// ce sont les décisions du pasteur, pas les phrases. Il n'existe donc qu'un
/// tour à un instant donné — le tour courant.
///
/// Ce que cette classe ajoute est un **compte rendu de séance** : ce que le
/// pasteur vient de dire, et les tours qu'il a reçus depuis qu'il a ouvert
/// l'écran. Rien de tout cela n'est persisté, et c'est honnête ainsi — rouvrir
/// la préparation demain rendra ce que le moteur en dit demain, pas la
/// conversation d'aujourd'hui.
sealed class ThreadEntry {
  const ThreadEntry();
}

/// Ce que le pasteur a dit — écrit, ou touché.
final class SpokenByPastor extends ThreadEntry {
  const SpokenByPastor(this.text);

  final String text;
}

/// Un tour rendu par le moteur.
final class ServedTurn extends ThreadEntry {
  const ServedTurn(this.turn, {required this.live});

  final Turn turn;

  /// Seul le dernier tour est vivant. Les précédents restent lisibles, mais
  /// leurs gestes ne mènent plus nulle part : le moteur a avancé, et répondre
  /// à un tour passé enverrait une décision à un étage qui n'attend plus.
  final bool live;
}

/// L'état de l'écran : la préparation, et le compte rendu de la séance.
final class ThreadState {
  const ThreadState({required this.study, this.entries = const []});

  final Study study;
  final List<ThreadEntry> entries;

  Turn? get turn => study.turn;
}

/// Une préparation ouverte, et ce qui s'est dit depuis.
final class PreparationThread extends AsyncNotifier<ThreadState> {
  PreparationThread(this.studyId);

  final String studyId;

  @override
  Future<ThreadState> build() async {
    final result = await ref.watch(studyRepositoryProvider).getById(studyId);

    return result.fold(
      onSuccess: (study) => ThreadState(
        study: study,
        entries: [
          // Ce que le pasteur a écrit en ouvrant — la seule chose qu'il ait
          // dite que le serveur garde vraiment. Tout le reste de ce qu'il dit
          // vit dans ses décisions, pas dans des phrases.
          if (study.rawInput.isNotEmpty) SpokenByPastor(study.rawInput),
          if (study.turn case final Turn turn) ServedTurn(turn, live: true),
        ],
      ),
      onFailure: (failure) => throw failure,
    );
  }

  /// Répondre à un étage qui rend la main.
  ///
  /// [stageCode] n'est pas toujours celui du tour : les pesées portent le leur.
  /// C'est le bloc qui le dit, pas l'écran — l'envoyer au mauvais étage vaut un
  /// refus du serveur.
  Future<Failure?> decide({
    required String stageCode,
    required String optionCode,
    required String label,
  }) =>
      _geste(
        said: label,
        action: (repository, studyId) => repository.decide(
          studyId: studyId,
          stageCode: stageCode,
          optionCode: optionCode,
        ),
      );

  /// Écarter une option. Aucun étage n'avance ; le tour suivant ne la
  /// reproposera pas.
  Future<Failure?> dismiss({
    required String stageCode,
    required String optionCode,
  }) =>
      _geste(
        action: (repository, studyId) => repository.dismiss(
          studyId: studyId,
          stageCode: stageCode,
          optionCode: optionCode,
        ),
      );

  /// Parler. Une phrase libre, à n'importe quel moment.
  Future<Failure?> say(String text) {
    final dit = text.trim();
    if (dit.isEmpty) return Future.value();

    return _geste(
      said: dit,
      action: (repository, studyId) =>
          repository.say(studyId: studyId, rawInput: dit),
    );
  }

  /// Le même chemin pour les trois gestes : on note ce que le pasteur a fait,
  /// on appelle, on remplace le tour vivant.
  ///
  /// L'écran ne bascule pas en chargement : ce qui est déjà lu doit rester lu
  /// pendant que le moteur travaille. Un fil qui disparaît à chaque réponse
  /// ferait perdre le fil de la conversation, au sens propre.
  Future<Failure?> _geste({
    String? said,
    required Future<Result<Study>> Function(
      StudyRepository repository,
      String studyId,
    ) action,
  }) async {
    final courant = state.value;
    if (courant == null) return null;

    final entries = [
      // Les tours passés perdent leurs gestes : le moteur a avancé.
      for (final entry in courant.entries)
        switch (entry) {
          ServedTurn(:final turn) => ServedTurn(turn, live: false),
          final ThreadEntry autre => autre,
        },
      if (said != null) SpokenByPastor(said),
    ];

    state = AsyncData(ThreadState(study: courant.study, entries: entries));

    final result = await action(ref.read(studyRepositoryProvider), studyId);

    return result.fold(
      onSuccess: (study) {
        state = AsyncData(ThreadState(
          study: study,
          entries: [
            ...entries,
            if (study.turn case final Turn turn) ServedTurn(turn, live: true),
          ],
        ));
        // Le fil d'accueil vient de vieillir : l'étage a changé.
        ref.invalidate(studyFeedProvider);
        return null;
      },
      onFailure: (failure) {
        // L'échec ne fait pas basculer l'écran : le fil reste lisible, et
        // l'appelant affiche le motif.
        return failure;
      },
    );
  }
}

final preparationThreadProvider = AsyncNotifierProvider.family<
    PreparationThread, ThreadState, String>(PreparationThread.new);
