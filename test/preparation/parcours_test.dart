import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/presentation/home/home_page.dart';
import 'package:urim/presentation/preparation/new_preparation_page.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import 'package:urim/presentation/theme/app_theme.dart';

/// Le parcours des maquettes, d'un bout à l'autre : l'accueil, la feuille des
/// tâches, le formulaire, puis le fil.
final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

final class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

void main() {
  final fixedNow = DateTime(2026, 8, 15, 10);

  Future<void> pumpParcours(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Un routeur réduit aux écrans du parcours : la redirection d'accès
    // demanderait une session, et ce n'est pas ce qui est vérifié ici.
    final router = GoRouter(
      initialLocation: AppRoutes.homePath,
      routes: [
        GoRoute(
          path: AppRoutes.homePath,
          name: AppRoutes.homeName,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.newPreparationPath,
          name: AppRoutes.newPreparationName,
          builder: (context, state) => const NewPreparationPage(),
        ),
        GoRoute(
          path: AppRoutes.preparationPath,
          name: AppRoutes.preparationName,
          builder: (context, state) =>
              PreparationPage(preparationId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(_FixedClock(fixedNow)),
          idGeneratorProvider.overrideWithValue(_SequentialIds()),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('accueil', () {
    testWidgets('les travaux sont groupés par récence', (tester) async {
      await pumpParcours(tester);

      expect(find.text('CETTE SEMAINE'), findsOneWidget);
      expect(find.text('PLUS TÔT'), findsOneWidget);
      expect(find.text('Amour fraternel'), findsOneWidget);
      expect(find.text('Actes 2:42-47'), findsOneWidget);
    });

    testWidgets('chaque carte dit à qui est la main', (tester) async {
      await pumpParcours(tester);

      for (final state in PreparationState.values) {
        expect(
          find.text(state.label),
          findsOneWidget,
          reason: 'l\'état « ${state.label} » doit se lire sur la liste',
        );
      }
    });

    testWidgets('ouvrir une carte mène à son fil', (tester) async {
      await pumpParcours(tester);

      await tester.tap(find.text('Amour fraternel'));
      await tester.pumpAndSettle();

      expect(find.byType(PreparationPage), findsOneWidget);
      expect(find.text('Sur quel axe veux-tu prêcher ?'), findsOneWidget);
    });
  });

  group('feuille des tâches', () {
    testWidgets('deux travaux, dont un encore fermé', (tester) async {
      await pumpParcours(tester);

      await tester.tap(find.text('Ouvrir une tâche'));
      await tester.pumpAndSettle();

      expect(find.text('Quelle tâche ?'), findsOneWidget);
      expect(find.text('Préparer un message'), findsOneWidget);
      expect(find.text('Transcrire une prédication'), findsOneWidget);
      expect(
        find.textContaining('moteur de transcription n\'est pas encore'),
        findsOneWidget,
      );
    });

    testWidgets('« Préparer un message » ouvre le formulaire', (tester) async {
      await pumpParcours(tester);

      await tester.tap(find.text('Ouvrir une tâche'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Préparer un message'));
      await tester.pumpAndSettle();

      expect(find.byType(NewPreparationPage), findsOneWidget);
      expect(find.text('Pour quel dimanche'.toUpperCase()), findsOneWidget);
    });
  });

  group('formulaire', () {
    Future<void> openForm(WidgetTester tester) async {
      await pumpParcours(tester);
      await tester.tap(find.text('Ouvrir une tâche'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Préparer un message'));
      await tester.pumpAndSettle();
    }

    testWidgets('le bouton attend une phrase', (tester) async {
      await openForm(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ouvrir la préparation'),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('écrire puis ouvrir mène au fil, avec la phrase dedans',
        (tester) async {
      await openForm(tester);

      await tester.enterText(
        find.byType(TextField),
        'Que l\'amour fraternel continue.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ouvrir la préparation'));
      await tester.pumpAndSettle();

      expect(find.byType(PreparationPage), findsOneWidget);
      expect(find.text('Que l\'amour fraternel continue.'), findsOneWidget);
      expect(
        find.text('Que l\'amour fraternel continue'),
        findsOneWidget,
        reason: 'le titre reprend les premiers mots, sans le point final',
      );
    });

    testWidgets('la préparation ouverte rejoint l\'accueil', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextField), 'Romains 8:15');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvrir la préparation'));
      await tester.pumpAndSettle();

      // Retour à l'accueil : le formulaire a été remplacé, donc un seul retour.
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Romains 8:15'), findsOneWidget);
    });
  });
}
