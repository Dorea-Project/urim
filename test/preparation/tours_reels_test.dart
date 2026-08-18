import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/turn.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import '../support/pump_app.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import '../support/tours_reels.dart';

/// L'ecran d'un telephone ordinaire, pas la surface geante des autres tests.
///
/// Les tests d'ecran existants agrandissent la fenetre pour que tout le fil
/// tienne dans l'arbre. C'est commode et c'est exactement ce qui masquerait le
/// probleme cherche ici : **un tour reel deborde-t-il un vrai telephone ?**
const _telephone = Size(390, 844);

/// Les libelles viennent de la meme source que l'ecran.
final texte = AppTextFr();

void main() {
  group('ce que le moteur envoie vraiment', () {
    test('le tour d\'ouverture melange axes et passages', () async {
      // Ma maquette en montrait trois. Le corpus en sert seize, et les deux
      // natures voyagent dans le meme bloc : les dix loci, puis des passages
      // qui traitent le sujet — « aller droit a un texte ».
      final tour = (ToursReels.etude(ToursReels.ouverture)).turn!;
      final pastilles = tour.blocks.whereType<ChipsBlock>().single.items;

      expect(pastilles, hasLength(16));
      expect(pastilles.where((p) => p.origin == 'locus'), hasLength(10));
      expect(
        pastilles.where((p) => p.origin != 'locus').map((p) => p.code),
        contains('1 Jean 4:7-21'),
        reason: 'un code d\'option peut etre une reference, pas un slug',
      );
    });

    test('le code d\'un axe pese n\'a pas de prefixe', () {
      // Les pastilles portent `axe:anthropologie`, les pesees `anthropologie`.
      // Fabriquer le code cote client au lieu de reprendre celui du serveur
      // ferait refuser une decision sur deux.
      final tour = ToursReels.etude(ToursReels.pesees).turn!;
      final pesees = tour.blocks.whereType<BearingsBlock>().single;

      expect(
        pesees.items.map((i) => i.axisCode),
        isNot(contains(startsWith('axe:'))),
      );
    });

    test('l\'etage des pesees se detache des le tour suivant', () {
      // A `bear_axes`, les deux coincident — c'est l'etage qui produit les
      // pesees. Des le tour d'apres elles deviennent du decor ambiant et
      // gardent leur etage : c'est la que les envoyer a l'etage courant
      // ferait refuser la decision.
      expect(ToursReels.etude(ToursReels.pesees).turn!.stageCode, 'bear_axes');

      for (final nom in [ToursReels.miseEnForme, ToursReels.theme]) {
        final tour = ToursReels.etude(nom).turn!;
        final pesees = tour.blocks.whereType<BearingsBlock>().single;

        expect(pesees.decideStage, 'bear_axes');
        expect(tour.stageCode, isNot('bear_axes'), reason: nom);
      }
    });

    test('a l\'etage des pesees, les memes axes sont proposes deux fois', () {
      // Constat, pas approbation : `bear_axes` sert ses options en pastilles
      // **et** les memes axes en pesees. Le pasteur voit « Christologie »
      // deux fois sur le meme tour, une fois nu et une fois avec sa force et
      // son motif. Ce test existe pour que le jour ou ca change, on le sache.
      final tour = ToursReels.etude(ToursReels.pesees).turn!;
      final pastilles = tour.blocks.whereType<ChipsBlock>().single.items;
      final choisissables = tour.blocks
          .whereType<BearingsBlock>()
          .single
          .items
          .where((i) => i.selectable);

      expect(
        choisissables.map((i) => i.label).toSet(),
        pastilles.map((p) => p.label).toSet(),
      );
    });

    test('le motif peut faire un paragraphe entier', () async {
      // 1 423 caracteres a l'etage des mises en forme : la liste des couples
      // ecartes, avec leur raison, est dans le motif.
      final tour = (ToursReels.etude(ToursReels.miseEnForme)).turn!;

      expect(tour.why.length, greaterThan(1000));
    });

    test('les pesees et la faisabilite reviennent a chaque tour', () async {
      // C'est du decor ambiant, par conception : elles accompagnent tous les
      // tours qui suivent l'etage qui les a produites. L'ecran les affiche
      // donc trois fois de suite, et doit rester lisible.
      for (final nom in [
        ToursReels.pesees,
        ToursReels.miseEnForme,
        ToursReels.theme,
        ToursReels.parole,
      ]) {
        final tour = (ToursReels.etude(nom)).turn!;

        expect(tour.blocks.whereType<BearingsBlock>().single.items,
            hasLength(10), reason: nom);
        expect(tour.blocks.whereType<FeasibilityBlock>().single.items,
            hasLength(18), reason: nom);
      }
    });

    test('aucun tour ne finit sur un mur', () async {
      for (final nom in ToursReels.tous) {
        final tour = (ToursReels.etude(nom)).turn!;

        expect(
          tour.offersChoice || tour.ask.isNotEmpty,
          isTrue,
          reason: '$nom : ni geste ni question',
        );
      }
    });

    test('le filet dore n\'est jamais vide', () async {
      // « Chaque reponse porte son motif » est une regle du produit, pas un
      // confort : un tour sans motif serait une conclusion sans provenance.
      for (final nom in ToursReels.tous) {
        final tour = (ToursReels.etude(nom)).turn!;
        expect(tour.why, isNotEmpty, reason: nom);
      }
    });

    test('l\'unite bornee est une phrase, pas une reference', () async {
      // « L'amour comme preuve de la connaissance de Dieu » — c'est ce que la
      // barre de titre affiche. La reference, elle, vit dans le motif.
      final etude = ToursReels.etude(ToursReels.theme);

      expect(etude.pericopeLabel, isNotNull);
      expect(etude.pericopeLabel!.length, greaterThan(20));
    });

    test('le fil sert une ligne par preparation, sans phrase d\'Urim',
        () async {
      final lignes = ToursReels.lignes();

      expect(lignes, isNotEmpty);
      for (final ligne in lignes) {
        expect(ligne.rawInput, isNotEmpty);
      }
    });
  });

  group('l\'ecran tient la charge reelle', () {
    Future<void> pumpTour(WidgetTester tester, Study etude) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = _telephone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(DepotFige(etude)),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'x')),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final nom in ToursReels.tous) {
      testWidgets('$nom se rend sans deborder', (tester) async {
        await pumpTour(tester, ToursReels.etude(nom));

        // Un debordement leve une FlutterError que le harnais capture : c'est
        // exactement ce qu'on vient chercher.
        expect(tester.takeException(), isNull);
      });

      testWidgets('$nom : les trois phrases sont a l\'ecran', (tester) async {
        final etude = ToursReels.etude(nom);
        await pumpTour(tester, etude);

        final tour = etude.turn!;
        expect(find.text(tour.say), findsOneWidget);
        expect(find.text(tour.why), findsOneWidget,
            reason: 'le motif ne se replie pas');
        if (tour.ask.isNotEmpty) {
          expect(find.text(tour.ask), findsOneWidget);
        }
      });
    }

    testWidgets('les seize pastilles sont toutes atteignables', (tester) async {
      final etude = ToursReels.etude(ToursReels.ouverture);
      await pumpTour(tester, etude);

      final pastilles =
          etude.turn!.blocks.whereType<ChipsBlock>().single.items;

      // ⚠️ Trouver le widget ne prouve rien : un tour entier est **un seul**
      // element de liste, donc tous ses enfants sont dans l'arbre, y compris
      // ceux a 1 600 px sous le pli. Ce qui se verifie, c'est qu'on peut les
      // amener a l'ecran et les toucher.
      final derniere = find.text(pastilles.last.label);
      expect(derniere, findsOneWidget);
      expect(
        tester.getRect(derniere).top,
        greaterThan(_telephone.height),
        reason: 'seize pastilles ne tiennent pas sur un ecran — c\'est le fait',
      );

      await tester.ensureVisible(derniere);
      await tester.pumpAndSettle();

      final place = tester.getRect(derniere);
      expect(place.top, greaterThanOrEqualTo(0.0));
      expect(place.bottom, lessThanOrEqualTo(_telephone.height));
    });

    testWidgets('un tour reel tient en quelques ecrans, decor replie',
        (tester) async {
      // ⚠️ **Le chiffre qui dit si le compagnon fait gagner du temps.**
      //
      // 🔴 Avant le repli, un tour de `shape_homiletic` faisait **11,1 ecrans**
      // sur un telephone de 844 px, le theme 9,0 et la parole 9,3 — parce que
      // dix pesees et dix-huit couples plan x matiere se republiaient a chaque
      // tour. Le pasteur traversait sa propre matiere deja lue pour atteindre
      // son geste, et il n'a pas ce temps-la.
      //
      // Depuis que le tour dit **de quoi il parle** (`speaks`), l'ecran deplie
      // ce bloc-la et replie le reste sous son intitule et son nombre :
      // 11,1 → 3,4 ecrans, 9,0 → 1,3.
      //
      // Ce test garde le gain. Il tombera si le decor se redeplie.
      final couts = <String, double>{};

      for (final nom in [
        ToursReels.ouverture,
        ToursReels.bornes,
        ToursReels.miseEnForme,
        ToursReels.theme,
      ]) {
        await pumpTour(tester, ToursReels.etude(nom));

        final position =
            tester.state<ScrollableState>(find.byType(Scrollable).first).position;
        couts[nom] =
            (position.maxScrollExtent + position.viewportDimension) /
                _telephone.height;
      }

      expect(couts[ToursReels.bornes], lessThan(3),
          reason: 'un tour sans decor tient en deux ecrans');
      expect(couts[ToursReels.ouverture], inInclusiveRange(3, 6),
          reason: 'seize pastilles, et c\'est bien d\'elles que le tour parle');
      expect(couts[ToursReels.miseEnForme], lessThan(5),
          reason: 'le decor est replie, pas supprime');
      expect(couts[ToursReels.theme], lessThan(3),
          reason: 'le theme est court : rien ne doit l\'enterrer');
    });

    testWidgets('le tour deplie ce dont il parle, et replie le reste',
        (tester) async {
      final etude = ToursReels.etude(ToursReels.theme);
      await pumpTour(tester, etude);

      // Le serveur dit que ce tour parle du theme.
      expect(etude.turn!.speaks, 'theme');
      expect(find.text('THÈME'), findsOneWidget);

      // Les dix pesees et les dix-huit couples sont replies — leur intitule
      // porte leur nombre, parce que replier n'est pas cacher.
      expect(find.text(texte.turnFoldedBearings(10)), findsOneWidget);
      expect(find.text(texte.turnFoldedFeasibility(18)), findsOneWidget);

      // Et leur contenu n'est pas a l'ecran. On prend un libelle de la charge
      // elle-meme : une capture neuve peut n'avoir aucun axe dominant, et un
      // test qui suppose le contenu du corpus tombe sans que rien ne soit
      // casse.
      final pesees =
          etude.turn!.blocks.whereType<BearingsBlock>().single.items;
      expect(find.text(pesees.first.label), findsNothing);
    });

    testWidgets('un decor replie se rouvre, et rien n\'a disparu',
        (tester) async {
      // La garde qui distingue ranger d'escamoter. Les refuses d'une grille de
      // faisabilite doivent rester atteignables : les cacher laisserait croire
      // qu'on n'y a pas pense.
      final etude = ToursReels.etude(ToursReels.theme);
      await pumpTour(tester, etude);

      final pesees =
          etude.turn!.blocks.whereType<BearingsBlock>().single.items;

      await tester.tap(find.text(texte.turnFoldedBearings(pesees.length)));
      await tester.pumpAndSettle();

      // Les dix axes sont revenus, avec leur motif — y compris les absents,
      // que le corpus a relus et dont il dit « le texte n'en dit rien ».
      for (final axe in pesees) {
        expect(find.text(axe.label), findsWidgets, reason: axe.label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('un geste ouvert ne se replie jamais', (tester) async {
      // Les sorties accompagnent le theme sans etre son sujet — mais « Ecrire
      // mes points » est un geste, et un geste replie est un geste perdu.
      await pumpTour(tester, ToursReels.etude(ToursReels.theme));

      expect(find.text('Écrire mes points'), findsOneWidget);
    });

    testWidgets('toucher une pastille poste l\'etage du tour', (tester) async {
      final etude = ToursReels.etude(ToursReels.ouverture);
      final depot = DepotFige(etude);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = _telephone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(depot),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Théologie propre — Dieu'));
      await tester.pumpAndSettle();

      expect(depot.decisions.single,
          ('weigh_conviction', 'axe:theologie_propre'));
    });

    testWidgets('un axe pese poste sur bear_axes, pas sur l\'etage du tour',
        (tester) async {
      // Le piege que le contrat nomme, verifie sur la vraie charge. Le tour
      // des mises en forme, et pas celui des pesees : c'est la que les deux
      // etages different, et c'est la que l'erreur serait possible.
      final etude = ToursReels.etude(ToursReels.miseEnForme);
      final depot = DepotFige(etude);
      final pesees =
          etude.turn!.blocks.whereType<BearingsBlock>().single;
      final choisissable = pesees.items.firstWhere((i) => i.selectable);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = _telephone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(depot),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      // ⚠️ Les pesees sont du decor a cet etage : elles sont **repliees**. Le
      // geste doit rester atteignable — c'est toute la difference entre ranger
      // et escamoter.
      final repli = find.text(texte.turnFoldedBearings(pesees.items.length));
      await tester.ensureVisible(repli);
      await tester.pumpAndSettle();
      await tester.tap(repli);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(choisissable.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(choisissable.label));
      await tester.pumpAndSettle();

      expect(depot.decisions.single, ('bear_axes', choisissable.axisCode));
      expect(etude.turn!.stageCode, isNot('bear_axes'));
    });
  });
}
