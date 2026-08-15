import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/in_memory_transcription_repository.dart';
import 'package:urim/domain/entities/transcription/synthesis_draft.dart';
import 'package:urim/domain/entities/transcription/transcription_review.dart';

/// Relecture d'une prédication transcrite.
final transcriptionReviewProvider =
    FutureProvider.family<TranscriptionReview, String>(
  (ref, preparationId) async {
    final result = await ref
        .watch(transcriptionRepositoryProvider(preparationId))
        .review();

    return result.fold(
      onSuccess: (review) => review,
      onFailure: (failure) => throw failure,
    );
  },
);

/// Synthèse d'une prédication.
final synthesisProvider = FutureProvider.family<SynthesisDraft, String>(
  (ref, preparationId) async {
    final result = await ref
        .watch(transcriptionRepositoryProvider(preparationId))
        .synthesis();

    return result.fold(
      onSuccess: (synthesis) => synthesis,
      onFailure: (failure) => throw failure,
    );
  },
);

/// Validation de la synthèse.
///
/// Séparée de la lecture, et sans optimisme : tant que l'écriture n'a pas
/// abouti, l'écran continue d'annoncer que rien n'est parti. C'est une
/// promesse faite à l'utilisateur, pas un état d'interface.
final class SynthesisValidator extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Renvoie la `Failure` en cas de refus, `null` sinon.
  Future<Failure?> validate(String preparationId) async {
    state = const AsyncLoading();

    final result = await ref
        .read(transcriptionRepositoryProvider(preparationId))
        .validate();

    return result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        ref.invalidate(synthesisProvider(preparationId));
        return null;
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }
}

final synthesisValidatorProvider =
    NotifierProvider<SynthesisValidator, AsyncValue<void>>(
  SynthesisValidator.new,
);
