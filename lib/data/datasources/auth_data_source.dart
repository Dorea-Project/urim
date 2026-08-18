import 'package:equatable/equatable.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Ce que rend une tentative de connexion.
///
/// Deux issues, et une seule des deux porte des jetons : un appareil inconnu
/// ne reçoit rien tant que le SMS n'a pas été vérifié. Les distinguer par un
/// type plutôt que par un booléen empêche de lire des jetons qui n'existent
/// pas.
sealed class SignInOutcome extends Equatable {
  const SignInOutcome();

  const factory SignInOutcome.session(AuthTokens tokens) = SignedIn;

  const factory SignInOutcome.otpRequired() = DeviceVerificationRequired;
}

/// Appareil de confiance : la session est ouverte.
final class SignedIn extends SignInOutcome {
  const SignedIn(this.tokens);

  final AuthTokens tokens;

  @override
  List<Object?> get props => [tokens];
}

/// Appareil inconnu : un SMS est parti, la suite passe par `verifyDevice`.
final class DeviceVerificationRequired extends SignInOutcome {
  const DeviceVerificationRequired();

  @override
  List<Object?> get props => const [];
}

/// Le parcours d'entrée, tel que le serveur l'expose.
///
/// Une seule interface pour la source distante et la source simulée : passer
/// de l'une à l'autre est une affaire de configuration, pas de réécriture.
abstract interface class AuthDataSource {
  /// Inscription — demande l'OTP. Le numéro est le seul élément connu.
  Future<void> requestRegistration(PhoneNumber phone);

  /// Inscription — confirme l'OTP **et** pose le code secret d'un même geste.
  ///
  /// Le code secret arrive avec l'OTP parce qu'il n'y a pas d'instant
  /// intermédiaire où le compte existerait sans code : le serveur ne veut pas
  /// d'un compte à moitié ouvert.
  Future<AuthTokens> confirmRegistration({
    required PhoneNumber phone,
    required String otp,
    required String secretCode,
    required String deviceId,
  });

  /// Connexion — numéro, code secret et appareil.
  Future<SignInOutcome> signIn({
    required PhoneNumber phone,
    required String secretCode,
    required String deviceId,
  });

  /// Vérifie l'OTP d'un nouvel appareil, qui devient de confiance.
  Future<AuthTokens> verifyDevice({
    required PhoneNumber phone,
    required String otp,
    required String deviceId,
  });

  /// Code secret oublié — demande l'OTP.
  ///
  /// Réussit toujours, même sur un numéro inconnu : répondre « inconnu »
  /// ferait de cette route un annuaire des inscrits.
  Future<void> requestSecretCodeReset(PhoneNumber phone);

  /// Code secret oublié — pose le nouveau code et ouvre la session.
  Future<AuthTokens> confirmSecretCodeReset({
    required PhoneNumber phone,
    required String otp,
    required String newSecretCode,
    required String deviceId,
  });

  /// Changer son code secret **en étant connecté** — demande l'OTP.
  ///
  /// Route distincte de « code oublié » : elle s'authentifie par le jeton, ne
  /// prend pas de numéro, et ne révoque aucun appareil. Le serveur l'a prévue
  /// (`/account/change-password`), et la confondre avec la réinitialisation
  /// déconnecterait la tablette du pasteur pour un simple changement de code.
  Future<void> requestSecretCodeChange();

  /// Changer son code secret — pose le nouveau code.
  ///
  /// Ne renvoie pas de jetons : la session en cours reste la sienne.
  Future<void> confirmSecretCodeChange({
    required String otp,
    required String newSecretCode,
  });

  /// Révoque cet appareil, ou tous.
  Future<void> signOut({bool everywhere});
}
