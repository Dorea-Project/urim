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

  static const String homePath = '/';
  static const String homeName = 'home';
}
