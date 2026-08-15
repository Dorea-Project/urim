import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/config/mock_credentials.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/security/device_identity.dart';
import 'package:urim/core/security/secure_store.dart';
import 'package:urim/core/security/token_store.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/session_local_data_source.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';
import 'package:urim/domain/usecases/auth/define_secret_code.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/auth/secret_code_view_model.dart';

import '../support/fake_vault.dart';

const AppConfig devConfig = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'http://localhost:8000',
  useMockAuth: true,
);

const AppConfig prodConfig = AppConfig(
  flavor: Flavor.prod,
  apiBaseUrl: 'https://api.dorea.church',
);

const PhoneNumber phone = PhoneNumber(
  dialCode: MockCredentials.dialCode,
  nationalNumber: MockCredentials.nationalNumber,
);

/// Conteneur du parcours d'entrée : préférences vierges, coffre en mémoire.
Future<(ProviderContainer, FakeVault)> makeContainer({
  AppConfig config = devConfig,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  final vault = FakeVault();

  final container = ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sharedPreferencesProvider.overrideWithValue(preferences),
      secretVaultProvider.overrideWithValue(vault),
    ],
  );

  return (container, vault);
}

/// Mène l'inscription complète : SMS demandé, code et serrure posés.
Future<Result<void>> register(
  ProviderContainer container, {
  String otp = MockCredentials.otp,
  String secretCode = MockCredentials.secretCode,
}) async {
  final repository = container.read(authRepositoryProvider);
  await repository.requestRegistration(phone);

  return repository.confirmRegistration(
    phone: phone,
    otp: otp,
    secretCode: secretCode,
  );
}

