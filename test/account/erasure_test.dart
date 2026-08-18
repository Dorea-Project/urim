import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/core/security/device_identity.dart';
import 'package:urim/core/security/token_store.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/repositories/local_account_erasure.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/account_erasure.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/profile/profile_page.dart';

import '../support/fake_documents.dart';
import '../support/fake_vault.dart';
import '../support/pump_app.dart';

/// Les libellés viennent de la même source que l'écran.
final texte = AppTextFr();

/// Un magasin qui refuse d'effacer — la panne du milieu de suppression.
final class _DocumentsRetifs implements LocalDocuments {
  final Map<String, String> contenu = {};

  @override
  Future<String?> read(String key) async => contenu[key];

  @override
  Future<void> write(String key, String value) async => contenu[key] = value;

  @override
  Future<void> delete(String key) async =>
      throw const FileSystemExceptionSimulee();

  @override
  Future<List<String>> keys() async => contenu.keys.toList();
}

final class FileSystemExceptionSimulee implements Exception {
  const FileSystemExceptionSimulee();

  @override
  String toString() => 'disque plein';
}

void main() {
  late FakeDocuments documents;
  late FakeVault vault;
  late TokenStore tokens;
  late SharedPreferences preferences;

  final jetons = AuthTokens(
    accessToken: 'acces',
    refreshToken: 'rafraichissement',
    expiresAt: DateTime(2026, 9),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboarding.completed': true,
      'secret.code.set': true,
    });
    preferences = await SharedPreferences.getInstance();

    documents = FakeDocuments();
    vault = FakeVault();
    tokens = SecureTokenStore(vault);
  });

  LocalAccountErasure suppression({LocalDocuments? magasin}) =>
      LocalAccountErasure(
        preferences: preferences,
        documents: magasin ?? documents,
        tokens: tokens,
      );

  test('efface les brouillons, les réglages et la session', () async {
    await documents.write('etude.brouillon.1', '{"titre":"Bartimée"}');
    await documents.write('geste.en-attente.2', '{}');
    await tokens.save(jetons);

    final result = await suppression().eraseEverything();

    expect(result, isA<Success<void>>());
    expect(await documents.keys(), isEmpty);
    expect(preferences.getKeys(), isEmpty);
    expect(await tokens.read(), isNull);
  });

  test("garde l'identité de l'appareil", () async {
    // Sans elle, le même téléphone se présenterait comme neuf à la
    // reconnexion et consommerait une seconde place sur deux (D45).
    await vault.write(DeviceIdentity.storageKey, 'urim-abc');
    await tokens.save(jetons);

    await suppression().eraseEverything();

    expect(vault.entries[DeviceIdentity.storageKey], 'urim-abc');
    expect(vault.entries.containsKey(SecureTokenStore.storageKey), isFalse);
  });

  test('supprimer deux fois ne casse rien', () async {
    await documents.write('etude.brouillon.1', '{}');

    await suppression().eraseEverything();
    final second = await suppression().eraseEverything();

    expect(second, isA<Success<void>>());
  });

  test("l'échec laisse le compte en place plutôt qu'à moitié vidé", () async {
    final retifs = _DocumentsRetifs();
    await retifs.write('etude.brouillon.1', '{}');
    await tokens.save(jetons);

    final result = await suppression(magasin: retifs).eraseEverything();

    expect(result, isA<Failed<void>>());
    // Les fichiers passent en premier : leur panne arrête tout avant que les
    // réglages et la session ne partent.
    expect(preferences.getKeys(), isNotEmpty);
    expect(await tokens.read(), isNotNull);
  });

  group('écran', () {
    late _SuppressionEspionne espionne;

    Future<void> pumpProfile(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      espionne = _SuppressionEspionne();

      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoConfigOverride,
            sharedPreferencesProvider.overrideWithValue(preferences),
            accountErasureProvider.overrideWithValue(espionne),
            authSessionProvider.overrideWith(
              (ref) async => AuthSession(
                userId: 'utilisateur-1',
                phone: const PhoneNumber(
                  dialCode: '+225',
                  nationalNumber: '0700000000',
                ),
                openedAt: DateTime(2026, 8, 15, 10),
              ),
            ),
          ],
          child: wrapScreen(const ProfilePage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le dialogue dit ce qui part et ce qui reste', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileDeleteAccount));
      await tester.pumpAndSettle();

      expect(find.text(texte.profileDeleteAccountTitle), findsOneWidget);
      expect(
        find.text(texte.profileDeleteAccountBody),
        findsOneWidget,
        reason: 'taire que le numéro reste connu du service serait une '
            'seconde promesse non tenue',
      );
    });

    testWidgets('annuler n\'efface rien', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileDeleteAccount));
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.cancel));
      await tester.pumpAndSettle();

      expect(espionne.appels, 0);
    });

    testWidgets('confirmer efface', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileDeleteAccount));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(texte.profileDeleteAccountConfirm),
        ),
      );
      await tester.pumpAndSettle();

      expect(espionne.appels, 1);
      expect(find.text(texte.profileDeleteAccountDone), findsOneWidget);
    });
  });
}

/// Compte les suppressions, sans rien effacer.
final class _SuppressionEspionne implements AccountErasure {
  int appels = 0;

  @override
  Future<Result<void>> eraseEverything() async {
    appels++;
    return const Result.success(null);
  }
}
