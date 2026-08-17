import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/home/home_view_model.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import 'package:urim/presentation/preparation/widgets/block_views.dart';
import '../support/pump_app.dart';

/// Horloge figée : les étiquettes « HIER 20:58 » doivent être vérifiables.
final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Identifiants prévisibles.
final class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

/// Les libelles viennent de la meme source que l'ecran.
final texte = AppTextFr();

void main() {
  final fixedNow = DateTime(2026, 8, 15, 10);

  ProviderContainer makeContainer() => ProviderContainer.test(
        overrides: [
          clockProvider.overrideWithValue(_FixedClock(fixedNow)),
          idGeneratorProvider.overrideWithValue(_SequentialIds()),
        ],
      );

  /// Le fil applique les réglages de lecture : sans préférences, l'écran ne se
  /// monte pas.
  Future<SharedPreferences> emptyPreferences() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return SharedPreferences.getInstance();
  }

  group('jeu d\'exemple', () {
    test('les quatre états des maquettes sont représentés', () async {
      final container = makeContainer();
      final repository = container.read(preparationRepositoryProvider);

      final preparations = await repository.watchPreparations().first;

      expect(
        preparations.valueOrNull!.map((p) => p.state).toSet(),
        PreparationState.values.toSet(),
      );
    });

    test('le fil guidé alterne ce que tu dis et ce qu\'Urim rend', () async {
      final container = makeContainer();
      final repository = container.read(preparationRepositoryProvider);

      final guided =
          (await repository.getById(repository.seededId!)).valueOrNull!;

      expect(guided.title, 'Amour fraternel');
      expect(guided.state, PreparationState.handsBack);
      expect(guided.blocks.whereType<UserBlock>(), hasLength(3));
      expect(guided.blocks.whereType<UrimTurn>(), hasLength(3));

      // Le dernier tour attend une réponse : c'est ce qui met la préparation
      // en tête de l'accueil.
      expect((guided.blocks.last as UrimTurn).asksSomething, isTrue);
    });

    test('les textes pesés portent les trois postures', () async {
      final container = makeContainer();
      final repository = container.read(preparationRepositoryProvider);

      final guided =
          (await repository.getById(repository.seededId!)).valueOrNull!;

      final weighed = guided.blocks
          .whereType<UrimTurn>()
          .expand((turn) => turn.texts)
          .toList();

      expect(weighed.map((text) => text.stance).toSet(), {
        TextStance.subject,
        TextStance.supports,
        TextStance.complicates,
      });
      expect(
        weighed.where((text) => text.stance.resists),
        hasLength(2),
        reason: 'ce qui résiste n\'est pas une note de bas de page',
      );
    });

    test('la recherche atteint le raisonnement d\'Urim', () async {
      final container = makeContainer();
      final repository = container.read(preparationRepositoryProvider);

      expect(
        (await repository.search('proof-texting')).valueOrNull,
        hasLength(1),
      );
      // Le passage cité dans le fil guidé, et le mouvement de la synthèse sur
      // la péricope : deux travaux distincts parlent de la même chose.
      expect(
        (await repository.search('fraction du pain')).valueOrNull,
        hasLength(2),
      );
      expect((await repository.search('   ')).valueOrNull, isEmpty);
    });
  });

  group('ouverture d\'une préparation', () {
    test('le titre est tiré des premiers mots', () async {
      final container = makeContainer();
      final repository = container.read(preparationRepositoryProvider);

      final opened = (await repository.open(
        text: '« l\'amour fraternel n\'existe plus dans l\'église »',
      ))
          .valueOrNull!;

      expect(opened.title, 'L\'amour fraternel n\'existe plus');
      expect(opened.blocks, hasLength(1));
      expect((opened.blocks.single as UserBlock).text, contains('amour'));
      expect(opened.updatedAt, fixedNow);
    });

    test('une phrase vide est refusée, pas ouverte', () async {
      final container = makeContainer();

      final failure = (await container
              .read(preparationRepositoryProvider)
              .open(text: '   '))
          .failureOrNull;

      expect(failure, isNotNull);
    });

    test('la date du culte est conservée', () async {
      final container = makeContainer();
      final service = DateTime(2026, 8, 17);

      final opened = (await container
              .read(preparationRepositoryProvider)
              .open(text: 'Actes 2', serviceDate: service))
          .valueOrNull!;

      expect(opened.serviceDate, service);
    });
  });

  group('regroupement de l\'accueil', () {
    StudySummary at(DateTime when) => StudySummary(
          id: when.toIso8601String(),
          rawInput: 'x',
          lastActivity: when,
        );

    test('la semaine d\'un côté, le reste de l\'autre', () {
      final groups = groupByRecency(
        [
          at(fixedNow.subtract(const Duration(hours: 13))),
          at(fixedNow.subtract(const Duration(days: 4))),
          at(fixedNow.subtract(const Duration(days: 11))),
        ],
        now: fixedNow,
      );

      expect(
        groups.map((group) => group.recency),
        [Recency.thisWeek, Recency.earlier],
      );
      expect(groups.first.summaries, hasLength(2));
      expect(groups.last.summaries, hasLength(1));
    });

    test('un groupe vide ne s\'affiche pas', () {
      final groups = groupByRecency([at(fixedNow)], now: fixedNow);

      expect(groups, hasLength(1));
      expect(groups.single.recency, Recency.thisWeek);
    });
  });

  group('étiquettes temporelles', () {
    test('un repère média s\'affiche en minutes et secondes', () {
      expect(formatAnchor(texte, const MediaAnchor(Duration(minutes: 3, seconds: 10))),
          '03:10');
      expect(
        formatAnchor(texte, const MediaAnchor(Duration(hours: 1, minutes: 4, seconds: 22))),
        '1:04:22',
      );
    });

    test('un repère horloge distingue aujourd\'hui, hier et une date', () {
      final today = DateTime(2026, 8, 15, 14, 2);
      final yesterday = DateTime(2026, 8, 14, 20, 58);
      final older = DateTime(2026, 8, 4, 9, 5);

      expect(formatAnchor(texte, ClockAnchor(today), now: fixedNow),
          'AUJOURD\'HUI 14:02');
      expect(formatAnchor(texte, ClockAnchor(yesterday), now: fixedNow), texte.blockYesterday('20:58'));
      expect(formatAnchor(texte, ClockAnchor(older), now: fixedNow), texte.blockOnDate('4 AOÛT', '09:05'));
    });
  });

  group('écran du fil', () {
    Future<String> pumpThread(WidgetTester tester) async {
      late String preparationId;
      final preferences = await emptyPreferences();

      // Une surface haute : le fil compte plusieurs blocs, et un écran de
      // test standard en laisserait la fin hors du viewport — donc hors de
      // l'arbre, donc introuvable.
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(_FixedClock(fixedNow)),
            idGeneratorProvider.overrideWithValue(_SequentialIds()),
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              preparationId = ref.watch(preparationRepositoryProvider).seededId!;
              return wrapScreen(
                PreparationPage(preparationId: preparationId),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      return preparationId;
    }

    testWidgets('le tour d\'Urim montre son raisonnement et ses choix',
        (tester) async {
      await pumpThread(tester);

      expect(find.textContaining('Six de tes mots sont dans l\'Écriture'),
          findsOneWidget);
      expect(find.text('Sur quel axe veux-tu prêcher ?'), findsOneWidget);
      expect(find.text('L\'Église'), findsWidgets);
      expect(find.text('Le péché'), findsOneWidget);
      expect(find.textContaining('Voir les dix loci'), findsOneWidget);
    });

    testWidgets('les textes qui résistent sont affichés au même rang',
        (tester) async {
      await pumpThread(tester);

      expect(find.text(textStanceLabel(texte, TextStance.subject)), findsOneWidget);
      expect(find.text(textStanceLabel(texte, TextStance.supports)), findsOneWidget);
      expect(find.text(textStanceLabel(texte, TextStance.complicates)), findsNWidgets(2));
      expect(find.text('1 Corinthiens 11:17-22'), findsOneWidget);
    });

    testWidgets('« Comment j\'en suis arrivé là » se déplie', (tester) async {
      await pumpThread(tester);

      expect(find.textContaining('Tes mots recoupent le vocabulaire'),
          findsNothing);

      await tester.tap(find.text('Comment j\'en suis arrivé là'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Tes mots recoupent le vocabulaire'),
        findsOneWidget,
      );
    });

    testWidgets('répondre par un choix ajoute la réponse au fil',
        (tester) async {
      await pumpThread(tester);

      await tester.tap(find.text('La péricope entière'));
      await tester.pumpAndSettle();

      // La réponse devient une bulle : le libellé apparaît une seconde fois.
      expect(find.text('La péricope entière'), findsNWidgets(2));
    });

    testWidgets('seule la dernière question est cliquable', (tester) async {
      await pumpThread(tester);

      await tester.tap(find.text('Le péché'));
      await tester.pumpAndSettle();

      expect(
        find.text('Le péché'),
        findsOneWidget,
        reason: 'une question déjà répondue ne se rejoue pas',
      );
    });

    testWidgets('écrire dans la barre ajoute un bloc au fil', (tester) async {
      await pumpThread(tester);

      await tester.enterText(
        find.byType(TextField),
        'Je garde la péricope entière.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(find.text('Je garde la péricope entière.'), findsOneWidget);
    });

    testWidgets('la dictée est visible mais inactive', (tester) async {
      await pumpThread(tester);

      final mic = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.mic_none),
          matching: find.byType(IconButton),
        ),
      );

      expect(
        mic.onPressed,
        isNull,
        reason: 'la dictée dépend du moteur de reconnaissance vocale (Q2)',
      );
    });
  });
}
