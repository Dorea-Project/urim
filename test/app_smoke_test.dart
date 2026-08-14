import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/app.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/presentation/home/home_page.dart';

/// Vérifie que le câblage tient : ProviderScope, routeur et écran initial.
/// PISTE 3 : point de départ de la suite de tests.
void main() {
  const testConfig = AppConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'https://api.test.local',
  );

  testWidgets('l\'application démarre sur l\'écran d\'accueil', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(testConfig)],
        child: const UrimApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
