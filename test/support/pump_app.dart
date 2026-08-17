import 'package:flutter/material.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_theme.dart';

/// La configuration d'un build de démonstration : **personne ne répond**.
///
/// `appConfigProvider` n'a volontairement pas de valeur par défaut — un
/// câblage oublié doit échouer, pas se rabattre sur une adresse au hasard. Les
/// écrans qui lisent un fil ont donc besoin de celle-ci : elle branche le
/// magasin de démonstration, et aucun test d'interface ne touche le réseau.
const demoConfig = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'http://serveur.test',
  useMockAuth: true,
);

final demoConfigOverride = appConfigProvider.overrideWithValue(demoConfig);

/// Enveloppe d'écran pour les tests : le thème **et** les textes.
///
/// Sans les délégués de localisation, `AppText.of(context)` ne trouve rien et
/// l'écran échoue au montage — avec un message qui ne dit pas pourquoi. Chaque
/// écran migré doit donc être pompé à travers cette enveloppe, et c'est plus
/// sûr de l'avoir en un seul endroit que de s'en souvenir dans quarante tests.
Widget wrapScreen(Widget child) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppText.localizationsDelegates,
      supportedLocales: AppText.supportedLocales,
      home: child,
    );

/// Même chose pour un écran atteint par une route.
Widget wrapRouter(RouterConfig<Object> router) => MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: AppText.localizationsDelegates,
      supportedLocales: AppText.supportedLocales,
      routerConfig: router,
    );
