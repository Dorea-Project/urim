import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Inscription et connexion par numéro de téléphone.
abstract interface class AuthRepository {
  /// Demande l'envoi d'un code par SMS.
  Future<Result<OtpChallenge>> requestOtp(PhoneNumber phone);

  /// Vérifie le code reçu et ouvre la session.
  Future<Result<AuthSession>> verifyOtp({
    required String challengeId,
    required String code,
  });

  /// Session en cours, `null` si personne n'est connecté.
  Future<Result<AuthSession?>> currentSession();

  Future<Result<void>> signOut();
}
