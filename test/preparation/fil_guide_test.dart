import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/domain/entities/preparation/turn.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import '../support/pump_app.dart';

/// Répond ce qu'on lui a mis dans la bouche, sans réseau.
final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final String body;

  /// Ce que le client a réellement envoyé — c'est là que se voit l'étage.
  final List<(String, Object?)> envois = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    envois.add((options.path, options.data));

    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(UrimRemoteDataSource, _StubAdapter) sourceRendant(String json) {
  final adapter = _StubAdapter(json);
  final dio = Dio(BaseOptions(baseUrl: 'http://serveur/api/mobile'))
    ..httpClientAdapter = adapter;
  return (UrimRemoteDataSource(dio), adapter);
}

/// Un tour complet, tel que `construire_tour` le rend côté serveur.
const _tourComplet = '''
{
  "id": "3f6c1b2e-0000-4000-8000-000000000001",
  "status": "ouverte",
  "raw_input": "l'amour fraternel n'existe plus dans l'église",
  "outcome": "await_decision",
  "theme": null,
  "pericope_label": "Actes 2:42-47",
  "axis_code": "axe:ecclesiologie",
  "bounds_overridden": false,
  "turn": {
    "say": "Voici les textes relus qui disent quelque chose de cet axe.",
    "why": "Votre formulation est chargée — j'affiche davantage de textes qui résistent.",
    "ask": "Lequel ouvrons-nous ?",
    "expects": "choice",
    "stage_code": "find_units",
    "signature": "ia-mistral",
    "blocks": [
      {
        "kind": "units",
        "groups": [
          {
            "role": "dominant",
            "heading": "En fait son sujet",
            "items": [
              {
                "code": "unit:act-2-42",
                "label": "Actes 2:42-47",
                "reference": "Actes 2:42-47",
                "rationale": "Quatre appuis énumérés au même niveau."
              }
            ]
          },
          {
            "role": "resiste",
            "heading": "Lui résiste",
            "items": [
              {
                "code": "unit:1co-11-17",
                "label": "1 Corinthiens 11:17-22",
                "reference": "1 Corinthiens 11:17-22",
                "rationale": "La même assemblée qui rompt le pain s'y divise."
              }
            ]
          }
        ]
      },
      {
        "kind": "bearings",
        "decide_stage": "bear_axes",
        "caveats": ["Le risque de proof-texting est relevé."],
        "items": [
          {
            "axis_code": "axe:ecclesiologie",
            "label": "L'Église",
            "strength": "dominant",
            "rationale": "Les quatre appuis décrivent ce qui tient l'assemblée.",
            "selected": true,
            "selectable": false
          },
          {
            "axis_code": "axe:pneumatologie",
            "label": "L'Esprit",
            "strength": "porte",
            "rationale": "Le contexte immédiat est celui de la Pentecôte.",
            "selected": false,
            "selectable": true
          }
        ]
      },
      { "kind": "theme", "body": "La communion comme pratique." },
      {
        "kind": "actions",
        "items": [
          { "code": "elements", "label": "Écrire mes points", "enabled": true },
          {
            "code": "deck",
            "label": "PowerPoint",
            "enabled": false,
            "unavailable_reason": "Une citation projetée doit d'abord être contrôlée."
          }
        ]
      },
      { "kind": "arbitrage", "items": [] }
    ]
  }
}''';

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
  final texte = AppTextFr();
  final fixedNow = DateTime(2026, 8, 15, 10);

  group('le tour que le serveur rend', () {
    test('les trois phrases traversent sans être réécrites', () async {
      final (source, _) = sourceRendant(_tourComplet);

      final tour = (await source.getStudy('x')).turn!;

      expect(tour.say, startsWith('Voici les textes relus'));
      expect(tour.why, startsWith('Votre formulation est chargée'));
      expect(tour.ask, 'Lequel ouvrons-nous ?');
      expect(tour.expects, TurnExpects.choice);
      expect(tour.stageCode, 'find_units');
      expect(tour.signature, 'ia-mistral');
    });

    test('les sept natures de bloc sont typées, l\'inconnue est tolérée',
        () async {
      final (source, _) = sourceRendant(_tourComplet);

      final blocs = (await source.getStudy('x')).turn!.blocks;

      expect(blocs.map((b) => b.runtimeType).toList(), [
        UnitsBlock,
        BearingsBlock,
        ThemeBlock,
        ActionsBlock,
        // `arbitrage` n'existe pas dans cette version : le tour reste lisible
        // au lieu de tomber.
        UnknownBlock,
      ]);
    });

    test('ce qui résiste arrive au même rang que ce qui porte', () async {
      final (source, _) = sourceRendant(_tourComplet);

      final unites = (await source.getStudy('x')).turn!.blocks.first
          as UnitsBlock;

      expect(unites.groups.map((g) => g.role), ['dominant', 'resiste']);
      // L'intitulé vient du serveur : l'application ne le fabrique pas.
      expect(unites.groups.last.heading, 'Lui résiste');
    });

    test('les pesées portent leur propre étage', () async {
      // C'est le piège que le contrat nomme : rendre ces axes cliquables et
      // les envoyer à l'étage du tour ferait refuser la décision.
      final (source, _) = sourceRendant(_tourComplet);

      final tour = (await source.getStudy('x')).turn!;
      final pesees =
          tour.blocks.whereType<BearingsBlock>().single;

      expect(tour.stageCode, 'find_units');
      expect(pesees.decideStage, 'bear_axes');
      expect(pesees.items.where((i) => i.selectable).single.label, 'L\'Esprit');
      // On ne propose pas de reprendre l'axe déjà retenu.
      expect(pesees.items.first.selected, isTrue);
      expect(pesees.items.first.selectable, isFalse);
    });

    test('un bouton fermé porte son motif', () async {
      final (source, _) = sourceRendant(_tourComplet);

      final sorties = (await source.getStudy('x'))
          .turn!
          .blocks
          .whereType<ActionsBlock>()
          .single;

      final ferme = sorties.items.firstWhere((item) => !item.enabled);
      expect(ferme.unavailableReason, isNotEmpty);
    });

    test('aucun tour ne finit sur un mur', () async {
      final (source, _) = sourceRendant(_tourComplet);

      final tour = (await source.getStudy('x')).turn!;

      // Des options à toucher, ou une question posée : jamais rien des deux.
      expect(tour.offersChoice || tour.ask.isNotEmpty, isTrue);
    });
  });

  group('ce que le client envoie', () {
    test('décider poste l\'étage et le code, rien d\'autre', () async {
      final (source, adapter) = sourceRendant(_tourComplet);

      await source.decide(
        studyId: 'etude-1',
        stageCode: 'bear_axes',
        optionCode: 'axe:pneumatologie',
      );

      final (chemin, corps) = adapter.envois.single;
      expect(chemin, '/urim/studies/etude-1/decisions');
      expect(corps, {
        'stage_code': 'bear_axes',
        'option_code': 'axe:pneumatologie',
      });
    });

    test('écarter passe par sa propre route', () async {
      // Écarter n'avance aucun étage : confondre les deux gestes ferait
      // avancer le pipeline sur une option qu'on vient de repousser.
      final (source, adapter) = sourceRendant(_tourComplet);

      await source.dismiss(
        studyId: 'etude-1',
        stageCode: 'weigh_conviction',
        optionCode: 'axe:hamartiologie',
      );

      expect(adapter.envois.single.$1, '/urim/studies/etude-1/dismissals');
    });

    test('parler n\'envoie aucun étage', () async {
      // C'est ce qui distingue le geste d'une décision : le pasteur parle, il
      // ne répond pas à un formulaire. L'étage, le serveur le connaît.
      final (source, adapter) = sourceRendant(_tourComplet);

      await source.say(studyId: 'etude-1', rawInput: 'Quel plan je peux tenir ?');

      final (chemin, corps) = adapter.envois.single;
      expect(chemin, '/urim/studies/etude-1/turns');
      expect(corps, {'raw_input': 'Quel plan je peux tenir ?'});
    });

    test('une date de culte voyage en jour, pas en instant', () async {
      final (source, adapter) = sourceRendant(_tourComplet);

      await source.open(
        rawInput: 'Actes 2',
        serviceDate: DateTime(2026, 8, 23, 14, 30),
      );

      expect(
        (adapter.envois.single.$2 as Map)['service_date'],
        '2026-08-23',
        reason: 'un instant se déplacerait d\'un fuseau à l\'autre',
      );
    });
  });

  group('l\'écran', () {
    Future<void> pumpThread(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      // Une surface haute : le tour compte plusieurs blocs, et un écran de
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
            demoConfigOverride,
          ],
          child: Consumer(
            builder: (context, ref, _) => wrapScreen(
              PreparationPage(
                preparationId:
                    ref.watch(preparationRepositoryProvider).seededId!,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le tour dit ce qu\'il a fait, son motif, et sa question',
        (tester) async {
      await pumpThread(tester);

      expect(find.text('Voici ce que je peux vous proposer ici.'),
          findsOneWidget);
      expect(find.textContaining('Six de vos mots sont dans l\'Écriture'),
          findsOneWidget);
      expect(find.text('Lequel retenez-vous ?'), findsOneWidget);
    });

    testWidgets('le motif n\'est pas replié', (tester) async {
      await pumpThread(tester);

      // Le filet doré distingue une proposition d'un oracle. Le replier
      // reviendrait à le rendre facultatif — il se lit sans rien toucher.
      expect(
        find.textContaining('Je pars donc de votre intention vers un texte.'),
        findsOneWidget,
      );
    });

    testWidgets('toucher une pastille fait avancer le moteur', (tester) async {
      await pumpThread(tester);

      await tester.tap(find.text('L\'Église'));
      await tester.pumpAndSettle();

      // Ce que le pasteur a touché devient une bulle — la pastille du tour
      // précédent reste lisible au-dessus, éteinte.
      expect(find.text('L\'Église'), findsNWidgets(2));
      expect(find.text('Voici les textes relus qui disent quelque chose de '
          'cet axe.'), findsOneWidget);
      expect(find.text('Lequel ouvrons-nous ?'), findsOneWidget);
    });

    testWidgets('un tour passé n\'est plus cliquable', (tester) async {
      await pumpThread(tester);

      await tester.tap(find.text('L\'Église'));
      await tester.pumpAndSettle();

      // « Le péché » appartient au tour précédent : le moteur a avancé, et
      // répondre l'enverrait à un étage qui n'attend plus.
      await tester.tap(find.text('Le péché'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Lequel ouvrons-nous ?'), findsOneWidget);
      expect(find.text('Le péché'), findsOneWidget,
          reason: 'aucune bulle nouvelle');
    });

    testWidgets('écrire le libellé vaut le toucher', (tester) async {
      await pumpThread(tester);

      // Les pastilles sont des raccourcis, jamais des barreaux : la barre
      // reste ouverte et désigne ce qui est à l'écran.
      await tester.enterText(find.byType(TextField), 'L\'Église');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(find.text('Lequel ouvrons-nous ?'), findsOneWidget);
    });

    testWidgets('ce qui résiste s\'affiche au même rang', (tester) async {
      await pumpThread(tester);

      await tester.tap(find.text('L\'Église'));
      await tester.pumpAndSettle();

      expect(find.text(texte.strengthDominant), findsWidgets);
      expect(find.text(texte.strengthResists), findsWidgets);
      expect(find.text('1 Corinthiens 11:17-22'), findsOneWidget);
    });

    testWidgets('la conséquence des bornes se lit avant de choisir',
        (tester) async {
      await pumpThread(tester);

      await tester.tap(find.text('L\'Église'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actes 2:42-47'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('je ne pourrai plus vous alerter'),
        findsOneWidget,
      );
      expect(find.text('Mon verset seul'), findsOneWidget);
    });

    testWidgets('un bouton fermé porte son motif', (tester) async {
      await pumpThread(tester);

      for (final libelle in [
        'L\'Église',
        'Actes 2:42-47',
        'La péricope entière',
      ]) {
        await tester.tap(find.text(libelle));
        await tester.pumpAndSettle();
      }

      expect(find.text('PowerPoint'), findsOneWidget);
      expect(
        find.textContaining('une citation projetée doit d\'abord être '
            'contrôlée'),
        findsWidgets,
      );
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
