import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/cached.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';

/// Le fil : les préparations, de la plus récemment touchée à la plus ancienne.
///
/// Une lecture, pas un abonnement. Le serveur sert une liste sur demande — un
/// flux ferait croire à une fraîcheur qu'aucune des deux implémentations ne
/// tient. Ce qui change le fil l'invalide (voir [PreparationOpener]).
///
/// **Ce qu'on sait d'abord, ce que le serveur dit ensuite.** La dernière liste
/// reçue s'affiche tout de suite, marquée de son heure, et le rafraîchissement
/// la remplace quand il arrive. Sans réseau, l'accueil montre le travail en
/// cours au lieu d'un écran vide.
final studyFeedProvider =
    AsyncNotifierProvider<StudyFeed, Cached<List<StudySummary>>>(
  StudyFeed.new,
);

final class StudyFeed extends AsyncNotifier<Cached<List<StudySummary>>> {
  @override
  Future<Cached<List<StudySummary>>> build() async {
    final repository = ref.watch(studyRepositoryProvider);

    if (await repository.cachedFeed() case final Cached<List<StudySummary>> g) {
      Future.microtask(_rafraichir);
      return g;
    }

    final result = await repository.listMine();

    return result.fold(
      onSuccess: Cached.fresh,
      onFailure: (failure) => throw failure,
    );
  }

  /// Un échec laisse la liste gardée en place : l'accueil reste utilisable.
  Future<void> _rafraichir() async {
    final result = await ref.read(studyRepositoryProvider).listMine();

    result.fold(
      onSuccess: (summaries) => state = AsyncData(Cached.fresh(summaries)),
      onFailure: (_) {},
    );
  }
}

/// Ouverture d'une nouvelle préparation depuis le formulaire.
final class PreparationOpener extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Renvoie l'identifiant de la préparation ouverte, ou la `Failure`.
  ///
  /// ⚠️ **Passe par le dépôt du moteur, et c'était un défaut de ne pas le
  /// faire.** Ce formulaire créait une préparation dans le magasin en mémoire :
  /// l'ouverture n'atteignait donc jamais le serveur, même avec un build qui le
  /// vise. Le fil d'accueil, lui, lisait le serveur — les deux se
  /// contredisaient sans que rien n'échoue.
  ///
  /// C'est aussi le seul geste qui ne peut pas attendre le réseau : lire une
  /// phrase demande le corpus, et il n'est pas sur l'appareil (Q4, étape 5).
  Future<(String?, Failure?)> open({
    required String text,
    DateTime? serviceDate,
  }) async {
    state = const AsyncLoading();

    final result = await ref.read(studyRepositoryProvider).open(
          rawInput: text,
          serviceDate: serviceDate,
        );

    return result.fold(
      onSuccess: (study) {
        state = const AsyncData(null);
        // Le fil est une lecture, pas un abonnement : c'est ici qu'on lui dit
        // qu'il a vieilli.
        ref.invalidate(studyFeedProvider);
        return (study.id, null);
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return (null, failure);
      },
    );
  }
}

final preparationOpenerProvider =
    NotifierProvider<PreparationOpener, AsyncValue<void>>(
  PreparationOpener.new,
);

/// Depuis quand un travail n'a pas bougé.
///
/// Une nature, pas un libellé : c'est l'écran qui nomme « CETTE SEMAINE ».
enum Recency { thisWeek, earlier }

/// Un groupe de l'accueil.
final class PreparationGroup {
  const PreparationGroup({
    required this.recency,
    required this.summaries,
  });

  final Recency recency;
  final List<StudySummary> summaries;
}

/// Regroupe par récence de dernière activité.
///
/// Deux groupes seulement : ce qui est encore dans la semaine, et le reste.
/// Un découpage plus fin — hier, avant-hier — multiplierait les intitulés sans
/// rien apprendre à celui qui cherche son travail en cours.
List<PreparationGroup> groupByRecency(
  List<StudySummary> summaries, {
  required DateTime now,
}) {
  final limit = now.subtract(const Duration(days: 7));

  final thisWeek =
      summaries.where((s) => s.lastActivity.isAfter(limit)).toList();
  final earlier =
      summaries.where((s) => !s.lastActivity.isAfter(limit)).toList();

  return [
    if (thisWeek.isNotEmpty)
      PreparationGroup(recency: Recency.thisWeek, summaries: thisWeek),
    if (earlier.isNotEmpty)
      PreparationGroup(recency: Recency.earlier, summaries: earlier),
  ];
}
