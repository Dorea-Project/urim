import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/datasources/account_local_data_source.dart';
import 'package:urim/data/repositories/account_repository_impl.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/entities/account/user_profile.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/profile/profile_page.dart';
import 'package:urim/presentation/profile/profile_view_model.dart';
import 'package:urim/presentation/theme/app_theme.dart';

/// Horloge figée : « Dernière activité le 28 juillet » doit être vérifiable.
final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

void main() {
  final fixedNow = DateTime(2026, 8, 15, 10);

  const phone = PhoneNumber(dialCode: '+225', nationalNumber: '0700000000');

  final session = AuthSession(
    userId: 'utilisateur-1',
    phone: phone,
    openedAt: fixedNow,
  );

  Future<SharedPreferences> preferencesWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  /// Conteneur du profil : préférences vierges, horloge figée, et une session
  /// déjà ouverte — l'écran de profil n'a pas à rejouer la connexion pour être
  /// testé.
  Future<ProviderContainer> makeContainer([
    Map<String, Object> values = const {},
  ]) async {
    final preferences = await preferencesWith(values);

    return ProviderContainer.test(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(_FixedClock(fixedNow)),
        authSessionProvider.overrideWith((ref) async => session),
      ],
    );
  }

  group('monogramme', () {
    UserProfile withName(String name) =>
        UserProfile(phone: phone, displayName: name);

    test('deux mots donnent deux initiales', () {
      expect(withName('Kouadio Aristide').initials, 'KA');
      expect(withName('  kouadio   aristide  ').initials, 'KA');
    });

    test('un seul mot donne une initiale', () {
      expect(withName('Aristide').initials, 'A');
    });

    test('au-delà de deux mots, on s\'arrête à deux', () {
      expect(withName('Jean Baptiste Kouassi').initials, 'JB');
    });

    test('sans nom, ni initiales ni titre inventé', () {
      expect(withName('   ').initials, isEmpty);
      expect(withName('').hasDisplayName, isFalse);
      expect(withName('').title, phone.e164);
    });
  });

  group('compte', () {
    test('le nom affiché est conservé', () async {
      final container = await makeContainer();
      final repository = container.read(accountRepositoryProvider);

      expect((await repository.displayName()).valueOrNull, isEmpty);

      await repository.setDisplayName('  Kouadio Aristide  ');

      expect(
        (await repository.displayName()).valueOrNull,
        'Kouadio Aristide',
        reason: 'les espaces de saisie ne font pas partie du nom',
      );

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesAccountDataSource.displayNameKey,
        ),
        'Kouadio Aristide',
      );
    });

    test('un nom trop long est refusé, pas tronqué', () async {
      final container = await makeContainer();

      final failure = (await container
              .read(accountRepositoryProvider)
              .setDisplayName('K' * 61))
          .failureOrNull;

      expect(failure, isA<ValidationFailure>());
    });

    test('l\'appareil courant ne peut pas se retirer lui-même', () async {
      final container = await makeContainer();
      final repository = container.read(accountRepositoryProvider);

      final devices = (await repository.devices()).valueOrNull!;
      final current = devices.firstWhere((device) => device.isCurrent);

      expect(
        (await repository.forgetDevice(current.id)).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect((await repository.devices()).valueOrNull, hasLength(devices.length));
    });

    test('retirer un autre appareil le sort de la liste', () async {
      final container = await makeContainer();
      final viewModel = container.read(profileViewModelProvider.notifier);
      final before = await container.read(profileViewModelProvider.future);

      final other = before.devices.firstWhere((device) => !device.isCurrent);

      expect(await viewModel.forgetDevice(other.id), isNull);
      expect(
        container.read(profileViewModelProvider).value?.devices,
        isNot(contains(other)),
      );
    });

    test('aucune église n\'est rattachée tant que l\'annuaire n\'existe pas',
        () async {
      final container = await makeContainer();

      final state = await container.read(profileViewModelProvider.future);

      expect(state.churches, isEmpty);
    });
  });

  group('écran', () {
    Future<void> pumpProfile(
      WidgetTester tester, [
      Map<String, Object> values = const {},
    ]) async {
      final preferences = await preferencesWith(values);

      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            clockProvider.overrideWithValue(_FixedClock(fixedNow)),
            authSessionProvider.overrideWith((ref) async => session),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sans nom, l\'écran le dit plutôt que d\'en inventer un',
        (tester) async {
      await pumpProfile(tester);

      expect(find.text('Sans nom'), findsOneWidget);
      expect(find.text('À définir'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('le numéro est affiché par groupes de deux', (tester) async {
      await pumpProfile(tester);

      expect(find.text('+225 07 00 00 00 00'), findsWidgets);
    });

    testWidgets('les appareils reprennent la maquette', (tester) async {
      await pumpProfile(tester);

      expect(find.text('Tecno Spark 8C'), findsOneWidget);
      expect(find.text('Cet appareil · actif maintenant'), findsOneWidget);
      expect(find.text('itel A60'), findsOneWidget);
      expect(find.text('Dernière activité le 28 juillet'), findsOneWidget);
      expect(
        find.text('Retirer'),
        findsOneWidget,
        reason: 'l\'appareil courant n\'a pas de bouton de retrait',
      );
    });

    testWidgets('retirer un appareil demande confirmation', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();

      expect(find.text('Retirer itel A60 ?'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('itel A60'), findsOneWidget);

      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Retirer').last);
      await tester.pumpAndSettle();

      expect(find.text('itel A60'), findsNothing);
    });

    testWidgets('nommer l\'utilisateur met à jour l\'en-tête et le monogramme',
        (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Nom affiché'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Kouadio Aristide');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Kouadio Aristide'), findsWidgets);
      expect(find.text('KA'), findsOneWidget);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesAccountDataSource.displayNameKey,
        ),
        'Kouadio Aristide',
      );
    });

    testWidgets('la promesse d\'étanchéité accompagne les églises',
        (tester) async {
      await pumpProfile(tester);

      expect(find.text('Aucune église rattachée'), findsOneWidget);
      expect(
        find.textContaining('ne traverse jamais vers elles'),
        findsOneWidget,
      );
    });
  });
}
