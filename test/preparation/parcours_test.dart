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
import 'package:urim/presentation/preparation/preparation_page.dart';

import '../support/pump_app.dart';

/// Les libelles viennent de la meme source que l'ecran.
final texte = AppTextFr();

/// Le parcours des maquettes, d'un bout a l'autre : l'accueil — qui **est** la
/// conversation — son tiroir, sa bascule, et le champ qui ouvre un travail neuf.
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

    // Un routeur reduit aux ecrans du parcours : la redirection d'acces
    // demanderait une session, et ce n'est pas ce qui est verifie ici.
    final router = GoRouter(
      initialLocation: AppRoutes.homePath,
      routes: [
        GoRoute(
          path: AppRoutes.homePath,
          name: AppRoutes.homeName,
          builder: (context, state) => const HomePage(),
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

  /// Le tiroir s'ouvre par son geste, pas par un bouton qu'on cherche.
  Future<void> ouvrirTiroir(WidgetTester tester) async {
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await tester.pumpAndSettle();
  }

  group('l\'accueil est la conversation', () {
    testWidgets('on arrive dans le travail qui attend une reponse',
        (tester) async {
      await pumpParcours(tester);

      // Plus de redirection : ce qu'Urim a demande est deja la, sous la barre.
      expect(find.text('Lequel retenez-vous ?'), findsOneWidget);
    });

    testWidgets('aucune liste ne s\'interpose', (tester) async {
      await pumpParcours(tester);

      // 🔴 Le fil groupe par recence occupait l'accueil, et la conversation
      // vivait un ecran plus loin. Il est passe au tiroir.
      expect(find.text(texte.homeGroupThisWeek), findsNothing);
      expect(find.text(texte.homeGroupEarlier), findsNothing);
    });
  });

  group('le tiroir', () {
    testWidgets('il porte l\'historique, et dit ce qui attend', (tester) async {
      await pumpParcours(tester);
      await ouvrirTiroir(tester);

      expect(find.text(texte.drawerNewPreparation), findsOneWidget);
      expect(find.text(texte.drawerPreparations), findsOneWidget);
      expect(find.text('Amour fraternel'), findsWidgets);
      expect(find.text('Actes 2:42-47'), findsWidgets);

      // Le vocabulaire du moteur passe entier : « rend la main » **est**
      // `await_decision`, et le tiroir sert justement a retrouver ce qu'on a
      // laisse en plan.
      expect(
        find.text(turnOutcomeLabel(texte, TurnOutcome.handsBack)),
        findsWidgets,
      );
    });

    testWidgets('une predication transcrite n\'est pas dans l\'historique',
        (tester) async {
      await pumpParcours(tester);
      await ouvrirTiroir(tester);

      // Elle a sa page. Sans quoi la bascule montrerait deux fois la meme.
      expect(find.textContaining('prêché le'), findsNothing);
    });

    testWidgets('en choisir une la met a l\'ecran', (tester) async {
      await pumpParcours(tester);
      await ouvrirTiroir(tester);

      await tester.tap(find.text('Actes 2:42-47').last);
      await tester.pumpAndSettle();

      // On n'a pas quitte l'accueil pour autant : la conversation s'y monte.
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(PreparationConversation), findsOneWidget);
    });

    testWidgets('« Nouvelle preparation » rend le champ vide', (tester) async {
      await pumpParcours(tester);
      await ouvrirTiroir(tester);

      await tester.tap(find.text(texte.drawerNewPreparation));
      await tester.pumpAndSettle();

      expect(find.text(texte.homeEmptyTitle), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('il suit l\'ecran : cote predications, il change', (tester) async {
      await pumpParcours(tester);

      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.record_voice_over_outlined),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.homeSwitchPreach));
      await tester.pumpAndSettle();
      await ouvrirTiroir(tester);

      // Le geste neuf devient celui du travail en cours, et l'historique aussi.
      expect(find.text(texte.drawerPreached), findsOneWidget);
      expect(find.text(texte.drawerNewPreparation), findsNothing);
      expect(find.text(texte.drawerPreparations), findsNothing);
    });
  });

  group('la bascule', () {
    Finder icone(IconData icon) => find.ancestor(
          of: find.byIcon(icon),
          matching: find.byType(IconButton),
        );

    testWidgets('elle demande avant d\'agir', (tester) async {
      await pumpParcours(tester);

      await tester.tap(icone(Icons.record_voice_over_outlined));
      await tester.pumpAndSettle();

      // Une icone seule n'explique pas ou elle emmene : la feuille pose la
      // question et nomme la destination.
      expect(find.text(texte.homeSwitchTitle), findsOneWidget);
      expect(find.text(texte.homeSwitchPreach), findsOneWidget);

      // 🔴 **Une seule destination.** La feuille montrait les deux travaux, dont
      // celui qu'on avait deja sous les yeux : une liste a relire pour retrouver
      // ou l'on etait, alors que l'ecran le disait deja.
      expect(find.text(texte.homeSwitchPrepare), findsNothing);
    });

    testWidgets('choisir l\'autre travail change d\'ecran', (tester) async {
      await pumpParcours(tester);

      await tester.tap(icone(Icons.record_voice_over_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.homeSwitchPreach));
      await tester.pumpAndSettle();

      expect(find.textContaining('prêché le'), findsOneWidget);

      // 🔴 **Le bouton a pris vie.** Il est resté inactif tant que Q2 n'était
      // pas tranchée ; l'étage 1 ne dépend pas du moteur de transcription —
      // capter, conserver, purger. Ce qui reste en attente est le transcript,
      // et la ligne du dessous le dit toujours.
      final bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, texte.homeRecordSermon),
      );
      expect(bouton.onPressed, isNotNull);
      expect(
        find.textContaining('moteur de transcription n\'est pas encore'),
        findsOneWidget,
      );
    });
  });

  group('le composeur', () {
    /// Le champ n'apparait que quand il n'y a rien a reprendre : autrement,
    /// c'est la conversation qui occupe l'ecran.
    Future<void> champVide(WidgetTester tester) async {
      await pumpParcours(tester);
      await ouvrirTiroir(tester);
      await tester.tap(find.text(texte.drawerNewPreparation));
      await tester.pumpAndSettle();
    }

    Future<void> ecrire(WidgetTester tester, String phrase) async {
      await tester.enterText(find.byType(TextField), phrase);
      await tester.pumpAndSettle();
    }

    testWidgets('rien a ouvrir tant que rien n\'est ecrit', (tester) async {
      await champVide(tester);

      expect(find.byTooltip(texte.newPreparationOpen), findsNothing);
    });

    testWidgets('la date du culte n\'apparait qu\'avec la phrase',
        (tester) async {
      await champVide(tester);

      expect(find.text(texte.newPreparationServiceDate), findsNothing);

      await ecrire(tester, 'Romains 8:15');

      expect(find.text(texte.newPreparationServiceDate), findsOneWidget);
      expect(find.byTooltip(texte.newPreparationOpen), findsOneWidget);
    });

    testWidgets('ouvrir continue sur place, sans changer d\'ecran',
        (tester) async {
      await champVide(tester);
      await ecrire(tester, 'Que l\'amour fraternel continue.');

      await tester.tap(find.byTooltip(texte.newPreparationOpen));
      await tester.pumpAndSettle();

      // 🔴 La repetition d'avant : le champ poussait un ecran portant un second
      // champ identique. La conversation prend la place du champ vide.
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(PreparationConversation), findsOneWidget);
      expect(find.text(texte.homeEmptyTitle), findsNothing);
    });
  });
}
