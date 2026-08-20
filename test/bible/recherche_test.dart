import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/bible/passage_detail.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/bible/search_page.dart';

import '../support/pump_app.dart';
import '../support/tours_reels.dart';

final texte = AppTextFr();

/// **Les deux questions qu'un pasteur a posées en séance**, et auxquelles le
/// produit n'avait aucun écran à opposer.
///
/// « En savoir plus sur ce livre » et « le sens original de *idole* » : le
/// serveur y répondait par `GET /urim/passages` et `GET /urim/lemmes`, et rien
/// ne les appelait.
void main() {
  Future<DepotFige> pumpRecherche(
    WidgetTester tester, {
    PassageDetail? passage,
    Concordance? concordance,
  }) async {
    final depot = DepotFige(ToursReels.etude(ToursReels.bartimee))
      ..passage = passage
      ..concordanceRendue = concordance;

    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoConfigOverride,
          studyRepositoryProvider.overrideWithValue(depot),
        ],
        child: wrapScreen(const SearchPage()),
      ),
    );
    await tester.pumpAndSettle();

    return depot;
  }

  testWidgets('sans rien de cherché, l\'écran le dit', (tester) async {
    await pumpRecherche(tester);

    expect(find.text(texte.searchEmpty), findsOneWidget);
  });

  testWidgets('un passage rend ce que le corpus en sait', (tester) async {
    await pumpRecherche(
      tester,
      passage: const PassageDetail(
        reference: 'Colossiens 1:15-20',
        pericopeLabel: 'Christologie : la prééminence du Christ',
        pericopeRationale: 'Le passage développe la prééminence du Christ.',
        reviewedBy: 'ia-mistral',
        verses: [
          ServedVerse(
            reference: 'Colossiens 1:15',
            text: 'Il est l’image du Dieu invisible',
          ),
        ],
        caveats: ['Le passage ne dit pas si le titre implique une adoption.'],
        bearings: [
          AxisBearing(
            axisCode: 'christologie',
            label: 'Christologie',
            strength: 'dominant',
            rationale: 'Le texte développe longuement la prééminence.',
          ),
        ],
      ),
    );

    await tester.enterText(find.byType(TextField), 'Colossiens 1:15-20');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text('Christologie : la prééminence du Christ'), findsOneWidget);
    expect(find.text('Colossiens 1:15'), findsOneWidget);
  });

  testWidgets('une unité écrite par le modèle porte son aveu', (tester) async {
    await pumpRecherche(
      tester,
      passage: const PassageDetail(
        reference: 'Colossiens 1:15-20',
        pericopeLabel: 'Christologie : la prééminence du Christ',
        reviewedBy: 'ia-mistral',
      ),
    );

    await tester.enterText(find.byType(TextField), 'Colossiens 1:15-20');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(
      find.text(texte.searchNotReviewed),
      findsOneWidget,
      reason: '139 198 énoncés du corpus sur 139 209 n\'ont aucun nom humain '
          'dessus : le taire ferait passer une production pour une relecture',
    );
  });

  testWidgets('un homme qui a signé est nommé', (tester) async {
    await pumpRecherche(
      tester,
      passage: const PassageDetail(
        reference: 'Colossiens 1:15-20',
        pericopeLabel: 'Christologie : la prééminence du Christ',
        reviewedBy: 'R. Gnanhi',
      ),
    );

    await tester.enterText(find.byType(TextField), 'Colossiens 1:15-20');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text(texte.searchReviewedBy('R. Gnanhi')), findsOneWidget);
  });

  testWidgets('un mot rend ses occurrences, et dit ce qu\'il ne sait pas',
      (tester) async {
    await pumpRecherche(
      tester,
      concordance: const Concordance(
        lemma: 'εἴδωλον',
        language: 'grc',
        total: 11,
        occurrences: [
          Occurrence(
            reference: '1 Jean 5:21',
            text: 'Petits enfants, gardez-vous des idoles.',
            surface: 'εἰδώλων',
            morphology: 'génitif pluriel neutre',
          ),
        ],
      ),
    );

    await tester.tap(find.text(texte.searchWordTab));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'εἴδωλον');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text('1 Jean 5:21'), findsNothing);
    expect(find.textContaining('1 Jean 5:21'), findsOneWidget);
    expect(find.text(texte.searchOccurrences(11)), findsOneWidget);
    expect(
      find.text(texte.searchNoGloss),
      findsOneWidget,
      reason: '80 gloses pour 14 101 lemmes : laisser croire que la '
          'concordance est le sens serait le mensonge le plus facile',
    );
  });

  testWidgets('un extrait ne se présente jamais comme un tout', (tester) async {
    await pumpRecherche(
      tester,
      concordance: const Concordance(
        lemma: 'δοῦλος',
        language: 'grc',
        total: 126,
        occurrences: [
          Occurrence(
            reference: 'Romains 1:1',
            text: 'Paul, serviteur de Jésus-Christ',
            surface: 'δοῦλος',
            morphology: 'nominatif singulier masculin',
          ),
        ],
      ),
    );

    await tester.tap(find.text(texte.searchWordTab));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'δοῦλος');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text(texte.searchOccurrences(126)), findsOneWidget);
    expect(find.text(texte.searchTruncated(1)), findsOneWidget);
  });

  testWidgets('un mot inconnu rend la phrase du serveur', (tester) async {
    await pumpRecherche(tester);

    await tester.tap(find.text(texte.searchWordTab));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'inconnu');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('ne parait dans aucun texte original'),
      findsOneWidget,
      reason: 'un refus qui dit pourquoi vaut mieux qu\'un « introuvable » sec',
    );
  });
}
