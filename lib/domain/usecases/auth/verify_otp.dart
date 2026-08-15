import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/repositories/auth_repository.dart';

final class VerifyOtpParams extends Equatable {
  const VerifyOtpParams({required this.challenge, required this.code});

  final OtpChallenge challenge;
  final String code;

  @override
  List<Object?> get props => [challenge, code];
}

/// Vérifie le code reçu par SMS et ouvre la session.
final class VerifyOtp implements UseCase<AuthSession, VerifyOtpParams> {
  const VerifyOtp(this._repository, this._now);

  final AuthRepository _repository;

  /// Horloge injectée : l'expiration doit être testable sans attendre cinq
  /// minutes.
  final DateTime Function() _now;

  @override
  Future<Result<AuthSession>> call(VerifyOtpParams params) async {
    final code = params.code.trim();

    if (code.length != params.challenge.codeLength ||
        !RegExp(r'^\d+$').hasMatch(code)) {
      return Result.failed(
        ValidationFailure(
          message: 'Le code comporte '
              '${params.challenge.codeLength} chiffres.',
          code: 'invalid_code_format',
          fieldErrors: const {'code': 'Code incomplet'},
        ),
      );
    }

    // Contrôle local d'abord, pour ne pas consommer une tentative serveur sur
    // un code dont on sait déjà qu'il est périmé. Le serveur revérifie de son
    // côté : c'est lui qui fait autorité.
    if (params.challenge.isExpired(_now())) {
      return const Result.failed(
        AuthFailure(
          message: 'Ce code a expiré. Demandez-en un nouveau.',
          code: 'otp_expired',
        ),
      );
    }

    return _repository.verifyOtp(
      challengeId: params.challenge.id,
      code: code,
    );
  }
}
