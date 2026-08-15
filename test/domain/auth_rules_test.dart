import 'package:flutter_test/flutter_test.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/entities/auth/secret_code_policy.dart';

void main() {
  group('PhoneNumber', () {
    test('un numéro ivoirien fait dix chiffres', () {
      const valid = PhoneNumber(dialCode: '+225', nationalNumber: '0747769069');
      const tooShort = PhoneNumber(dialCode: '+225', nationalNumber: '074776');

      expect(valid.isValid, isTrue);
      expect(tooShort.isValid, isFalse);
    });

    test('la normalisation retire ce que les gens saisissent', () {
      expect(PhoneNumber.normalize('07 47 76-90.69'), '0747769069');
    });

    test('la forme E.164 recolle indicatif et numéro', () {
      const phone = PhoneNumber(dialCode: '+225', nationalNumber: '0747769069');
      expect(phone.e164, '+2250747769069');
    });

    test('hors Côte d\'Ivoire, la longueur est simplement plausible', () {
      const french = PhoneNumber(dialCode: '+33', nationalNumber: '612345678');
      expect(french.isValid, isTrue);
    });
  });

  group('SecretCodePolicy', () {
    test('rejette les répétitions et les suites', () {
      expect(SecretCodePolicy.isTrivial('0000'), isTrue);
      expect(SecretCodePolicy.isTrivial('1234'), isTrue);
      expect(SecretCodePolicy.isTrivial('4321'), isTrue);
      expect(SecretCodePolicy.isTrivial('7777'), isTrue);
    });

    test('accepte un code ordinaire', () {
      expect(SecretCodePolicy.isTrivial('2749'), isFalse);
      expect(SecretCodePolicy.isTrivial('1357'), isFalse);
    });

    test('exige la bonne longueur et des chiffres', () {
      expect(SecretCodePolicy.hasValidShape('2749'), isTrue);
      expect(SecretCodePolicy.hasValidShape('274'), isFalse);
      expect(SecretCodePolicy.hasValidShape('27a9'), isFalse);
    });
  });

  group('OtpChallenge', () {
    final expiry = DateTime(2026, 8, 15, 10, 5);
    final challenge = OtpChallenge(
      id: 'c1',
      phone: const PhoneNumber(
        dialCode: '+225',
        nationalNumber: '0747769069',
      ),
      expiresAt: expiry,
    );

    test('expire à l\'échéance, pas après', () {
      expect(challenge.isExpired(expiry.subtract(const Duration(seconds: 1))),
          isFalse);
      expect(challenge.isExpired(expiry), isTrue);
    });

    test('le temps restant ne devient jamais négatif', () {
      expect(
        challenge.remaining(expiry.add(const Duration(minutes: 3))),
        Duration.zero,
      );
    });
  });
}
