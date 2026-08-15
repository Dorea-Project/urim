import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
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

/// Demande l'envoi du code SMS d'inscription.
///
/// Le consentement est vérifié ici, et pas seulement en désactivant le bouton :
/// une règle qui ne vit que dans l'interface disparaît au premier écran refait.
///
/// Le serveur ne répond rien d'autre qu'un accusé : ni identifiant de défi, ni
/// durée de validité. Le code voyage par SMS, et c'est l'utilisateur qui le
/// rapporte — l'application n'a aucun état à garder entre les deux écrans, sinon
/// le numéro.
final class RequestOtp implements UseCase<void, RequestOtpParams> {
  const RequestOtp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(RequestOtpParams params) async {
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

    return _repository.requestRegistration(params.phone);
  }
}
