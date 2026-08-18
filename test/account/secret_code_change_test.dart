import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';

import '../support/pump_app.dart';

class _FakeAuthRepository extends Mock implements AuthRepository {}

/// Changer son code secret depuis le profil.
///
/// Le serveur a **sa propre route** pour ça (`/account/change-password`),
/// authentifiée par le jeton : ni numéro à donner, ni appareil révoqué, ni
/// session rouverte. Emprunter « code oublié » aurait déconnecté la tablette
/// du pasteur pour un simple changement de code.
void main() {
  const phone = PhoneNumber(dialCode: '+225', nationalNumber: '0700000000');

  final session = AuthSession(
    userId: 'utilisateur-1',
    phone: phone,
    openedAt: DateTime(2026, 8, 15, 10),
  );

  late _FakeAuthRepository repository;

  setUpAll(() => registerFallbackValue(phone));

  setUp(() {
    repository = _FakeAuthRepository();
    when(() => repository.requestSecretCodeChange())
        .thenAnswer((_) async => const Result.success(null));
    when(
      () => repository.confirmSecretCodeChange(
        otp: any(named: 'otp'),
        newSecretCode: any(named: 'newSecretCode'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => repository.requestSecretCodeReset(any()))
        .thenAnswer((_) async => const Result.success(null));
    when(
      () => repository.confirmSecretCodeReset(
        phone: any(named: 'phone'),
        otp: any(named: 'otp'),
        newSecretCode: any(named: 'newSecretCode'),
      ),
    ).thenAnswer((_) async => Result.success(session));
  });

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    return ProviderContainer.test(
      overrides: [
        demoConfigOverride,
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  group('lancer le changement', () {
    test("la route dédiée est appelée, pas celle de l'oubli", () async {
      final container = await makeContainer();

      final sent = await container
          .read(authFlowViewModelProvider.notifier)
          .startSecretCodeChange(phone);

      expect(sent, isTrue);
      verify(() => repository.requestSecretCodeChange()).called(1);
      verifyNever(
        () => repository.requestSecretCodeReset(any()),
      );
    });

    test("le numéro reste connu de l'écran", () async {
      final container = await makeContainer();

      await container
          .read(authFlowViewModelProvider.notifier)
          .startSecretCodeChange(phone);

      expect(
        container.read(authFlowViewModelProvider).phone,
        phone,
        reason: "l'écran affiche où part le code ; le serveur, lui, le lit "
            'dans le jeton',
      );
    });

    test('la porte du changement s\'ouvre', () async {
      final container = await makeContainer();

      await container
          .read(authFlowViewModelProvider.notifier)
          .startSecretCodeChange(phone);

      expect(
        container.read(authFlowViewModelProvider).door,
        AuthDoor.secretCodeChange,
        reason: 'c\'est elle qui autorise la redirection à laisser passer les '
            'deux écrans du parcours',
      );
    });

    test('un envoi refusé n\'ouvre rien', () async {
      when(() => repository.requestSecretCodeChange()).thenAnswer(
        (_) async => const Result.failed(
          NetworkFailure(message: 'Serveur injoignable.'),
        ),
      );

      final container = await makeContainer();

      final sent = await container
          .read(authFlowViewModelProvider.notifier)
          .startSecretCodeChange(phone);

      expect(sent, isFalse);
      expect(
        container.read(authFlowViewModelProvider).door,
        isNot(AuthDoor.secretCodeChange),
        reason: "laisser la porte ouverte après un refus autoriserait les "
            "écrans d'entrée sans qu'aucun code ne soit parti",
      );
    });
  });

  group('poser le nouveau code', () {
    test('le serveur est toujours appelé, session ouverte ou non', () async {
      final container = await makeContainer();
      final flow = container.read(authFlowViewModelProvider.notifier);

      await flow.startSecretCodeChange(phone);
      await flow.confirmSecretCodeChange('2749');

      verify(
        () => repository.confirmSecretCodeChange(
          otp: any(named: 'otp'),
          newSecretCode: '2749',
        ),
      ).called(1);
    });

    test("aucun appareil n'est révoqué au passage", () async {
      final container = await makeContainer();
      final flow = container.read(authFlowViewModelProvider.notifier);

      await flow.startSecretCodeChange(phone);
      await flow.confirmSecretCodeChange('2749');

      verifyNever(
        () => repository.confirmSecretCodeReset(
          phone: any(named: 'phone'),
          otp: any(named: 'otp'),
          newSecretCode: any(named: 'newSecretCode'),
        ),
      );
    });

    test('la porte se referme derrière soi', () async {
      final container = await makeContainer();
      final flow = container.read(authFlowViewModelProvider.notifier);

      await flow.startSecretCodeChange(phone);
      await flow.confirmSecretCodeChange('2749');

      expect(
        container.read(authFlowViewModelProvider).door,
        isNot(AuthDoor.secretCodeChange),
        reason: 'sinon la redirection continuerait d\'autoriser les écrans '
            'd\'entrée, et l\'utilisateur resterait bloqué dessus',
      );
    });
  });

  group('routes du changement', () {
    test('les deux écrans concernés sont nommés', () {
      expect(AppRoutes.secretCodeChangePaths, {
        AppRoutes.otpPath,
        AppRoutes.secretCodeSetupPath,
      });
    });

    test('ils appartiennent aussi au parcours d\'entrée', () {
      for (final path in AppRoutes.secretCodeChangePaths) {
        expect(
          AppRoutes.entryPaths.contains(path),
          isTrue,
          reason: 'ce sont les mêmes écrans : seule la porte empruntée dit '
              'laquelle des deux situations on vit',
        );
      }
    });
  });
}
