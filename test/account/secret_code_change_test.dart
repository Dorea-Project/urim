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
/// Le serveur ne connaît qu'un chemin pour reposer une serrure, et il passe
/// par un SMS : c'est le même que « code oublié ». Ce qui change, c'est qu'une
/// session est déjà ouverte — et c'est précisément là que le piège était.
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
    test('le numéro du profil sert au SMS', () async {
      final container = await makeContainer();

      final sent = await container
          .read(authFlowViewModelProvider.notifier)
          .startSecretCodeChange(phone);

      expect(sent, isTrue);
      verify(() => repository.requestSecretCodeReset(phone)).called(1);
    });

    test('la porte du changement s\'ouvre', () async {
      final container = await makeContainer();

      await container
          .read(authFlowViewModelProvider.notifier)
          .startSecretCodeChange(phone);

      expect(
        container.read(authFlowViewModelProvider).door,
        AuthDoor.secretCodeReset,
        reason: 'c\'est elle qui autorise la redirection à laisser passer les '
            'deux écrans du parcours',
      );
    });

    test('un envoi refusé n\'ouvre rien', () async {
      when(() => repository.requestSecretCodeReset(any())).thenAnswer(
        (_) async => const Result.failed(
          NetworkFailure(message: 'Serveur injoignable.'),
        ),
      );

      final container = await makeContainer();

      final sent = await container
          .read(authFlowViewModelProvider.notifier)
          .startSecretCodeChange(phone);

      expect(sent, isFalse);
    });
  });

  group('poser le nouveau code', () {
    test('le serveur est toujours appelé, session ouverte ou non', () async {
      final container = await makeContainer();
      final flow = container.read(authFlowViewModelProvider.notifier);

      await flow.startSecretCodeChange(phone);
      await flow.confirmSecretCodeReset('2749');

      verify(
        () => repository.confirmSecretCodeReset(
          phone: phone,
          otp: any(named: 'otp'),
          newSecretCode: '2749',
        ),
      ).called(1);
    });

    test('la porte se referme derrière soi', () async {
      final container = await makeContainer();
      final flow = container.read(authFlowViewModelProvider.notifier);

      await flow.startSecretCodeChange(phone);
      await flow.confirmSecretCodeReset('2749');

      expect(
        container.read(authFlowViewModelProvider).door,
        isNot(AuthDoor.secretCodeReset),
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
