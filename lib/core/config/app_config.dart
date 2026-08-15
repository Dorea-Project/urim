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
    this.apiPrefix = defaultApiPrefix,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.enableVerboseLogging = false,
    this.useMockAuth = false,
  });

  /// Préfixe du canal mobile côté serveur (`API_PREFIX` du backend).
  static const String defaultApiPrefix = '/api/mobile';

  /// Adresse par défaut en développement.
  ///
  /// `10.0.2.2` est la machine hôte vue depuis l'émulateur Android. Sur un
  /// téléphone réel, il faut passer l'adresse du poste sur le réseau local :
  ///
  /// ```bash
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000 \
  ///             --dart-define=USE_MOCK_AUTH=false
  /// ```
  static const String defaultDevBaseUrl = 'http://10.0.2.2:8000';

  /// Lit la configuration depuis les `--dart-define` fournis au build.
  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    final flavor = Flavor.parse(flavorName);

    const baseUrl = String.fromEnvironment('API_BASE_URL');
    const mock = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);

    return AppConfig(
      flavor: flavor,
      apiBaseUrl: baseUrl.isNotEmpty ? baseUrl : defaultDevBaseUrl,
      apiPrefix: const String.fromEnvironment(
        'API_PREFIX',
        defaultValue: defaultApiPrefix,
      ),
      enableVerboseLogging: !flavor.isProduction,
      // La production ne connaît pas de serveur simulé, quelle que soit la
      // valeur passée au build : une erreur de ligne de commande ne doit pas
      // pouvoir livrer une application qui accepte n'importe quel code.
      useMockAuth: !flavor.isProduction && mock,
    );
  }

  final Flavor flavor;

  /// Racine du serveur, sans préfixe : `https://api.dorea.church`.
  final String apiBaseUrl;

  final String apiPrefix;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Le parcours d'entrée est-il joué contre la source simulée, sans serveur ?
  ///
  /// Distinct de [usesMockCredentials] : celui-ci décide **qui répond**, celui-là
  /// décide **ce qui est affiché**. Un build peut viser le vrai serveur tout en
  /// restant hors production.
  final bool useMockAuth;

  /// Racine des appels : `https://api.dorea.church/api/mobile`.
  String get apiRoot => '$apiBaseUrl$apiPrefix';

  /// Journalisation détaillée des requêtes réseau. Toujours désactivée en
  /// production : les en-têtes contiennent des jetons.
  final bool enableVerboseLogging;

  /// Faut-il afficher les identifiants de démonstration ?
  ///
  /// Seulement quand personne ne répond vraiment : dès que le build vise le
  /// serveur, un code affiché à l'écran serait un mensonge — c'est le SMS qui
  /// fait foi.
  bool get usesMockCredentials => useMockAuth;

  @override
  String toString() => 'AppConfig(flavor: ${flavor.name}, '
      'apiRoot: $apiRoot, mockAuth: $useMockAuth)';
}
