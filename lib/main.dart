import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/app.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seul point où la configuration est lue depuis l'environnement. Partout
  // ailleurs, elle se récupère via `ref.watch(appConfigProvider)`, ce qui la
  // rend substituable dans les tests.
  final config = AppConfig.fromEnvironment();

  // Résolu une fois pour toutes avant le premier rendu : les lectures de
  // préférences deviennent ensuite synchrones partout dans l'application.
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const UrimApp(),
    ),
  );
}
