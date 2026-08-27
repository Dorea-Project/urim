import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/auth/phone_page.dart';

import '../support/pump_app.dart';

final texte = AppTextFr();

/// **Le mur du deuxième lancement**, trouvé sur un vrai téléphone.
///
/// 🔴 `setDoor` n'était appelé que par la présentation animée, et la
/// présentation ne revient jamais. Au relancement suivant, la redirection
/// menait à l'écran du numéro avec la porte à sa valeur par défaut —
/// l'inscription. Tout pasteur revenant le lendemain tapait son numéro,
/// recevait un SMS, posait un code, et s'entendait dire « ce numéro est déjà
/// inscrit ». Sans aucune sortie.
///
/// Aucun test d'écran ne pouvait le voir : ils n'ont pas de deuxième
/// lancement. C'est une séance de dix minutes sur un appareil qui l'a montré.
void main() {
  Future<void> pumpPhone(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoConfigOverride,
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: wrapScreen(const PhonePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("l'écran du numéro offre l'autre porte", (tester) async {
    await pumpPhone(tester);

    // La porte par défaut est l'inscription : c'est celle sur laquelle un
    // relancement retombe.
    expect(find.text(texte.authPhoneTitleRegistration), findsOneWidget);
    expect(find.text(texte.authSwitchToSignIn), findsOneWidget);
  });

  testWidgets('la bascule mène vraiment à la connexion', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.text(texte.authSwitchToSignIn));
    await tester.pumpAndSettle();

    expect(find.text(texte.authPhoneTitleSignIn), findsOneWidget);
    expect(
      find.text(texte.authSwitchToRegistration),
      findsOneWidget,
      reason: 'la bascule marche dans les deux sens : celui qui se trompe de '
          'porte doit pouvoir revenir',
    );
  });

  testWidgets('le consentement ne se redemande pas à la connexion',
      (tester) async {
    await pumpPhone(tester);
    // La case, et non le texte : le lien de la politique vit dans un `TextSpan`
    // que `find.text` ne voit pas, et le bandeau de démonstration parle lui
    // aussi de « la politique » aux deux portes.
    final consentement = find.byType(Checkbox);

    expect(consentement, findsWidgets);

    await tester.tap(find.text(texte.authSwitchToSignIn));
    await tester.pumpAndSettle();

    expect(
      consentement,
      findsNothing,
      reason: "celui qui se reconnecte l'a donné le jour de son inscription",
    );
  });
}
