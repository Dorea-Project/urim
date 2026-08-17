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
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/home/home_page.dart';
import 'package:urim/presentation/preparation/new_preparation_page.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';

import '../support/pump_app.dart';

/// Les libelles viennent de la meme source que l'ecran.
final texte = AppTextFr();

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
          demoConfigOverride,
        ],
        child: wrapRouter(router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('accueil', () {
    testWidgets('les travaux sont groupés par récence', (tester) async {
      await pumpParcours(tester);

      expect(find.text(texte.homeGroupThisWeek), findsOneWidget);
      expect(find.text(texte.homeGroupEarlier), findsOneWidget);
      expect(find.text('Amour fraternel'), findsOneWidget);
      expect(find.text('Actes 2:42-47'), findsOneWidget);
    });

    testWidgets('la carte dit où le moteur s\'est arrêté', (tester) async {
      await pumpParcours(tester);

      // Le vocabulaire affiché est celui du moteur, traduit une seule fois :
      // « rend la main » **est** `await_decision`. Les états inventés côté
      // application ont disparu du fil, et ce test empêche leur retour.
      for (final outcome in [
        TurnOutcome.handsBack,
        TurnOutcome.kept,
        TurnOutcome.refused,
      ]) {
        final libelle = turnOutcomeLabel(texte, outcome);

        expect(
          find.text(libelle),
          findsWidgets,
          reason: 'l\'issue « $libelle » doit se lire sur la liste',
        );
      }
    });

    testWidgets('une prédication déjà prêchée ne porte pas de pastille',
        (tester) async {
      await pumpParcours(tester);

      // « Retour disponible » ne vient pas du moteur de préparation mais de la
      // branche transcription, qui reste une maquette. Tant qu'aucune issue ne
      // le porte côté serveur, la carte se tait plutôt que d'inventer.
      expect(find.text(texte.stateFeedbackReady), findsNothing);
    });

    testWidgets('ouvrir une carte mène à son fil', (tester) async {
      await pumpParcours(tester);

      await tester.tap(find.text('Amour fraternel'));
      await tester.pumpAndSettle();

      expect(find.byType(PreparationPage), findsOneWidget);
      // Ce que la carte annonçait — « Rend la main » — se retrouve derrière
      // elle : le moteur s'est arrêté sur une question.
      expect(find.text('Lequel retenez-vous ?'), findsOneWidget);
    });
  });

  group('feuille des tâches', () {
    testWidgets('deux travaux, dont un encore fermé', (tester) async {
      await pumpParcours(tester);

      await tester.tap(find.text(texte.homeOpenTask));
      await tester.pumpAndSettle();

      expect(find.text(texte.taskSheetTitle), findsOneWidget);
      expect(find.text(texte.taskWriteTitle), findsOneWidget);
      expect(find.text(texte.taskTranscribeTitle), findsOneWidget);
      expect(
        find.textContaining('moteur de transcription n\'est pas encore'),
        findsOneWidget,
      );
    });

    testWidgets('« Préparer un message » ouvre le formulaire', (tester) async {
      await pumpParcours(tester);

      await tester.tap(find.text(texte.homeOpenTask));
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.taskWriteTitle));
      await tester.pumpAndSettle();

      expect(find.byType(NewPreparationPage), findsOneWidget);
      expect(find.text(texte.newPreparationServiceSection.toUpperCase()), findsOneWidget);
    });
  });

  group('formulaire', () {
    Future<void> openForm(WidgetTester tester) async {
      await pumpParcours(tester);
      await tester.tap(find.text(texte.homeOpenTask));
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.taskWriteTitle));
      await tester.pumpAndSettle();
    }

    testWidgets('le bouton attend une phrase', (tester) async {
      await openForm(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, texte.newPreparationOpen),
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

      await tester.tap(find.text(texte.newPreparationOpen));
      await tester.pumpAndSettle();

      expect(find.byType(PreparationPage), findsOneWidget);
      // La phrase d'ouverture est la seule chose que le pasteur ait dite que
      // le serveur garde vraiment : elle ouvre le fil, et tient lieu de titre
      // tant qu'aucune unité n'est bornée.
      expect(find.text('Que l\'amour fraternel continue.'), findsNWidgets(2));
    });

    testWidgets('la préparation ouverte rejoint l\'accueil', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextField), 'Romains 8:15');
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.newPreparationOpen));
      await tester.pumpAndSettle();

      // Retour à l'accueil : le formulaire a été remplacé, donc un seul retour.
      await tester.tap(find.byTooltip(texte.back));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Romains 8:15'), findsOneWidget);
    });
  });
}
