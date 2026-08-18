import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/local_account_erasure.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/onboarding/onboarding_view_model.dart';

/// Suppression du compte, et remise à zéro de ce que l'application garde en
/// mémoire.
///
/// Effacer les magasins ne suffit pas : sans invalidation, l'écran continuerait
/// d'afficher un compte qui n'existe plus, jusqu'au prochain lancement. Les
/// drapeaux de session sont les plus traîtres — présentation écartée,
/// application déverrouillée : ils survivent en mémoire et laisseraient entrer
/// dans une application vidée.
final class AccountErasureViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Renvoie la `Failure` en cas d'échec, `null` si tout est parti.
  Future<Failure?> erase() async {
    state = const AsyncLoading();

    final result = await ref.read(accountErasureProvider).eraseEverything();

    return result.fold(
      onSuccess: (_) {
        // Les drapeaux d'abord : ce sont eux qui décident de l'écran.
        ref.read(sessionUnlockedProvider.notifier).lock();
        ref.invalidate(onboardingCompletedProvider);
        ref.invalidate(authSessionProvider);
        ref.invalidate(hasSecretCodeProvider);

        state = const AsyncData(null);
        return null;
      },
      onFailure: (failure) {
        // L'échec laisse l'application en l'état. Mieux vaut un compte encore
        // là qu'une application vidée à moitié, où plus personne ne sait ce
        // qui reste.
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }
}

final accountErasureViewModelProvider =
    NotifierProvider<AccountErasureViewModel, AsyncValue<void>>(
  AccountErasureViewModel.new,
);
