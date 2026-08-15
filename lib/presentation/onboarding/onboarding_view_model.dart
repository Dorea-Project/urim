import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/data/repositories/onboarding_repository_impl.dart';
import 'package:urim/domain/usecases/onboarding/complete_onboarding.dart';
import 'package:urim/domain/usecases/onboarding/has_completed_onboarding.dart';

final hasCompletedOnboardingProvider = Provider(
  (ref) => HasCompletedOnboarding(ref.watch(onboardingRepositoryProvider)),
);

final completeOnboardingProvider = Provider(
  (ref) => CompleteOnboarding(ref.watch(onboardingRepositoryProvider)),
);

/// Présentation écartée pour la session en cours.
///
/// Doublure volontaire de la valeur persistée : si l'écriture en préférences
/// échoue, l'utilisateur passe quand même — il reverra la présentation au
/// prochain lancement, ce qui est un désagrément, alors que le bloquer sur un
/// écran de bienvenue serait une impasse.
final class SessionOnboardingFlag extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

final sessionOnboardingFlagProvider =
    NotifierProvider<SessionOnboardingFlag, bool>(SessionOnboardingFlag.new);

/// Faut-il montrer la présentation ? Consulté par la redirection du routeur.
///
/// Un échec de lecture est traité comme « jamais vue » : mieux vaut une
/// présentation en trop qu'un démarrage bloqué.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(sessionOnboardingFlagProvider)) return true;

  final result = await ref.watch(hasCompletedOnboardingProvider)(
    const NoParams(),
  );

  return result.fold(onSuccess: (seen) => seen, onFailure: (_) => false);
});

/// Clôture de la présentation.
final class OnboardingViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Marque la présentation comme vue et laisse la redirection faire le reste.
  ///
  /// Renvoie la `Failure` d'écriture le cas échéant — l'écran s'en sert pour
  /// prévenir, sans retenir l'utilisateur.
  Future<Failure?> complete() async {
    state = const AsyncLoading();

    final result = await ref.read(completeOnboardingProvider)(const NoParams());

    // Dans les deux cas la session est marquée : la redirection peut opérer.
    ref.read(sessionOnboardingFlagProvider.notifier).dismiss();

    return result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        return null;
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, AsyncValue<void>>(
  OnboardingViewModel.new,
);
