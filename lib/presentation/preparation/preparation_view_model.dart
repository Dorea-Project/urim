import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';

/// Une préparation et son fil.
final preparationProvider =
    FutureProvider.family<Preparation, String>((ref, preparationId) async {
  final result =
      await ref.watch(preparationRepositoryProvider).getById(preparationId);

  return result.fold(
    onSuccess: (preparation) => preparation,
    onFailure: (failure) => throw failure,
  );
});

/// Ajout au fil depuis la barre de saisie.
///
/// Séparé de la lecture : écrire est une action ponctuelle qui peut échouer
/// seule, sans faire basculer tout l'écran en erreur.
final class PreparationComposer extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Ajoute ce que l'utilisateur vient d'écrire. Renvoie la `Failure` en cas
  /// d'échec, `null` sinon.
  Future<Failure?> append({
    required String preparationId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    state = const AsyncLoading();

    final result = await ref.read(preparationRepositoryProvider).appendBlock(
          preparationId: preparationId,
          block: UserBlock(
            id: ref.read(idGeneratorProvider).newId(),
            anchor: ClockAnchor(ref.read(clockProvider).now()),
            text: trimmed,
          ),
        );

    return result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        ref.invalidate(preparationProvider(preparationId));
        return null;
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }
}

final preparationComposerProvider =
    NotifierProvider<PreparationComposer, AsyncValue<void>>(
  PreparationComposer.new,
);
