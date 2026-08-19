import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/data/repositories/local_account_erasure.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/onboarding/onboarding_view_model.dart';

/// Suppression du compte : le serveur d'abord, l'appareil ensuite.
///
/// **L'ordre est la décision.** Le serveur efface le contenu et ferme le
/// compte ; ce n'est qu'ensuite que l'appareil se vide. L'inverse laisserait,
/// si le serveur refusait, un téléphone vidé devant un compte toujours vivant
/// que plus rien ne permet d'atteindre — ni pour l'utiliser, ni pour le
/// supprimer.
///
/// Effacer les magasins ne suffit pas : sans invalidation, l'écran continuerait
/// d'afficher un compte qui n'existe plus, jusqu'au prochain lancement. Les
/// drapeaux de session sont les plus traîtres — présentation écartée,
/// application déverrouillée : ils survivent en mémoire et laisseraient entrer
/// dans une application vidée.
final class AccountErasureViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Supprime le compte, le code SMS à l'appui.
  ///
  /// Renvoie la `Failure` en cas d'échec, `null` si tout est parti.
  Future<Failure?> erase(String otp) async {
    state = const AsyncLoading();

    final server =
        await ref.read(authRepositoryProvider).confirmAccountDeletion(otp: otp);

    final refused = server.failureOrNull;
    if (refused != null) {
      // Rien n'a bougé, ni ici ni là-bas : le compte est encore là pour
      // recommencer.
      state = AsyncError(refused, StackTrace.current);
      return refused;
    }

    final local = await ref.read(accountErasureProvider).eraseEverything();

    return local.fold(
      onSuccess: (_) {
        _forget();
        return null;
      },
      onFailure: (failure) {
        // Le compte n'existe plus côté serveur : garder l'application ouverte
        // sur ses restes serait pire que de la refermer. On oublie quand même,
        // et l'écran dit ce qui n'a pas pu être effacé.
        _forget();
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }

  /// Les drapeaux d'abord : ce sont eux qui décident de l'écran.
  void _forget() {
    ref.read(authFlowViewModelProvider.notifier).closeDoor();
    ref.read(sessionUnlockedProvider.notifier).lock();
    ref.invalidate(onboardingCompletedProvider);
    ref.invalidate(authSessionProvider);
    ref.invalidate(hasSecretCodeProvider);

    state = const AsyncData(null);
  }
}

final accountErasureViewModelProvider =
    NotifierProvider<AccountErasureViewModel, AsyncValue<void>>(
  AccountErasureViewModel.new,
);
