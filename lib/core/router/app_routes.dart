/// Chemins et noms de routes, centralisés.
///
/// Naviguer par **nom** (`context.goNamed(AppRoutes.homeName)`) plutôt que par
/// chemin littéral : le nom survit à un changement d'URL.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String homePath = '/';
  static const String homeName = 'home';
}
