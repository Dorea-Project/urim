import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import 'package:urim/presentation/preparation/widgets/study_material.dart';
import '../support/pump_app.dart';
import '../support/tours_reels.dart';

/// Ce que la preparation porte, et que personne ne montrait.
///
/// Le fil parle de l'unite, la pese, propose des plans — et n'affichait jamais
/// les versets. Le pasteur travaillait sur un passage qu'il ne voyait nulle
/// part. Et le contexte litteraire est calcule a l'ouverture, ecrit dans la
/// trace, stocke : un pasteur l'a demande alors que la reponse etait **deja
/// dans sa preparation**.

final texte = AppTextFr();
const _telephone = Size(390, 844);

/// La matiere vit **dans le menu** depuis le 22/08.
///
/// Elle se recollait sous le dernier tour, donc elle se rappelait a la fin de
/// **chaque** echange — deux replis fermes qui closaient la conversation au
/// lieu de la servir. Elle reste a un geste ; elle ne s'impose plus.
Future<void> ouvrirLaMatiere(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texte.preparationMaterialTitle));
  await tester.pumpAndSettle();
}

Future<void> pumpEtude(WidgetTester tester, Study etude) async {
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

void main() {
  group('ce que la charge porte', () {
    test('une preparation bornee porte son texte', () {
      // Sept versets sur Marc 10:46-52. Ils etaient dans la charge depuis le
      // premier jour, et aucun bloc du tour ne les portait.
      final etude = ToursReels.etude(ToursReels.bartimee);

      expect(etude.verses, hasLength(7));
      expect(etude.verses.first.reference, startsWith('Marc 10:46'));
      expect(etude.verses.last.text, contains('foi'));
    });

    test('le contexte est la, quand le corpus l\'a', () {
      final etude = ToursReels.etude(ToursReels.bartimee);

      expect(etude.context, hasLength(1));
      expect(etude.context.single.kind, 'litteraire');
      expect(etude.context.single.body, contains('10:35-45'));
    });

    test('toutes les unites n\'ont pas de contexte, et on ne l\'invente pas',
        () {
      // Le corpus n'a pas de note sur chaque unite. Une section vide
      // promettrait ce qu'elle n'a pas.
      expect(ToursReels.etude(ToursReels.theme).context, isEmpty);
    });
  });

  group("l'ecran l'offre", () {
    testWidgets("la matiere ne ferme plus les echanges", (tester) async {
      // 🔴 Le defaut du 22/08, trouve sur telephone : « pas besoin de le
      // mentionner a la fin des echanges ». Le fil se termine sur le tour.
      await pumpEtude(tester, ToursReels.etude(ToursReels.bartimee));

      expect(find.byType(StudyMaterial), findsNothing);
      expect(find.text(texte.studyText(7)), findsNothing);
    });

    testWidgets("le texte et le contexte s'ouvrent depuis le menu",
        (tester) async {
      await pumpEtude(tester, ToursReels.etude(ToursReels.bartimee));
      await ouvrirLaMatiere(tester);

      expect(find.byType(StudyMaterial), findsOneWidget);
      expect(find.text(texte.studyText(7)), findsOneWidget);
      expect(find.text(texte.studyContext(1)), findsOneWidget);
    });

    testWidgets("replie par defaut : on ouvre ce qu'on veut lire",
        (tester) async {
      await pumpEtude(tester, ToursReels.etude(ToursReels.bartimee));
      await ouvrirLaMatiere(tester);

      // Nomme, pas deplie — sinon on remplacerait un defilement par un autre.
      expect(find.textContaining("Ils arrivèrent à Jéricho"), findsNothing);
      expect(find.textContaining("10:35-45"), findsNothing);
    });

    testWidgets("le contexte s'ouvre — et c'etait la reponse a la question",
        (tester) async {
      // « Est-ce que je peux avoir le contexte historique du livre de Marc ? »
      // La reponse etait deja dans la preparation, et personne ne la montrait.
      await pumpEtude(tester, ToursReels.etude(ToursReels.bartimee));
      await ouvrirLaMatiere(tester);

      await tester.tap(find.text(texte.studyContext(1)));
      await tester.pumpAndSettle();

      expect(find.textContaining("10:35-45"), findsOneWidget);
      expect(find.text(texte.studyContextLiterary), findsOneWidget);
    });

    testWidgets("le texte s'ouvre, verset par verset", (tester) async {
      await pumpEtude(tester, ToursReels.etude(ToursReels.bartimee));
      await ouvrirLaMatiere(tester);

      await tester.tap(find.text(texte.studyText(7)));
      await tester.pumpAndSettle();

      expect(find.textContaining("Jéricho"), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets("rien a offrir : le menu ne le propose pas", (tester) async {
      // Un tour d'ouverture : aucune unite bornee, donc aucun verset. Une
      // entree de menu qui ouvrirait le vide serait pire que pas d'entree.
      final etude = ToursReels.etude(ToursReels.ouverture);
      expect(etude.verses, isEmpty);

      await pumpEtude(tester, etude);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text(texte.preparationMaterialTitle), findsNothing);
    });
  });
}
