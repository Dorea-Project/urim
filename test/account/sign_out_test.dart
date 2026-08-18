import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/profile/profile_page.dart';
import 'package:urim/presentation/profile/sign_out_view_model.dart';

import '../support/pump_app.dart';

class _FakeAuthRepository extends Mock implements AuthRepository {}

/// Les libellés viennent de la même source que l'écran.
final texte = AppTextFr();

void main() {
  const phone = PhoneNumber(dialCode: '+225', nationalNumber: '0700000000');

  final session = AuthSession(
    userId: 'utilisateur-1',
    phone: phone,
    openedAt: DateTime(2026, 8, 15, 10),
  );

  late _FakeAuthRepository repository;

  setUp(() {
    repository = _FakeAuthRepository();
    when(() => repository.signOut(everywhere: any(named: 'everywhere')))
        .thenAnswer((_) async => const Result.success(null));
  });

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    return ProviderContainer.test(
      overrides: [
        demoConfigOverride,
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(repository),
        authSessionProvider.overrideWith((ref) async => session),
      ],
    );
  }

  group('fermer la session', () {
    test('la session locale est verrouillée', () async {
      final container = await makeContainer();
      container.read(sessionUnlockedProvider.notifier).unlock();

      await container.read(signOutViewModelProvider.notifier).signOut();

      expect(container.read(sessionUnlockedProvider), isFalse);
      verify(() => repository.signOut(everywhere: false)).called(1);
    });

    test('« sur tous mes appareils » remonte jusqu\'au dépôt', () async {
      final container = await makeContainer();

      await container
          .read(signOutViewModelProvider.notifier)
          .signOut(everywhere: true);

      verify(() => repository.signOut(everywhere: true)).called(1);
    });

    test('un refus du serveur ne retient personne', () async {
      when(() => repository.signOut(everywhere: any(named: 'everywhere')))
          .thenAnswer(
        (_) async => const Result.failed(
          NetworkFailure(message: 'Serveur injoignable.'),
        ),
      );

      final container = await makeContainer();
      container.read(sessionUnlockedProvider.notifier).unlock();

      final failure =
          await container.read(signOutViewModelProvider.notifier).signOut();

      expect(failure, isNotNull);
      expect(
        container.read(sessionUnlockedProvider),
        isFalse,
        reason: 'le dépôt efface jetons et trace même quand l\'appel échoue : '
            'refuser de déconnecter parce que le réseau manque serait absurde',
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
            authRepositoryProvider.overrideWithValue(repository),
            authSessionProvider.overrideWith((ref) async => session),
          ],
          child: wrapScreen(const ProfilePage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le profil offre de se déconnecter', (tester) async {
      await pumpProfile(tester);

      expect(find.text(texte.profileSignOut), findsOneWidget);
    });

    testWidgets('le dialogue dit ce qui n\'est pas détruit', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileSignOut));
      await tester.pumpAndSettle();

      expect(find.text(texte.profileSignOutTitle), findsOneWidget);
      expect(
        find.text(texte.profileSignOutBody),
        findsOneWidget,
        reason: 'perdre son travail est la seule inquiétude réelle au moment '
            'de toucher ce bouton',
      );
    });

    testWidgets('annuler ne ferme rien', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileSignOut));
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.cancel));
      await tester.pumpAndSettle();

      verifyNever(() => repository.signOut(everywhere: any(named: 'everywhere')));
    });

    testWidgets('confirmer ferme la session', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(texte.profileSignOut));
      await tester.pumpAndSettle();

      // La rangée et le bouton portent le même verbe : c'est naturel à
      // l'écran, et ambigu pour un sélecteur. On vise donc dans le dialogue.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(texte.profileSignOutConfirm),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repository.signOut(everywhere: false)).called(1);
    });
  });
}
