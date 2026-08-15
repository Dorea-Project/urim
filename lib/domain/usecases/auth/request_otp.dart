import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';

final class RequestOtpParams extends Equatable {
  const RequestOtpParams({
    required this.phone,
    required this.privacyAccepted,
  });

  final PhoneNumber phone;
  final bool privacyAccepted;

  @override
  List<Object?> get props => [phone, privacyAccepted];
}

/// Demande l'envoi du code SMS.
///
/// Le consentement est vérifié ici, et pas seulement en désactivant le bouton :
/// une règle qui ne vit que dans l'interface disparaît au premier écran refait.
final class RequestOtp implements UseCase<OtpChallenge, RequestOtpParams> {
  const RequestOtp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<OtpChallenge>> call(RequestOtpParams params) async {
    if (!params.privacyAccepted) {
      return const Result.failed(
        ValidationFailure(
          message: 'La politique de confidentialité doit être acceptée.',
          code: 'privacy_not_accepted',
          fieldErrors: {'privacy': 'Obligatoire'},
        ),
      );
    }

    if (!params.phone.isValid) {
      return const Result.failed(
        ValidationFailure(
          message: 'Ce numéro n\'est pas valide.',
          code: 'invalid_phone',
          fieldErrors: {'phone': 'Numéro incomplet'},
        ),
      );
    }

    return _repository.requestOtp(params.phone);
  }
}
