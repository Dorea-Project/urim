import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/auth_local_data_source.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/usecases/auth/define_secret_code.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/auth/secret_code_view_model.dart';

/// Le tirage ensemencé rend le code SMS prévisible : la source de
/// développement consomme ses cinq premiers tirages pour le composer.
const int seed = 42;

String expectedCode() {
  final random = Random(seed);
  return List.generate(
    OtpChallenge.defaultCodeLength,
    (_) => random.nextInt(10),
  ).join();
}

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();

  return ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      authDataSourceProvider.overrideWith(
        (ref) => DevAuthDataSource(preferences, random: Random(seed)),
      ),
    ],
  );
}

void main() {
  group('parcours de connexion', () {
    test('le bon code ouvre la session', () async {
      final container = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      viewModel
        ..setNationalNumber('0747769069')
        ..setPrivacyAccepted(true);

      expect(await viewModel.requestCode(), isTrue);
      expect(await viewModel.verifyCode(expectedCode()), isTrue);

      final session = await container.read(authSessionProvider.future);
      expect(session, isNotNull);
    });

    test('un code erroné laisse la session fermée', () async {
      final container = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      viewModel
        ..setNationalNumber('0747769069')
        ..setPrivacyAccepted(true);
      await viewModel.requestCode();

      final wrong = expectedCode().split('').reversed.join();
      // Un code palindrome invaliderait le test : on décale un chiffre.
      final surelyWrong = wrong == expectedCode() ? '00000' : wrong;

      expect(await viewModel.verifyCode(surelyWrong), isFalse);
      expect(container.read(authFlowViewModelProvider).failure, isNotNull);
    });

    test('sans consentement, aucun SMS n\'est demandé', () async {
      final container = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      viewModel.setNationalNumber('0747769069');

      expect(await viewModel.requestCode(), isFalse);
      expect(
        container.read(authFlowViewModelProvider).failure,
        isA<ValidationFailure>(),
      );
    });

    test('un numéro incomplet est refusé avant tout appel', () async {
      final container = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      viewModel
        ..setNationalNumber('0747')
        ..setPrivacyAccepted(true);

      expect(await viewModel.requestCode(), isFalse);
      expect(container.read(authFlowViewModelProvider).challenge, isNull);
    });
  });

  group('code secret', () {
    test('un code trop simple est refusé', () async {
      final container = await makeContainer();

      final result = await container.read(defineSecretCodeProvider)(
        const DefineSecretCodeParams(code: '1234', confirmation: '1234'),
      );

      expect(result, isA<Failed<void>>());
      expect((result as Failed<void>).failure.code, 'trivial_code');
    });

    test('deux saisies divergentes sont refusées', () async {
      final container = await makeContainer();

      final result = await container.read(defineSecretCodeProvider)(
        const DefineSecretCodeParams(code: '2749', confirmation: '2748'),
      );

      expect((result as Failed<void>).failure.code, 'confirmation_mismatch');
    });

    test('un code défini se vérifie, un autre est rejeté', () async {
      final container = await makeContainer();

      await container.read(defineSecretCodeProvider)(
        const DefineSecretCodeParams(code: '2749', confirmation: '2749'),
      );

      expect(
        (await container.read(verifySecretCodeProvider)('2749')).valueOrNull,
        isTrue,
      );
      expect(
        (await container.read(verifySecretCodeProvider)('2750')).valueOrNull,
        isFalse,
      );
    });

    test('le code n\'est jamais stocké en clair', () async {
      final container = await makeContainer();

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

  group('porte d\'entrée', () {
    test('sans session, la porte est fermée', () async {
      final container = await makeContainer();
      expect(await container.read(authGateProvider.future), AuthGate.signedOut);
    });

    test('session ouverte sans code secret : il faut en créer un', () async {
      final container = await makeContainer();
      final viewModel = container.read(authFlowViewModelProvider.notifier);

      viewModel
        ..setNationalNumber('0747769069')
        ..setPrivacyAccepted(true);
      await viewModel.requestCode();
      await viewModel.verifyCode(expectedCode());

      expect(
        await container.read(authGateProvider.future),
        AuthGate.needsSecretCode,
      );
    });
  });
}
