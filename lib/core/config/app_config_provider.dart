import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config.dart';

/// Configuration de l'application.
///
/// Volontairement sans valeur par défaut : `main()` doit la surcharger, et
/// les tests fournissent la leur. Une erreur ici est une erreur de câblage,
/// pas un cas à traiter à l'exécution.
///
/// ```dart
/// ProviderScope(
///   overrides: [appConfigProvider.overrideWithValue(AppConfig.fromEnvironment())],
///   child: const UrimApp(),
/// )
/// ```
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider doit être surchargé au démarrage (voir main.dart).',
  ),
);
