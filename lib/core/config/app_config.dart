/// Environnement de déploiement.
enum Flavor {
  dev,
  staging,
  prod;

  static Flavor parse(String value) => switch (value.toLowerCase()) {
        'prod' || 'production' => Flavor.prod,
        'staging' || 'stg' => Flavor.staging,
        _ => Flavor.dev,
      };

  bool get isProduction => this == Flavor.prod;
}

/// Configuration résolue au démarrage, injectée par `appConfigProvider`.
///
/// Les valeurs proviennent de `--dart-define`, jamais d'un fichier commité :
/// aucun secret ne doit entrer dans le dépôt.
///
/// ```bash
/// flutter run --dart-define=FLAVOR=staging --dart-define=API_BASE_URL=https://api.staging.urim.app
/// ```
final class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.enableVerboseLogging = false,
  });

  /// Lit la configuration depuis les `--dart-define` fournis au build.
  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    final flavor = Flavor.parse(flavorName);

    return AppConfig(
      flavor: flavor,
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.dev.urim.local',
      ),
      enableVerboseLogging: !flavor.isProduction,
    );
  }

  final Flavor flavor;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Journalisation détaillée des requêtes réseau. Toujours désactivée en
  /// production : les en-têtes contiennent des jetons.
  final bool enableVerboseLogging;

  @override
  String toString() => 'AppConfig(flavor: ${flavor.name}, apiBaseUrl: $apiBaseUrl)';
}
