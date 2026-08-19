import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/profile/profile_page.dart';

import '../support/pump_app.dart';

class _FakeAuthRepository extends Mock implements AuthRepository {}

/// Changer de numéro depuis le profil.
///
/// Le serveur sert cette route depuis longtemps
/// (`/account/change-phone/{request,confirm}`) ; l'application n'en faisait
/// rien et affichait « changer de numéro suppose un nouveau code par SMS »
/// sous un champ mort.
///
/// Le code part sur le **nouveau** numéro : l'ancien a été prouvé le jour de
/// l'inscription, et le jeton atteste déjà du compte.
final texte = AppTextFr();

void main() {
  const ancien = PhoneNumber(dialCode: '+225', nationalNumber: '0700000000');
  const nouveau = PhoneNumber(dialCode: '+225', nationalNumber: '0500000099');

  final session = AuthSession(
    userId: 'utilisateur-1',
    phone: ancien,
    openedAt: DateTime(2026, 8, 15, 10),
  );

  late _FakeAuthRepository depot;

  setUpAll(() => registerFallbackValue(ancien));

  setUp(() {
    depot = _FakeAuthRepository();
    when(() => depot.requestPhoneChange(any()))
        .thenAnswer((_) async => const Result.success(null));
    when(
      () => depot.confirmPhoneChange(
        newPhone: any(named: 'newPhone'),
        otp: any(named: 'otp'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        AuthSession(
          userId: session.userId,
          phone: nouveau,
          openedAt: session.openedAt,
        ),
      ),
    );
  });

  Future<ProviderContainer> conteneur() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    return ProviderContainer.test(
      overrides: [
        demoConfigOverride,
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(depot),
        authSessionProvider.overrideWith((ref) async => session),
      ],
    );
  }

  group('demander le code', () {
    test('il part sur le nouveau numéro', () async {
      final container = await conteneur();

      final sent = await container
          .read(authFlowViewModelProvider.notifier)
          .startPhoneChange(nouveau);

      expect(sent, isTrue);
      verify(() => depot.requestPhoneChange(nouveau)).called(1);
    });

    test("la porte du changement de numéro s'ouvre", () async {
      final container = await conteneur();

      await container
          .read(authFlowViewModelProvider.notifier)
          .startPhoneChange(nouveau);

      final state = container.read(authFlowViewModelProvider);
      expect(state.door, AuthDoor.phoneChange);
      expect(
        state.phone,
        nouveau,
        reason: "l'écran du code doit afficher le numéro qui vient de recevoir "
            "le SMS, pas celui qu'on quitte",
      );
    });

    test("un envoi refusé referme la porte", () async {
      when(() => depot.requestPhoneChange(any())).thenAnswer(
        (_) async => const Result.failed(
          NetworkFailure(message: 'Serveur injoignable.'),
        ),
      );

      final container = await conteneur();

      final sent = await container
          .read(authFlowViewModelProvider.notifier)
          .startPhoneChange(nouveau);

      expect(sent, isFalse);
      expect(
        container.read(authFlowViewModelProvider).door,
        isNot(AuthDoor.phoneChange),
      );
    });
  });

  group('poser le nouveau numéro', () {
    test('le code accompagne le numéro qui vient de le recevoir', () async {
      final container = await conteneur();
      final flow = container.read(authFlowViewModelProvider.notifier);

      await flow.startPhoneChange(nouveau);
      flow.setOtp('123456');
      final done = await flow.confirmPhoneChange();

      expect(done, isTrue);
      verify(
        () => depot.confirmPhoneChange(newPhone: nouveau, otp: '123456'),
      ).called(1);
    });

    test('la porte se referme derrière soi', () async {
      final container = await conteneur();
      final flow = container.read(authFlowViewModelProvider.notifier);

      await flow.startPhoneChange(nouveau);
      flow.setOtp('123456');
      await flow.confirmPhoneChange();

      expect(
        container.read(authFlowViewModelProvider).door,
        isNot(AuthDoor.phoneChange),
      );
    });
  });

  group('écran', () {
    Future<void> pumpProfile(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoConfigOverride,
            sharedPreferencesProvider.overrideWithValue(preferences),
            authRepositoryProvider.overrideWithValue(depot),
            authSessionProvider.overrideWith((ref) async => session),
          ],
          child: wrapRouter(
            GoRouter(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const ProfilePage()),
                GoRoute(
                  path: AppRoutes.otpPath,
                  name: AppRoutes.otpName,
                  builder: (_, _) =>
                      const Scaffold(body: Text('écran du code')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le numéro du profil ouvre la boîte', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profilePhone));
      await tester.pumpAndSettle();

      expect(find.text(texte.profilePhoneChangeTitle), findsOneWidget);
      expect(find.text(texte.profilePhoneChangeBody), findsOneWidget);
    });

    testWidgets("le même numéro ne déclenche rien", (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profilePhone));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).last,
        ancien.nationalNumber,
      );
      await tester.pumpAndSettle();

      final bouton = find.widgetWithText(
        TextButton,
        texte.profilePhoneChangeConfirm,
      );
      expect(
        tester.widget<TextButton>(bouton).onPressed,
        isNull,
        reason: 'demander un SMS pour ne rien changer serait un code payé pour '
            'rien',
      );
    });

    testWidgets('un nouveau numéro fait partir le code', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profilePhone));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).last,
        nouveau.nationalNumber,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(TextButton, texte.profilePhoneChangeConfirm),
      );
      await tester.pumpAndSettle();

      verify(() => depot.requestPhoneChange(nouveau)).called(1);
      expect(find.text('écran du code'), findsOneWidget);
    });
  });
}