void main() {
  group('parcours de demonstration', () {
    test('le code de demonstration a la longueur attendue', () {
      expect(MockCredentials.isCoherent, isTrue);
    });

    test('sans serveur, le numero est prerempli', () async {
      final (container, _) = await makeContainer();
      final state = container.read(authFlowViewModelProvider);

      expect(state.nationalNumber, MockCredentials.nationalNumber);
      expect(state.dialCode, MockCredentials.dialCode);
      expect(
        state.privacyAccepted,
        isFalse,
        reason: 'le consentement est un geste, jamais une valeur par defaut',
      );
    });

    test('en production, rien n\'est prerempli ni simule', () async {
      final (container, _) = await makeContainer(config: prodConfig);
      final state = container.read(authFlowViewModelProvider);

      expect(state.nationalNumber, isEmpty);
      expect(prodConfig.usesMockCredentials, isFalse);
      expect(
        prodConfig.useMockAuth,
        isFalse,
        reason: 'aucune ligne de commande ne doit pouvoir simuler en prod',
      );
    });

    test('l\'adresse du serveur porte le prefixe du canal mobile', () {
      expect(prodConfig.apiRoot, 'https://api.dorea.church/api/mobile');
    });
  });

  group('inscription', () {
    test('code SMS et code secret ouvrent la session d\'un seul geste',
        () async {
      final (container, vault) = await makeContainer();

      expect((await register(container)).isSuccess, isTrue);

      final session = await container.read(authSessionProvider.future);
      expect(session, isNotNull);
      expect(session!.phone, phone);

      expect(
        vault.entries.containsKey(SecureTokenStore.storageKey),
        isTrue,
        reason: 'les jetons vont au coffre, jamais aux preferences',
      );
    });

    test('un code SMS errone laisse la session fermee', () async {
      final (container, vault) = await makeContainer();

      final result = await register(container, otp: '999999');

      expect(result.isFailure, isTrue);
      expect(await container.read(authSessionProvider.future), isNull);
      expect(
        vault.entries.containsKey(SecureTokenStore.storageKey),
        isFalse,
        reason: 'un echec n\'ecrit aucun jeton — l\'identifiant d\'appareil, '
            'lui, a bien ete cree pour l\'appel',
      );
    });

    test('un code SMS mal forme est refuse avant tout appel', () async {
      final (container, _) = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      viewModel
        ..setPrivacyAccepted(true)
        ..setOtp('12');

      expect(await viewModel.requestCode(), isTrue);
      expect(await viewModel.confirmRegistration(MockCredentials.secretCode),
          isFalse);
      expect(
        container.read(authFlowViewModelProvider).failure,
        isA<ValidationFailure>(),
      );
    });

    test('sans consentement, aucun SMS n\'est demande', () async {
      final (container, _) = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      expect(await viewModel.requestCode(), isFalse);
      expect(
        container.read(authFlowViewModelProvider).failure,
        isA<ValidationFailure>(),
      );
    });

    test('un numero incomplet est refuse avant tout appel', () async {
      final (container, _) = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      viewModel
        ..setNationalNumber('0747')
        ..setPrivacyAccepted(true);

      expect(await viewModel.requestCode(), isFalse);
      expect(container.read(authFlowViewModelProvider).hasPendingOtp, isFalse);
    });
  });

  group('connexion', () {
    test('le bon code secret rouvre la session', () async {
      final (container, _) = await makeContainer();
      await register(container);

      final result = await container.read(authRepositoryProvider).signIn(
            phone: phone,
            secretCode: MockCredentials.secretCode,
          );

      expect(result.valueOrNull, isA<SessionOpened>());
    });

    test('un code secret errone est refuse', () async {
      final (container, _) = await makeContainer();
      await register(container);

      final result = await container.read(authRepositoryProvider).signIn(
            phone: phone,
            secretCode: '9999',
          );

      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('se connecter pose la serrure locale sans la redemander', () async {
      final (container, _) = await makeContainer();
      await register(container);

      // On efface la derivation locale : c'est l'etat d'un telephone neuf, ou
      // d'une reinstallation.
      final preferences = await SharedPreferences.getInstance();
      for (final key in preferences.getKeys().toList()) {
        if (key.startsWith('secret_code')) await preferences.remove(key);
      }
      container.invalidate(hasSecretCodeProvider);

      final outcome = await container
          .read(authFlowViewModelProvider.notifier)
          .signIn(MockCredentials.secretCode);

      expect(outcome, isA<SessionOpened>());
      expect(
        await container.read(hasSecretCodeProvider.future),
        isTrue,
        reason: 'le code vient d\'etre tape et valide : le redemander serait '
            'le faire saisir deux fois de suite',
      );
    });

    test('le consentement ne conditionne que l\'inscription', () async {
      final (container, _) = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      expect(container.read(authFlowViewModelProvider).canSubmitPhone, isFalse);

      viewModel.setDoor(AuthDoor.signIn);

      expect(container.read(authFlowViewModelProvider).canSubmitPhone, isTrue);
    });
  });

  group('code secret oublie', () {
    test('la demande aboutit meme sur un numero inconnu', () async {
      final (container, _) = await makeContainer();

      final sent = await container
          .read(authFlowViewModelProvider.notifier)
          .requestSecretCodeReset();

      expect(sent, isTrue, reason: 'repondre « inconnu » ferait un annuaire');
      expect(
        container.read(authFlowViewModelProvider).door,
        AuthDoor.secretCodeReset,
      );
    });

    test('un nouveau code remplace l\'ancien', () async {
      final (container, _) = await makeContainer();
      await register(container);

      final repository = container.read(authRepositoryProvider);
      await repository.requestSecretCodeReset(phone);

      final result = await repository.confirmSecretCodeReset(
        phone: phone,
        otp: MockCredentials.otp,
        newSecretCode: '3856',
      );

      expect(result.isSuccess, isTrue);

      expect(
        (await repository.signIn(phone: phone, secretCode: '3856'))
            .valueOrNull,
        isA<SessionOpened>(),
      );
      expect(
        (await repository.signIn(
          phone: phone,
          secretCode: MockCredentials.secretCode,
        ))
            .failureOrNull,
        isNotNull,
        reason: 'l\'ancien code ne doit plus ouvrir',
      );
    });
  });

  group('session', () {
    test('des jetons absents invalident la trace locale', () async {
      final (container, vault) = await makeContainer();
      await register(container);

      // Coffre vide : c'est ce que laisse une revocation, ou un
      // rafraichissement en echec.
      vault.entries.remove(SecureTokenStore.storageKey);

      final repository = container.read(authRepositoryProvider);
      expect((await repository.currentSession()).valueOrNull, isNull);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesSessionDataSource.storageKey,
        ),
        isNull,
        reason: 'une trace sans jetons ne doit pas survivre a sa relecture',
      );
    });

    test('se deconnecter efface le coffre et la trace', () async {
      final (container, vault) = await makeContainer();
      await register(container);

      expect((await container.read(authRepositoryProvider).signOut()).isSuccess,
          isTrue);

      expect(vault.entries.containsKey(SecureTokenStore.storageKey), isFalse);
      expect(
        (await container.read(authRepositoryProvider).currentSession())
            .valueOrNull,
        isNull,
      );
    });

    test('l\'identifiant d\'appareil est cree une fois, puis relu', () async {
      final (container, vault) = await makeContainer();
      final device = container.read(deviceIdentityProvider);

      final first = await device.resolve();
      final second = await device.resolve();

      expect(first, second);
      expect(first, startsWith('urim-'));
      expect(vault.entries[DeviceIdentity.storageKey], first);
    });
  });

  group('code secret local', () {
    test('un code trop simple est refuse', () async {
      final (container, _) = await makeContainer();

      final result = await container.read(defineSecretCodeProvider)(
        const DefineSecretCodeParams(code: '1234', confirmation: '1234'),
      );

      expect(result, isA<Failed<void>>());
      expect((result as Failed<void>).failure.code, 'trivial_code');
    });

    test('deux saisies divergentes sont refusees', () async {
      final (container, _) = await makeContainer();

      final result = await container.read(defineSecretCodeProvider)(
        const DefineSecretCodeParams(code: '2749', confirmation: '2748'),
      );

      expect((result as Failed<void>).failure.code, 'confirmation_mismatch');
    });

    test('le code n\'est jamais stocke en clair', () async {
      final (container, _) = await makeContainer();

      await container.read(defineSecretCodeProvider)(
        const DefineSecretCodeParams(code: '2749', confirmation: '2749'),
      );

      final preferences = await SharedPreferences.getInstance();
      final stored = preferences
          .getKeys()
          .map((key) => preferences.get(key).toString())
          .join('|');

      expect(stored.contains('2749'), isFalse);
    });
  });

  group('porte d\'entree', () {
    test('sans session, la porte est fermee', () async {
      final (container, _) = await makeContainer();

      expect(await container.read(authGateProvider.future), AuthGate.signedOut);
    });

    test('session ouverte sans code secret local : il faut en poser un',
        () async {
      final (container, _) = await makeContainer();
      await register(container);

      expect(
        await container.read(authGateProvider.future),
        AuthGate.needsSecretCode,
      );
    });
  });
}
