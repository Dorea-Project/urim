import 'package:flutter_test/flutter_test.dart';
import 'package:urim/domain/entities/account/device_roster.dart';
import 'package:urim/domain/entities/account/known_device.dart';

void main() {
  final now = DateTime(2026, 8, 15, 10);

  KnownDevice device(String id, {bool current = false}) => KnownDevice(
        id: id,
        label: 'Tecno Spark $id',
        lastActiveAt: now,
        isCurrent: current,
      );

  group('deux appareils au maximum', () {
    test('la limite est deux', () {
      expect(DeviceRoster.maxDevices, 2);
    });

    test('un seul appareil laisse une place', () {
      final roster = DeviceRoster([device('1', current: true)]);

      expect(roster.count, 1);
      expect(roster.freeSlots, 1);
      expect(roster.isFull, isFalse);
      expect(roster.acceptsAnother, isTrue);
    });

    test('deux appareils remplissent le compte', () {
      final roster = DeviceRoster([device('1', current: true), device('2')]);

      expect(roster.isFull, isTrue);
      expect(roster.freeSlots, 0);
      expect(roster.acceptsAnother, isFalse);
    });

    test('un compte vide accepte deux appareils', () {
      const roster = DeviceRoster([]);

      expect(roster.freeSlots, 2);
      expect(roster.current, isNull);
    });

    test('au-delà de la limite, aucune place négative', () {
      final roster = DeviceRoster([
        device('1', current: true),
        device('2'),
        device('3'),
      ]);

      expect(
        roster.freeSlots,
        0,
        reason: 'le serveur a pu accorder plus que la règle actuelle ; '
            'l\'écran ne doit pas afficher « -1 »',
      );
      expect(roster.isFull, isTrue);
    });
  });

  group('ce qu\'on peut libérer', () {
    test('l\'appareil courant ne se retire pas lui-même', () {
      final roster = DeviceRoster([device('1', current: true), device('2')]);

      expect(roster.current?.id, '1');
      expect(
        roster.removable.map((device) => device.id),
        ['2'],
        reason: 'retirer l\'appareil courant serait une déconnexion déguisée, '
            'qui a son propre bouton',
      );
    });

    test('sans autre appareil, il n\'y a rien à libérer', () {
      final roster = DeviceRoster([device('1', current: true)]);

      expect(roster.removable, isEmpty);
    });
  });
}
