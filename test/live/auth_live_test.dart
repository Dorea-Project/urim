@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/security/secure_store.dart';
import 'package:urim/core/security/token_store.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

import '../support/fake_vault.dart';

/// Essai **contre le vrai serveur**. Exclu de la suite : il sort de la machine.
///
/// ```bash
/// # 1. le SMS part : le code arrive sur WhatsApp
/// flutter test test/live --tags live --dart-define=PHONE=0747769069
///
/// # 2. on le rapporte, l'inscription s'acheve
/// flutter test test/live --tags live --dart-define=PHONE=0747769069 \
///                                    --dart-define=OTP=123456
/// ```
///
/// Ce qu'il verifie et qu'aucun test hors ligne ne peut verifier : que les noms
/// de champs passent la validation du serveur, que les jetons se lisent, et que
/// les refus arrivent dans l'enveloppe attendue.
void main() {
  const host = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  const national = String.fromEnvironment('PHONE');
  const otp = String.fromEnvironment('OTP');
  const secretCode = String.fromEnvironment('PIN', defaultValue: '2749');

  const config = AppConfig(
    flavor: Flavor.dev,
    apiBaseUrl: host,
    // Le vrai serveur, pas la source simulee : c'est tout l'objet.
    useMockAuth: false,
  );

  late ProviderContainer container;

  setUp(() async {
    // `flutter_test` remplace le client HTTP par un faux qui repond 400 a tout.
    // Sans cette ligne, aucune requete ne sortirait de la machine.
    HttpOverrides.global = null;

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(preferences),
        secretVaultProvider.overrideWithValue(FakeVault()),
      ],
    );
  });

  test('le serveur repond, et accepte notre demande de code', () async {
    expect(
      national,
      isNotEmpty,
      reason: 'passe --dart-define=PHONE=07XXXXXXXX',
    );

    final phone = PhoneNumber(dialCode: '+225', nationalNumber: national);
    final result =
        await container.read(authRepositoryProvider).requestRegistration(phone);

    // ignore: avoid_print
    print(result.isSuccess
        ? '→ demande acceptee par $host. Le code part vers ${phone.e164}.'
        : '→ REFUS : ${result.failureOrNull}');

    expect(result.isSuccess, isTrue);
  });

  test(
    'le code recu acheve l\'inscription et ouvre la session',
    () async {
      final phone = PhoneNumber(dialCode: '+225', nationalNumber: national);

      final result =
          await container.read(authRepositoryProvider).confirmRegistration(
                phone: phone,
                otp: otp,
                secretCode: secretCode,
              );

      final session = result.valueOrNull;

      // ignore: avoid_print
      print(session != null
          ? '→ session ouverte pour ${session.phone.e164}'
          : '→ REFUS : ${result.failureOrNull}');

      expect(session, isNotNull);

      // Les jetons doivent etre au coffre, et lisibles.
      final tokens = await container.read(tokenStoreProvider).read();
      expect(tokens, isNotNull);
      expect(tokens!.accessToken, isNotEmpty);
      expect(
        tokens.expiresAt.isAfter(DateTime.now()),
        isTrue,
        reason: 'expires_in doit avoir ete converti en date',
      );

      // ignore: avoid_print
      print('→ jetons au coffre, acces valide jusqu\'a ${tokens.expiresAt}');
    },
    skip: otp.isEmpty ? 'passe --dart-define=OTP=... pour cette etape' : false,
  );
}
