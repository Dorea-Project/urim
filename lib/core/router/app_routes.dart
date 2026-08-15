/// Chemins et noms de routes, centralisés.
///
/// Naviguer par **nom** (`context.goNamed(AppRoutes.homeName)`) plutôt que par
/// chemin littéral : le nom survit à un changement d'URL.
abstract final class AppRoutes {
  const AppRoutes._();

  /// Écran de lancement. Point d'entrée : tant que l'on ignore si la
  /// présentation a déjà été vue, on ne sait pas où aller.
  static const String splashPath = '/lancement';
  static const String splashName = 'splash';

  static const String onboardingPath = '/presentation';
  static const String onboardingName = 'onboarding';

  static const String signInPath = '/connexion';
  static const String signInName = 'signIn';

  static const String otpPath = '/connexion/code';
  static const String otpName = 'otp';

  static const String secretCodeSetupPath = '/code-secret/creation';
  static const String secretCodeSetupName = 'secretCodeSetup';

  static const String secretCodePath = '/code-secret';
  static const String secretCodeName = 'secretCode';

  static const String homePath = '/';
  static const String homeName = 'home';

  /// Routes du parcours d'entrée : inaccessibles une fois l'accès ouvert.
  static const Set<String> entryPaths = {
    splashPath,
    onboardingPath,
    signInPath,
    otpPath,
    secretCodeSetupPath,
    secretCodePath,
  };
}
