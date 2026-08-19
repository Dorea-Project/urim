import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/core/security/device_identity.dart';
import 'package:urim/core/security/token_store.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/data/repositories/local_account_erasure.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/profile/account_erasure_view_model.dart';
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

  group("le serveur d'abord, l'appareil ensuite", () {
    late _FakeAuthRepository depot;

    Future<ProviderContainer> conteneur() async {
      depot = _FakeAuthRepository();
      when(() => depot.requestAccountDeletion())
          .thenAnswer((_) async => const Result.success(null));
      when(() => depot.confirmAccountDeletion(otp: any(named: 'otp')))
          .thenAnswer((_) async => const Result.success(null));

      await documents.write('etude.brouillon.1', '{}');
      await tokens.save(jetons);

      return ProviderContainer.test(
        overrides: [
          demoConfigOverride,
          sharedPreferencesProvider.overrideWithValue(preferences),
          localDocumentsProvider.overrideWithValue(documents),
          tokenStoreProvider.overrideWithValue(tokens),
          authRepositoryProvider.overrideWithValue(depot),
        ],
      );
    }

    test('le code accepté efface les deux côtés', () async {
      final container = await conteneur();

      final failure = await container
          .read(accountErasureViewModelProvider.notifier)
          .erase('123456');

      expect(failure, isNull);
      verify(() => depot.confirmAccountDeletion(otp: '123456')).called(1);
      expect(await documents.keys(), isEmpty);
      expect(await tokens.read(), isNull);
    });

    test('un refus du serveur ne vide pas le téléphone', () async {
      final container = await conteneur();
      when(() => depot.confirmAccountDeletion(otp: any(named: 'otp')))
          .thenAnswer(
        (_) async => const Result.failed(
          AuthFailure(message: 'Code incorrect.'),
        ),
      );

      final failure = await container
          .read(accountErasureViewModelProvider.notifier)
          .erase('000000');

      expect(failure, isNotNull);
      expect(
        await documents.keys(),
        isNotEmpty,
        reason: 'un appareil vidé devant un compte encore vivant serait un '
            "compte que plus rien ne permet d'atteindre",
      );
      expect(await tokens.read(), isNotNull);
    });

    test('la session se referme quand tout est parti', () async {
      final container = await conteneur();
      container.read(sessionUnlockedProvider.notifier).unlock();

      await container
          .read(accountErasureViewModelProvider.notifier)
          .erase('123456');

      expect(container.read(sessionUnlockedProvider), isFalse);
      expect(
        container.read(authFlowViewModelProvider).door,
        isNot(AuthDoor.accountDeletion),
      );
    });
  });

  group('écran', () {
    late _FakeAuthRepository depot;

    Future<void> pumpProfile(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      depot = _FakeAuthRepository();
      when(() => depot.requestAccountDeletion())
          .thenAnswer((_) async => const Result.success(null));

      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoConfigOverride,
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(depot),
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
          // Un routeur minuscule : la demande de code **quitte** le profil
          // pour l'écran du SMS, et c'est ce départ qu'il faut pouvoir voir.
          child: wrapRouter(
            GoRouter(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const ProfilePage()),
                GoRoute(
                  path: AppRoutes.otpPath,
                  name: AppRoutes.otpName,
                  builder: (_, _) => const Scaffold(body: Text('écran du code')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le dialogue dit ce qui part, des deux côtés', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileDeleteAccount));
      await tester.pumpAndSettle();

      expect(find.text(texte.profileDeleteAccountTitle), findsOneWidget);
      expect(find.text(texte.profileDeleteAccountBody), findsOneWidget);
    });

    testWidgets("annuler n'envoie rien", (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileDeleteAccount));
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.cancel));
      await tester.pumpAndSettle();

      verifyNever(() => depot.requestAccountDeletion());
    });

    testWidgets('confirmer demande le code, sans rien détruire',
        (tester) async {
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

      verify(() => depot.requestAccountDeletion()).called(1);
      verifyNever(() => depot.confirmAccountDeletion(otp: any(named: 'otp')));
      expect(
        find.text('écran du code'),
        findsOneWidget,
        reason: 'la suppression se termine sur le code, pas sur le profil',
      );
    });
  });
}

class _FakeAuthRepository extends Mock implements AuthRepository {}
