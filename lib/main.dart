import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/app.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Seul point où la configuration est lue depuis l'environnement. Partout
  // ailleurs, elle se récupère via `ref.watch(appConfigProvider)`, ce qui la
  // rend substituable dans les tests.
  final config = AppConfig.fromEnvironment();

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const UrimApp(),
    ),
  );
}
