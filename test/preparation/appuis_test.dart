import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/preparation/supports_page.dart';

import '../support/pump_app.dart';
import '../support/tours_reels.dart';

final texte = AppTextFr();

/// **Un sermon convoque une chaîne ; Urim n'en tenait qu'un maillon.**
///
/// Deux prédications réelles portaient huit textes, puis douze — et dans la
/// seconde, deux références inexistantes. Le contrôle savait le dire depuis le
/// premier jour ; il manquait une surface où ces textes soient soumis.
void main() {
  Study avecAppuis(List<SupportText> appuis) {
    final base = ToursReels.etude(ToursReels.bartimee);

    return Study(
      id: base.id,
      status: base.status,
      rawInput: base.rawInput,
      turn: base.turn,
      supports: appuis,
    );
  }

  Future<DepotFige> pumpAppuis(WidgetTester tester, Study etude) async {
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
        child: wrapScreen(SupportsPage(study: etude)),
      ),
    );
    await tester.pumpAndSettle();

    return depot;
  }

  testWidgets('la saisie part telle quelle, dans la notation du pasteur',
      (tester) async {
    final depot = await pumpAppuis(tester, avecAppuis(const []));

    await tester.tap(find.text(texte.preparationSupportsAdd));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Hb 2v29');
    await tester.tap(find.text(texte.preparationSupportsSave));
    await tester.pumpAndSettle();

    expect(
      depot.appuisSoumis,
      ['Hb 2v29'],
      reason: 'c\'est le serveur qui lit la notation, parce que c\'est lui qui '
          'a le corpus',
    );
  });

  testWidgets('une référence inexistante revient avec son motif',
      (tester) async {
    // 🔴 « Ph 28v9 » — l'épître aux Philippiens compte quatre chapitres. C'est
    // l'une des deux références inexistantes des notes du Pasteur X. Urim
    // savait le dire depuis le premier jour ; personne ne l'entendait.
    await pumpAppuis(
      tester,
      avecAppuis(const [
        SupportText(
          raw: 'Ph 28v9',
          verdict: 'Hébreux 2 compte 18 versets, il n\'y a pas de verset 29.',
        ),
      ]),
    );

    expect(
      find.text('Hébreux 2 compte 18 versets, il n\'y a pas de verset 29.'),
      findsOneWidget,
    );
    expect(
      find.text('Ph 28v9'),
      findsWidgets,
      reason: 'la saisie survit : la perdre obligerait le pasteur à se '
          'souvenir de ce qu\'il voulait citer',
    );
  });

  testWidgets('un texte résolu montre ce que le corpus a servi', (tester) async {
    await pumpAppuis(
      tester,
      avecAppuis(const [
        SupportText(
          raw: 'Jn14v28',
          reference: 'Jean 14:28',
          text: 'Vous avez entendu que je vous ai dit : Je m\'en vais.',
        ),
      ]),
    );

    expect(find.text('Jean 14:28'), findsOneWidget);
    expect(
      find.textContaining('Je m\'en vais'),
      findsOneWidget,
      reason: 'il vérifie qu\'il a bien convoqué ce qu\'il croyait convoquer',
    );
  });

  testWidgets('l\'ordre est le sien, pas celui du canon', (tester) async {
    final depot = await pumpAppuis(
      tester,
      avecAppuis(const [
        SupportText(raw: 'Ésaïe 53:5', reference: 'Ésaïe 53:5'),
        SupportText(raw: 'Jean 19:30', reference: 'Jean 19:30'),
      ]),
    );

    await tester.tap(find.text(texte.preparationSupportsSave));
    await tester.pumpAndSettle();

    expect(depot.appuisSoumis, ['Ésaïe 53:5', 'Jean 19:30']);
  });
}
