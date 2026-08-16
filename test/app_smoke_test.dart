import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/app.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/onboarding_local_data_source.dart';
import 'package:urim/presentation/auth/phone_page.dart';
import 'package:urim/presentation/home/home_page.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/onboarding/onboarding_page.dart';
import 'package:urim/presentation/splash/splash_page.dart';

/// Parcours de démarrage : lancement, présentation, accès à l'application.
/// Les libelles viennent des memes fichiers que l'ecran : le test verifie le
/// sens, jamais une chaine recopiee.
final texte = AppTextFr();

void main() {
  const testConfig = AppConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'https://api.test.local',
  );

  Future<Widget> buildApp({required bool onboardingSeen}) async {
    SharedPreferences.setMockInitialValues(
      onboardingSeen
          ? {SharedPreferencesOnboardingDataSource.storageKey: true}
          : <String, Object>{},
    );
    final preferences = await SharedPreferences.getInstance();

    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const UrimApp(),
    );
  }

  testWidgets('au premier lancement, la présentation s\'affiche',
      (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: false));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('l\'écran de lancement précède la redirection', (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: false));
    // Une seule frame : la lecture des préférences n'a pas encore abouti.
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('présentation déjà vue : on arrive sur la connexion',
      (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: true));
    await tester.pumpAndSettle();

    // L'accueil n'est plus atteignable sans session : la porte d'entrée
    // renvoie sur le numéro de téléphone.
    expect(find.byType(PhonePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('« Passer » clôt la présentation et la retient', (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text(texte.onboardingSkip));
    await tester.pumpAndSettle();

    expect(find.byType(PhonePage), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(SharedPreferencesOnboardingDataSource.storageKey),
      isTrue,
      reason: 'passer vaut avoir vu : la présentation ne doit pas revenir',
    );
  });

  testWidgets('le parcours complet mène à la connexion', (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text(texte.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texte.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texte.onboardingCreateAccount));
    await tester.pumpAndSettle();

    expect(find.byType(PhonePage), findsOneWidget);
  });

  testWidgets('le bouton reste inactif tant que la politique n\'est pas '
      'acceptée', (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: true));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).last,
      '0747769069',
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      button.onPressed,
      isNull,
      reason: 'le consentement conditionne l\'envoi du SMS',
    );
  });
}
