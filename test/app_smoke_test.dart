import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/app.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/onboarding_local_data_source.dart';
import 'package:urim/presentation/home/home_page.dart';
import 'package:urim/presentation/onboarding/onboarding_content.dart';
import 'package:urim/presentation/onboarding/onboarding_page.dart';
import 'package:urim/presentation/splash/splash_page.dart';

/// Parcours de démarrage : lancement, présentation, accès à l'application.
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

  testWidgets('présentation déjà vue : on arrive directement sur l\'accueil',
      (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: true));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  testWidgets('« Passer » clôt la présentation et la retient', (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text(OnboardingContent.skip));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(SharedPreferencesOnboardingDataSource.storageKey),
      isTrue,
      reason: 'passer vaut avoir vu : la présentation ne doit pas revenir',
    );
  });

  testWidgets('le parcours complet mène à l\'accueil', (tester) async {
    await tester.pumpWidget(await buildApp(onboardingSeen: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text(OnboardingContent.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingContent.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingContent.enter));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
