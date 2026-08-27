import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/articulation.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/preparation/plan_page.dart';

import '../support/pump_app.dart';
import '../support/tours_reels.dart';

final texte = AppTextFr();

/// **La seule prose qu'Urim produise, et elle se demande.**
///
/// Ce fichier ne garde pas une fonctionnalité, il garde une frontière. Le
/// produit tient parce que le document n'imprime que ce que le pasteur a
/// écrit ; une proposition qui entrerait seule dans un champ franchirait cette
/// frontière sans qu'aucune ligne de code n'ait l'air fautive.
///
/// Quatre propriétés, et chacune est un interdit :
///
/// - on n'articule pas un point vide — **ce serait l'écrire** ;
/// - on enregistre **avant** de demander, sinon la proposition porte sur une
///   phrase déjà remplacée ;
/// - fermer la feuille ne touche à rien ;
/// - `disponible: false` **n'est pas une erreur**.
void main() {
  /// Le rang du point central dans le squelette affiché — c'est celui que
  /// l'écran envoie, et donc celui que le serveur doit recevoir.
  final rangDesPoints = PlanSkeleton.braga.indexOf(PlanSkeleton.pointCentral);

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

  Future<DepotFige> pumpPlan(WidgetTester tester, {Articulation? rendue}) async {
    final depot = DepotFige(etudeAvec(const []))..articulationRendue = rendue;

    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoConfigOverride,
          studyRepositoryProvider.overrideWithValue(depot),
        ],
        child: wrapScreen(PlanPage(study: depot.etude)),
      ),
    );
    await tester.pumpAndSettle();

    return depot;
  }

  /// Demander l'articulation du point central.
  Future<void> demander(WidgetTester tester) async {
    await tester.tap(
      find
          .widgetWithText(TextButton, texte.preparationPlanArticulate)
          .at(rangDesPoints),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('un point vide ne part pas au serveur', (tester) async {
    final depot = await pumpPlan(tester);

    await demander(tester);

    expect(
      depot.articulationsDemandees,
      isEmpty,
      reason: 'on n\'articule pas un point qui n\'existe pas : ce serait '
          'l\'écrire',
    );
    expect(depot.elementsEnvoyes, isNull);
    expect(find.text(texte.preparationPlanArticulateEmpty), findsOneWidget);
  });

  testWidgets('le plan part avant la demande, et le rang est celui de l\'écran',
      (tester) async {
    final depot = await pumpPlan(
      tester,
      rendue: const Articulation(
        body: 'La prééminence n\'est pas un rang, c\'est une place tenue.',
        transition: 'Et cette place, il ne la partage pas.',
        model: 'mistral-small',
        available: true,
      ),
    );

    await tester.enterText(
      find.byType(TextField).at(rangDesPoints),
      'I. Sa prééminence',
    );
    await tester.pumpAndSettle();
    await demander(tester);

    // ⚠️ Le serveur articule le point **tel qu'il l'a en base**. Sans cet
    // envoi, la proposition porterait sur une phrase que le pasteur vient de
    // remplacer — et rien à l'écran ne le dirait.
    final envoyes = depot.elementsEnvoyes;
    expect(envoyes, isNotNull, reason: 'on enregistre avant de demander');
    expect(
      envoyes!.firstWhere((e) => e.code == PlanSkeleton.pointCentral).body,
      'I. Sa prééminence',
    );
    expect(
      depot.articulationsDemandees,
      [(PlanSkeleton.pointCentral, rangDesPoints)],
      reason: 'le rang demandé est celui que l\'envoi vient d\'écrire',
    );
  });

  testWidgets('la proposition se lit, sans signature de modèle', (tester) async {
    await pumpPlan(
      tester,
      rendue: const Articulation(
        body: 'La prééminence n\'est pas un rang, c\'est une place tenue.',
        transition: 'Et cette place, il ne la partage pas.',
        model: 'mistral-small',
        available: true,
      ),
    );

    await tester.enterText(
      find.byType(TextField).at(rangDesPoints),
      'I. Sa prééminence',
    );
    await tester.pumpAndSettle();
    await demander(tester);

    expect(find.text(texte.preparationPlanArticulateTitle), findsOneWidget);
    expect(
      find.text('La prééminence n\'est pas un rang, c\'est une place tenue.'),
      findsOneWidget,
    );
    expect(
      find.text(texte.preparationPlanArticulateNotice),
      findsOneWidget,
      reason: "ce qui reste vrai quoi qu'il arrive : la proposition vit à "
          "côté du plan tant qu'il ne l'a pas reprise",
    );
    expect(
      find.textContaining('mistral'),
      findsNothing,
      reason: 'la signature du modèle est gardée en base, pas montrée (22/08)',
    );
  });

  testWidgets('fermer la feuille ne touche pas au point', (tester) async {
    await pumpPlan(
      tester,
      rendue: const Articulation(
        body: 'Ce que le modèle propose.',
        transition: '',
        model: 'mistral-small',
        available: true,
      ),
    );

    await tester.enterText(
      find.byType(TextField).at(rangDesPoints),
      'I. Sa prééminence',
    );
    await tester.pumpAndSettle();
    await demander(tester);

    await tester.tap(find.text(texte.preparationPlanArticulateClose));
    await tester.pumpAndSettle();

    expect(find.text('I. Sa prééminence'), findsOneWidget);
    expect(
      find.text('Ce que le modèle propose.'),
      findsNothing,
      reason: 'la proposition ne s\'écrit jamais toute seule',
    );
  });

  testWidgets('reprendre l\'ajoute à la suite, jamais à la place',
      (tester) async {
    await pumpPlan(
      tester,
      rendue: const Articulation(
        body: 'Ce que le modèle propose.',
        transition: 'Et la suite.',
        model: 'mistral-small',
        available: true,
      ),
    );

    await tester.enterText(
      find.byType(TextField).at(rangDesPoints),
      'I. Sa prééminence',
    );
    await tester.pumpAndSettle();
    await demander(tester);

    await tester.tap(find.text(texte.preparationPlanArticulateTake));
    await tester.pumpAndSettle();

    final champ = tester.widget<TextField>(
      find.byType(TextField).at(rangDesPoints),
    );

    expect(
      champ.controller!.text,
      'I. Sa prééminence\n\nCe que le modèle propose.\n\nEt la suite.',
      reason: 'ce que le pasteur a écrit reste devant',
    );
  });

  testWidgets('sans modèle, ce n\'est pas une erreur', (tester) async {
    // Le mannequin, le plafond, l'absence de clé : trois états de production,
    // et aucun n'est une panne. Le point reste écrit.
    await pumpPlan(tester, rendue: const Articulation.indisponible());

    await tester.enterText(
      find.byType(TextField).at(rangDesPoints),
      'I. Sa prééminence',
    );
    await tester.pumpAndSettle();
    await demander(tester);

    expect(
      find.text(texte.preparationPlanArticulateUnavailable),
      findsOneWidget,
    );
    expect(find.text(texte.preparationPlanArticulateTitle), findsNothing);
    expect(find.text('I. Sa prééminence'), findsOneWidget);
  });
}
