import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/router/app_router.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_theme.dart';

/// Racine de l'application.
///
/// Le thème vient entièrement de `presentation/theme/`. Aucune couleur, aucune
/// taille et aucun espacement ne se décide ici.
///
/// Les textes viennent de `lib/l10n/*.arb`. Une seule langue aujourd'hui : la
/// liste des langues acceptées suffit à en accueillir une seconde sans qu'aucun
/// écran ne bouge.
class UrimApp extends ConsumerWidget {
  const UrimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppText.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Suit le réglage du système tant qu'un choix explicite n'est pas
      // proposé dans l'application.
      themeMode: ThemeMode.system,
      localizationsDelegates: AppText.localizationsDelegates,
      supportedLocales: AppText.supportedLocales,
      // Un téléphone réglé en anglais parle français plutôt que de tomber sur
      // des clés vides : tant qu'une seule langue existe, elle sert à tout le
      // monde.
      localeResolutionCallback: (locale, supported) => supported.first,
    );
  }
}
