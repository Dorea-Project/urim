import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/preached.dart';

/// L'archive du prédicateur, et son parcours dans l'Écriture.
///
/// Deux lectures séparées parce que le serveur les sert séparément, et parce
/// qu'elles ne vieillissent pas ensemble : consigner une prédication change les
/// deux, mais l'écran peut afficher l'une pendant que l'autre arrive.

final archiveProvider = FutureProvider<List<PreachedSermon>>((ref) async {
  final result = await ref.watch(studyRepositoryProvider).listPreached();

  return result.fold(
    onSuccess: (archive) => archive,
    onFailure: (failure) => throw failure,
  );
});

/// ⚠️ **Des faits, aucune consigne.** Le serveur le pose dans son contrat, et
/// ça vaut pour l'écran qui lit ceci : *un rayon vide se montre, il ne se
/// comble pas*. Aucun score, aucune série, aucun pourcentage de complétude —
/// ce serait mesurer la fidélité d'un pasteur, et transformer une aide en
/// performance à tenir.
final coverageProvider = FutureProvider<PreachingCoverage>((ref) async {
  final result = await ref.watch(studyRepositoryProvider).preachingCoverage();

  return result.fold(
    onSuccess: (couverture) => couverture,
    onFailure: (failure) => throw failure,
  );
});

/// Marquer une préparation comme prêchée.
///
/// 🔴 **Rien ne s'archive parce qu'une date est passée.** C'est un geste, jamais
/// une déduction du calendrier : une préparation datée du dimanche prochain n'a
/// pas été prêchée pour autant. Le jour par défaut est **aujourd'hui**.
final class PreachedMarker extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Rend la prédication consignée, ou la panne.
  Future<(PreachedSermon?, Object?)> mark(String studyId) async {
    state = const AsyncLoading();

    final result =
        await ref.read(studyRepositoryProvider).markPreached(studyId: studyId);

    return result.fold(
      onSuccess: (sermon) {
        state = const AsyncData(null);

        // L'archive a vieilli, et le fil aussi : côté serveur, archiver ferme
        // la préparation quand c'est son auteur qui archive (D57).
        ref.invalidate(archiveProvider);
        ref.invalidate(coverageProvider);

        return (sermon, null);
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return (null, failure);
      },
    );
  }
}

final preachedMarkerProvider =
    NotifierProvider<PreachedMarker, AsyncValue<void>>(PreachedMarker.new);
