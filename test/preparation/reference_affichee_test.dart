import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';

import 'package:urim/l10n/generated/app_text_fr.dart';

import '../support/pump_app.dart';
import '../support/tours_reels.dart';

/// **Un texte proposé sans sa référence ne se choisit pas.**
///
/// Trouvé en jouant une préparation : l'écran offrait dix-huit unités du canon
/// sous leur seul intitulé curé — « Adresse et action de grâces initiale », qui
/// convient à quatre épîtres — et le pasteur a choisi sans savoir où il allait.
/// Le serveur mettait l'identifiant de l'unité dans le champ `reference`, et le
/// client ne rendait pas ce champ.
final texte = AppTextFr();

void main() {
  /// La capture réelle, avec la référence que le serveur pose désormais sur
  /// chaque option qui désigne un passage. Le reste de la charge ne bouge pas :
  /// le test passe par le vrai chemin d'analyse.
  Map<String, dynamic> avecReferences(String nom, String reference) {
    final charge = jsonDecode(ToursReels.json(nom)) as Map<String, dynamic>;
    final blocs = (charge['turn'] as Map<String, dynamic>)['blocks'] as List;

    for (final bloc in blocs.cast<Map<String, dynamic>>()) {
      for (final item in (bloc['items'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        // « Mes bornes » ne désigne aucun passage : il n'en reçoit pas.
        if (item['code'] != 'tel_quel' && item['code'] != 'en_un_seul') {
          item['reference'] = reference;
        }
      }
    }

    return charge;
  }

  Future<void> pumpEtude(
    WidgetTester tester,
    Map<String, dynamic> charge,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final depot = DepotFige(studyFromWire(charge));

    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          demoConfigOverride,
          studyRepositoryProvider.overrideWithValue(depot),
        ],
        child: wrapScreen(const PreparationPage(preparationId: 'etude-1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("l'unité proposée porte sa référence à l'écran", (tester) async {
    await pumpEtude(tester, avecReferences(ToursReels.bornes, '1 Jean 4:7-12'));

    expect(find.text('1 Jean 4:7-12'), findsWidgets);
  });

  testWidgets('ce qui ne désigne aucun passage reste nu', (tester) async {
    await pumpEtude(tester, avecReferences(ToursReels.bornes, '1 Jean 4:7-12'));

    // La capture porte quatre options : trois unités relues, et « Le tout, en
    // un seul sermon » — un choix, pas un texte. Rien à situer sous celui-là,
    // et une référence inventée serait pire que pas de référence.
    expect(find.text('1 Jean 4:7-12'), findsNWidgets(3));
    expect(find.text('Le tout, en un seul sermon'), findsOneWidget);
  });

  testWidgets("l'identifiant d'unité ne s'affiche jamais", (tester) async {
    await pumpEtude(tester, avecReferences(ToursReels.bornes, '1 Jean 4:7-12'));

    expect(find.textContaining('texte:'), findsNothing);
    expect(find.textContaining('-4000-'), findsNothing);
  });

  testWidgets("un geste que l'écran ne sait pas ouvrir se montre fermé",
      (tester) async {
    // La capture du thème porte les trois gestes de fin de fil : « Écrire mes
    // points », déclarée active par le serveur — la route existe — et les deux
    // livrables, fermés avec leur motif.
    await pumpEtude(tester, avecReferences(ToursReels.theme, 'Colossiens 1:1-14'));

    expect(
      find.byIcon(Icons.arrow_forward),
      findsNothing,
      reason: "aucun geste n'est servi par l'application : aucune flèche",
    );
    expect(find.text(texte.preparationActionAVenir), findsWidgets);
  });
}
