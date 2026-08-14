import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/router/app_router.dart';

/// Racine de l'application.
///
/// PISTE 1 : le thème ci-dessous est un minimum viable. Le design system
/// (couleurs, typographie, composants) vous appartient — remplacez `theme` et
/// `darkTheme` par ce que vous exposerez depuis `presentation/theme/`.
class UrimApp extends ConsumerWidget {
  const UrimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Urim',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3A5A98),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF3A5A98),
        brightness: Brightness.dark,
      ),
    );
  }
}
