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
class UrimApp extends ConsumerStatefulWidget {
  const UrimApp({super.key});

  @override
  ConsumerState<UrimApp> createState() => _UrimAppState();
}

class _UrimAppState extends ConsumerState<UrimApp> {
  // ⛔ **La file ne se vide plus toute seule** (D71, 06/09). Deux déclencheurs
  // vivaient ici : le lancement de l'application et son retour au premier plan.
  // Ils faisaient partir cent quatre-vingts fragments — 173 Mo d'une salle
  // d'église, voix comprises — vers un serveur qui ne les lit jamais : le port
  // `FragmentStore` n'a que `put` et `purge`, aucune lecture nulle part.
  //
  // 🔴 **D71 a retiré la dernière raison de les envoyer** : on ne transcrit
  // jamais la matière brute, seule une pièce se transcrit. Le transport
  // reviendra pour la pièce — un objet que le pasteur a écouté et décidé de
  // garder — pas pour ce que le micro a pris sans intention.
  //
  // `FragmentOutbox` reste entière : sa file, son rejeu et sa marque haute
  // serviront ce transport-là.

  @override
  Widget build(BuildContext context) {
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
