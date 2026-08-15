import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/secret_code_repository_impl.dart';
import 'package:urim/domain/usecases/auth/define_secret_code.dart';
import 'package:urim/domain/usecases/auth/verify_secret_code.dart';
import 'package:urim/presentation/auth/auth_gate.dart';

final defineSecretCodeProvider = Provider(
  (ref) => DefineSecretCode(ref.watch(secretCodeRepositoryProvider)),
);

final verifySecretCodeProvider = Provider(
  (ref) => VerifySecretCode(ref.watch(secretCodeRepositoryProvider)),
);

/// Étape de la création du code.
enum SecretCodeStage { choose, confirm }

final class SecretCodeState extends Equatable {
  const SecretCodeState({
    this.stage = SecretCodeStage.choose,
    this.firstEntry = '',
    this.isSubmitting = false,
    this.failure,
  });

  final SecretCodeStage stage;
  final String firstEntry;
  final bool isSubmitting;
  final Failure? failure;

  @override
  List<Object?> get props => [stage, firstEntry, isSubmitting, failure];
}

/// Création du code secret, en deux saisies.
final class SecretCodeViewModel extends Notifier<SecretCodeState> {
  @override
  SecretCodeState build() => const SecretCodeState();

  /// Première saisie : mémorisée, sans rien écrire encore.
  void submitFirstEntry(String code) => state = SecretCodeState(
        stage: SecretCodeStage.confirm,
        firstEntry: code,
      );

  /// Retour à la première saisie, après une confirmation divergente.
  void restart() => state = const SecretCodeState();

  /// Seconde saisie : c'est ici que le cas d'usage tranche.
  Future<bool> confirm(String confirmation) async {
    state = SecretCodeState(
      stage: state.stage,
      firstEntry: state.firstEntry,
      isSubmitting: true,
    );

    final result = await ref.read(defineSecretCodeProvider)(
      DefineSecretCodeParams(
        code: state.firstEntry,
        confirmation: confirmation,
      ),
    );

    return result.fold(
      onSuccess: (_) {
        // Définir son code vaut déverrouillage : on ne le redemande pas dans
        // la foulée.
        ref.read(sessionUnlockedProvider.notifier).unlock();
        ref.invalidate(hasSecretCodeProvider);
        state = const SecretCodeState();
        return true;
      },
      onFailure: (failure) {
        // Codes trop simples ou saisies divergentes : on repart de la
        // première saisie, garder la précédente n'aurait pas de sens.
        state = SecretCodeState(failure: failure);
        return false;
      },
    );
  }
}

final secretCodeViewModelProvider =
    NotifierProvider<SecretCodeViewModel, SecretCodeState>(
  SecretCodeViewModel.new,
);

/// Déverrouillage à l'ouverture.
final class SecretCodeUnlockViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Vrai si le code est le bon.
  Future<bool> unlock(String code) async {
    state = const AsyncLoading();

    final result = await ref.read(verifySecretCodeProvider)(code);

    return result.fold(
      onSuccess: (matches) {
        state = const AsyncData(null);
        if (matches) ref.read(sessionUnlockedProvider.notifier).unlock();
        return matches;
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}

final secretCodeUnlockViewModelProvider =
    NotifierProvider<SecretCodeUnlockViewModel, AsyncValue<void>>(
  SecretCodeUnlockViewModel.new,
);
