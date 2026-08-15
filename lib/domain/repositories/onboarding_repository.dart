import 'package:urim/core/result/result.dart';

/// Mémoire du premier lancement.
///
/// Muet sur le support : préférences système, fichier ou base locale. Seul le
/// fait est métier — l'utilisateur a-t-il déjà vu la présentation.
abstract interface class OnboardingRepository {
  /// Faux au tout premier lancement.
  Future<Result<bool>> hasCompletedOnboarding();

  /// Marque la présentation comme vue. Idempotent.
  Future<Result<void>> markOnboardingCompleted();
}
