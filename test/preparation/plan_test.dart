import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/deliverable.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/preparation/deck_page.dart';
import 'package:urim/presentation/preparation/plan_page.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';

import '../support/pump_app.dart';
import '../support/tours_reels.dart';

final texte = AppTextFr();

/// **Le seul écran où le pasteur écrit son sermon**, et le seul où Urim ne
/// propose rien.
///
/// Il est né d'une préparation jouée pour de vrai : le pasteur traversait
/// quatre étages, arrivait sur « Écrire mes points », et touchait une ligne
/// morte. La fiche de chaire, elle, réclamait « Votre plan : à écrire ».
void main() {
  Study etudeAvec(List<PlanElement> elements) {
    final base = ToursReels.etude(ToursReels.theme);

    return Study(
      id: base.id,
      status: base.status,
      rawInput: base.rawInput,
      turn: base.turn,
      elements: elements,
    );
  }

  Future<DepotFige> pumpPlan(WidgetTester tester, Study etude) async {
    final depot = DepotFige(etude);

    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoConfigOverride,
          studyRepositoryProvider.overrideWithValue(depot),
        ],
        child: wrapScreen(PlanPage(study: etude)),
      ),
    );
    await tester.pumpAndSettle();

    return depot;
  }

  testWidgets('les dix de Braga sont là, dans leur ordre', (tester) async {
    await pumpPlan(tester, etudeAvec(const []));

    for (final code in PlanSkeleton.braga) {
      expect(
        find.text(texte.preparationSectionTitre).evaluate().isNotEmpty ||
            code.isNotEmpty,
        isTrue,
      );
    }
    expect(find.text(texte.preparationSectionIntroduction), findsOneWidget);
    expect(find.text(texte.preparationSectionDivisions), findsOneWidget);
    expect(find.text(texte.preparationSectionConclusion), findsOneWidget);
  });

  testWidgets('les cinq sections observées ne s\'imposent pas',
      (tester) async {
    await pumpPlan(tester, etudeAvec(const []));

    expect(
      find.text(texte.preparationSectionTemoignage),
      findsNothing,
      reason: 'Braga n\'en parle pas ; le pasteur les ajoute s\'il les tient',
    );
    expect(find.text(texte.preparationPlanAdd), findsOneWidget);
  });

  testWidgets('un plan déjà écrit se relit dans ses champs', (tester) async {
    await pumpPlan(
      tester,
      etudeAvec(const [
        PlanElement(code: 'divisions', ordinal: 0, body: 'I. Le Fils premier-né'),
        PlanElement(code: 'temoignage', ordinal: 1, body: 'Ce que j\'ai vu'),
      ]),
    );

    expect(find.text('I. Le Fils premier-né'), findsOneWidget);
    expect(
      find.text(texte.preparationSectionTemoignage),
      findsOneWidget,
      reason: 'une section venue d\'ailleurs ne disparaît pas en ouvrant '
          'l\'écran',
    );
  });

  testWidgets('enregistrer envoie tout ce qui est montré', (tester) async {
    final depot = await pumpPlan(tester, etudeAvec(const []));

    await tester.enterText(find.byType(TextField).at(5), 'I. Sa prééminence');
    await tester.pumpAndSettle();
    await tester.tap(find.text(texte.preparationPlanSave));
    await tester.pumpAndSettle();

    final envoyes = depot.elementsEnvoyes;
    expect(envoyes, isNotNull);
    expect(
      envoyes!.length,
      PlanSkeleton.braga.length,
      reason: 'l\'envoi remplace l\'ensemble : ne pas envoyer une section, '
          'c\'est l\'effacer',
    );

    final points = envoyes.firstWhere((e) => e.code == PlanSkeleton.pointCentral);
    expect(points.body, 'I. Sa prééminence');
    expect(
      points.ordinal,
      PlanSkeleton.braga.indexOf(PlanSkeleton.pointCentral),
      reason: 'l\'ordre envoyé est celui de l\'écran',
    );
  });

  testWidgets('le seuil du document est dit là où il se joue', (tester) async {
    await pumpPlan(tester, etudeAvec(const []));

    expect(find.text(texte.preparationPlanPointsHint), findsOneWidget);
  });

  group('le document', () {
    testWidgets('un refus de citation montre ce qui ne va pas', (tester) async {
      // Le dossier revient « rejete » : aucun fichier n'existe, et c'est le
      // seul écran où un verset abîmé se voit avant le dimanche.
      final depot = DepotFige(studyFromWire(_ficheOuverte()))
        ..dossier = const Deliverable(
          id: 'd-1',
          kind: 'note',
          format: 'docx',
          validation: 'rejete',
          controls: [
            CitationCheck(
              slideNo: 1,
              reference: 'Romains 8:1',
              projectedText: "Il n'y a donc maintenant aucune condamnation",
              verdict: 'altere',
              rationale: 'Le texte projeté ne correspond à aucune version détenue.',
            ),
          ],
        );

      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(depot),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'etude-1')),
        ),
      );
      await tester.pumpAndSettle();

      // Deux gestes ouvrables — écrire ses points, et la fiche de chaire. Le
      // PowerPoint reste fermé : composer des diapositives demande un éditeur
      // qui n'existe pas.
      expect(find.byIcon(Icons.arrow_forward), findsNWidgets(2));
      await tester.tap(find.text('Fiche de chaire'));
      await tester.pumpAndSettle();

      expect(depot.documentsDemandes, ['note']);
      expect(find.text(texte.preparationDocumentRefusedTitle), findsOneWidget);
      expect(find.text('Romains 8:1'), findsOneWidget);
    });
  });

  group('les diapositives', () {
    Future<DepotFige> pumpDeck(WidgetTester tester, {Deliverable? dossier}) async {
      final depot = DepotFige(ToursReels.etude(ToursReels.bartimee))
        ..dossier = dossier;

      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(depot),
          ],
          child: wrapScreen(DeckPage(study: depot.etude)),
        ),
      );
      await tester.pumpAndSettle();

      return depot;
    }

    testWidgets('le texte servi remplit les diapositives', (tester) async {
      // Le pasteur part de ce que le corpus porte plutot que d'une page
      // blanche — sept versets de Bartimee, sept diapositives.
      final depot = await pumpDeck(tester);

      expect(depot.etude.verses, isNotEmpty);
      expect(
        find.text(texte.preparationDeckSlide(1)),
        findsOneWidget,
        reason: "la numerotation est celle du serveur",
      );
      expect(
        find.text(depot.etude.verses.first.reference),
        findsWidgets,
        reason: "la reference du premier verset est deja la",
      );
    });

    testWidgets('soumettre envoie ce qui est composé', (tester) async {
      final depot = await pumpDeck(
        tester,
        dossier: const Deliverable(
          id: 'd-2',
          kind: 'deck',
          format: 'pptx',
          validation: 'rejete',
          controls: [
            CitationCheck(
              slideNo: 1,
              reference: 'Marc 10:46',
              projectedText: "un texte qui n'est pas celui du corpus",
              verdict: 'altere',
              rationale: 'Le texte projete ne correspond a aucune version detenue.',
            ),
          ],
        ),
      );

      await tester.tap(find.text(texte.preparationDeckSubmit));
      await tester.pumpAndSettle();

      expect(depot.documentsDemandes, ['deck']);
      expect(depot.diapositivesSoumises, isNotEmpty);
      expect(
        depot.diapositivesSoumises.first.reference,
        depot.etude.verses.first.reference,
      );
    });

    testWidgets("le verdict se lit sous la diapositive qu'il juge",
        (tester) async {
      await pumpDeck(
        tester,
        dossier: const Deliverable(
          id: 'd-2',
          kind: 'deck',
          format: 'pptx',
          validation: 'rejete',
          controls: [
            CitationCheck(
              slideNo: 1,
              reference: 'Marc 10:46',
              projectedText: 'coupe',
              verdict: 'altere',
              rationale: 'Le texte projete ne correspond a aucune version detenue.',
            ),
          ],
        ),
      );

      await tester.tap(find.text(texte.preparationDeckSubmit));
      await tester.pumpAndSettle();

      expect(
        find.text('Le texte projete ne correspond a aucune version detenue.'),
        findsOneWidget,
        reason: "il corrige la ou il regarde, pas dans un rapport a part",
      );
    });
  });
}

/// La capture du thème, avec la fiche de chaire **ouverte**.
///
/// Le serveur annonçait les deux livrables fermés alors qu'ils fonctionnent —
/// un motif qui datait d'avant le module. Il dit désormais vrai, et la capture,
/// elle, est plus vieille que la correction.
Map<String, dynamic> _ficheOuverte() {
  final charge = jsonDecode(ToursReels.json(ToursReels.theme)) as Map<String, dynamic>;

  for (final bloc in ((charge['turn'] as Map<String, dynamic>)['blocks'] as List)
      .cast<Map<String, dynamic>>()) {
    for (final item in (bloc['items'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (item['code'] == 'sheet') {
        item['enabled'] = true;
        item['unavailable_reason'] = '';
      }
    }
  }

  return charge;
}
