import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/settings_local_data_source.dart';
import 'package:urim/domain/entities/bible/bible_translation.dart';
import 'package:urim/domain/entities/settings/app_settings.dart';
import 'package:urim/presentation/settings/settings_page.dart';
import 'package:urim/presentation/settings/settings_view_model.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/theme/app_theme.dart';

import '../support/pump_app.dart';

/// Réglages : ce qui est conservé, et ce qui est montré sans être promis.
void main() {
  Future<SharedPreferences> preferencesWith([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Future<ProviderContainer> makeContainer([
    Map<String, Object> values = const {},
  ]) async {
    final preferences = await preferencesWith(values);

    return ProviderContainer.test(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
  }

  group('préférences', () {
    test('sans rien d\'enregistré, les valeurs par défaut s\'appliquent',
        () async {
      final container = await makeContainer();

      final settings = await container.read(settingsViewModelProvider.future);

      expect(settings, const AppSettings());
      expect(settings.readingTextSize, ReadingTextSize.normal);
      expect(settings.alwaysShowReference, isTrue);
      expect(settings.defaultTranslationId, BibleTranslation.louisSegond1910Id);
    });

    test('un changement est écrit dans les préférences', () async {
      final container = await makeContainer();
      await container.read(settingsViewModelProvider.future);

      final failure = await container
          .read(settingsViewModelProvider.notifier)
          .setReadingTextSize(ReadingTextSize.large);

      expect(failure, isNull);
      expect(
        container.read(settingsViewModelProvider).value?.readingTextSize,
        ReadingTextSize.large,
      );

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesSettingsDataSource.readingTextSizeKey,
        ),
        'large',
      );
    });

    test('un réglage enregistré survit au relancement', () async {
      final container = await makeContainer({
        SharedPreferencesSettingsDataSource.readingTextSizeKey: 'extraLarge',
        SharedPreferencesSettingsDataSource.alwaysShowReferenceKey: false,
      });

      final settings = await container.read(settingsViewModelProvider.future);

      expect(settings.readingTextSize, ReadingTextSize.extraLarge);
      expect(settings.alwaysShowReference, isFalse);
    });

    test('une valeur illisible retombe sur la valeur par défaut', () async {
      final container = await makeContainer({
        SharedPreferencesSettingsDataSource.readingTextSizeKey: 'gigantesque',
        SharedPreferencesSettingsDataSource.defaultTranslationKey:
            'traduction-disparue',
      });

      final settings = await container.read(settingsViewModelProvider.future);

      expect(settings.readingTextSize, ReadingTextSize.normal);
      expect(
        settings.defaultTranslationId,
        BibleTranslation.louisSegond1910Id,
        reason: 'une version retirée du catalogue ne doit pas rester en place',
      );
    });

    test('les réglages effectifs valent les valeurs par défaut avant lecture',
        () async {
      final container = await makeContainer();

      expect(container.read(effectiveSettingsProvider), const AppSettings());
    });
  });

  group('écran', () {
    Future<void> pumpSettings(
      WidgetTester tester, [
      Map<String, Object> values = const {},
    ]) async {
      final preferences = await preferencesWith(values);

      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: wrapScreen(const SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('les cinq sections de la maquette sont là', (tester) async {
      await pumpSettings(tester);

      expect(find.text('LECTURE'), findsOneWidget);
      expect(find.text('ÉCRITURE'), findsOneWidget);
      expect(find.text('HORS CONNEXION'), findsOneWidget);
      expect(find.text('RAPPELS'), findsOneWidget);
      expect(find.text('CONTENU'), findsOneWidget);
    });

    testWidgets('basculer la référence l\'enregistre', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Toujours afficher la référence'));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(
          SharedPreferencesSettingsDataSource.alwaysShowReferenceKey,
        ),
        isFalse,
      );
    });

    testWidgets('les réglages en attente sont visibles mais inactifs',
        (tester) async {
      await pumpSettings(tester);

      for (final title in const [
        'Texte biblique téléchargé',
        'Transcrire sur l\'appareil',
        'Synchroniser en Wi-Fi seulement',
        'Préparation en cours',
      ]) {
        final row = find.ancestor(
          of: find.text(title),
          matching: find.byType(Row),
        );

        final toggle = tester.widget<Switch>(
          find.descendant(of: row.first, matching: find.byType(Switch)),
        );

        expect(
          toggle.onChanged,
          isNull,
          reason: '« $title » dépend d\'une question ouverte (D13)',
        );
        expect(toggle.value, isFalse, reason: 'ne rien promettre de faux');
      }
    });

    testWidgets('l\'aperçu grandit avec le réglage', (tester) async {
      await pumpSettings(tester);

      double sampleFontSize() => tester
          .widget<Text>(
            find.text(AppTextFr().settingsReadingSample),
          )
          .style!
          .fontSize!;

      final before = sampleFontSize();

      await tester.tap(find.text('Très grand'));
      await tester.pumpAndSettle();

      expect(sampleFontSize(), greaterThan(before));
    });

    testWidgets('la version par défaut s\'affiche et annonce sa limite',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('Louis Segond 1910'), findsOneWidget);

      await tester.tap(find.text('Version par défaut'));
      await tester.pumpAndSettle();

      expect(find.text('Domaine public'), findsOneWidget);
      expect(
        find.textContaining('demandent une licence'),
        findsOneWidget,
      );
    });
  });
}
