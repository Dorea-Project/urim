import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';

/// Les préparations, de la plus récemment touchée à la plus ancienne.
final preparationListProvider = StreamProvider<List<Preparation>>((ref) {
  return ref.watch(preparationRepositoryProvider).watchPreparations().map(
        (result) => result.fold(
          onSuccess: (preparations) => preparations,
          onFailure: (failure) => throw failure,
        ),
      );
});

/// Ouverture d'une nouvelle préparation depuis le formulaire.
final class PreparationOpener extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Renvoie l'identifiant de la préparation ouverte, ou la `Failure`.
  Future<(String?, Failure?)> open({
    required String text,
    DateTime? serviceDate,
  }) async {
    state = const AsyncLoading();

    final result = await ref.read(preparationRepositoryProvider).open(
          text: text,
          serviceDate: serviceDate,
        );

    return result.fold(
      onSuccess: (preparation) {
        state = const AsyncData(null);
        return (preparation.id, null);
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
    required this.preparations,
  });

  final Recency recency;
  final List<Preparation> preparations;
}

/// Regroupe par récence de dernière activité.
///
/// Deux groupes seulement : ce qui est encore dans la semaine, et le reste.
/// Un découpage plus fin — hier, avant-hier — multiplierait les intitulés sans
/// rien apprendre à celui qui cherche son travail en cours.
List<PreparationGroup> groupByRecency(
  List<Preparation> preparations, {
  required DateTime now,
}) {
  final limit = now.subtract(const Duration(days: 7));

  final thisWeek = preparations
      .where((preparation) => preparation.updatedAt.isAfter(limit))
      .toList();
  final earlier = preparations
      .where((preparation) => !preparation.updatedAt.isAfter(limit))
      .toList();

  return [
    if (thisWeek.isNotEmpty)
      PreparationGroup(recency: Recency.thisWeek, preparations: thisWeek),
    if (earlier.isNotEmpty)
      PreparationGroup(recency: Recency.earlier, preparations: earlier),
  ];
}
