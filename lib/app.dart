import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/router/app_router.dart';
import 'package:urim/presentation/theme/app_theme.dart';

/// Racine de l'application.
///
/// Le thème vient entièrement de `presentation/theme/`. Aucune couleur, aucune
/// taille et aucun espacement ne se décide ici.
class UrimApp extends ConsumerWidget {
  const UrimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Urim',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Suit le réglage du système tant qu'un choix explicite n'est pas
      // proposé dans l'application.
      themeMode: ThemeMode.system,
    );
  }
}
