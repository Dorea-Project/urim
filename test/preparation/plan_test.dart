import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/preparation/plan_page.dart';

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
}
