import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/entities/auth/secret_code_policy.dart';
import 'package:urim/domain/repositories/auth_repository.dart';

final class ConfirmRegistrationParams extends Equatable {
  const ConfirmRegistrationParams({
    required this.phone,
    required this.otp,
    required this.secretCode,
  });

  final PhoneNumber phone;
  final String otp;

  /// Le code secret est posé **en même temps** que la vérification du SMS :
  /// le serveur n'ouvre pas de compte sans serrure.
  final String secretCode;

  @override
  List<Object?> get props => [phone, otp, secretCode];
}

/// Confirme le code reçu, pose le code secret, et ouvre la session.
final class ConfirmRegistration
    implements UseCase<AuthSession, ConfirmRegistrationParams> {
  const ConfirmRegistration(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(ConfirmRegistrationParams params) async {
    final otp = params.otp.trim();

    final malformed = _rejectMalformedOtp(otp);
    if (malformed != null) return malformed;

    if (!SecretCodePolicy.hasValidShape(params.secretCode)) {
      return const Result.failed(
        ValidationFailure(
          message: 'Le code secret doit comporter '
              '${SecretCodePolicy.length} chiffres.',
          code: 'invalid_secret_code',
          fieldErrors: {'secret_code': 'Code incomplet'},
        ),
      );
    }

    return _repository.confirmRegistration(
      phone: params.phone,
      otp: otp,
      secretCode: params.secretCode,
    );
  }
}

final class VerifyDeviceParams extends Equatable {
  const VerifyDeviceParams({required this.phone, required this.otp});

  final PhoneNumber phone;
  final String otp;

  @override
  List<Object?> get props => [phone, otp];
}

/// Vérifie le code reçu sur un appareil que le serveur ne connaissait pas.
final class VerifyDevice implements UseCase<AuthSession, VerifyDeviceParams> {
  const VerifyDevice(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(VerifyDeviceParams params) async {
    final otp = params.otp.trim();

    final malformed = _rejectMalformedOtp(otp);
    if (malformed != null) return malformed;

    return _repository.verifyDevice(phone: params.phone, otp: otp);
  }
}

/// Refus local d'un code manifestement mal formé.
///
/// Le serveur revérifie et fait autorité ; ce contrôle évite seulement de
/// consommer une des cinq tentatives pour un code de quatre chiffres.
Result<AuthSession>? _rejectMalformedOtp(String otp) {
  if (otp.length == OtpChallenge.defaultCodeLength &&
      RegExp(r'^\d+$').hasMatch(otp)) {
    return null;
  }

  return Result.failed(
    ValidationFailure(
      message: 'Le code comporte ${OtpChallenge.defaultCodeLength} chiffres.',
      code: 'invalid_code_format',
      fieldErrors: const {'otp': 'Code incomplet'},
    ),
  );
}
