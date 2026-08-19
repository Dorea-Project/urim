import 'package:equatable/equatable.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Ce que rend une tentative de connexion.
///
/// Un appareil déjà connu ouvre la session ; un appareil inconnu déclenche un
/// SMS et n'ouvre rien. Le type distingue les deux, plutôt qu'une session
/// nulle qui obligerait chaque appelant à deviner pourquoi.
sealed class SignInResult extends Equatable {
  const SignInResult();

  const factory SignInResult.opened(AuthSession session) = SessionOpened;

  const factory SignInResult.deviceUnknown() = DeviceVerificationNeeded;
}

final class SessionOpened extends SignInResult {
  const SessionOpened(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

final class DeviceVerificationNeeded extends SignInResult {
  const DeviceVerificationNeeded();

  @override
  List<Object?> get props => const [];
}

/// Le parcours d'entrée, vu du métier.
///
/// L'identifiant d'appareil n'apparaît nulle part : c'est une affaire
/// d'infrastructure, résolue par la couche data. Le domaine ne connaît que le
/// numéro, le code reçu et le code secret.
abstract interface class AuthRepository {
  /// Inscription — demande le code par SMS.
  Future<Result<void>> requestRegistration(PhoneNumber phone);

  /// Inscription — confirme le code et pose le code secret.
  Future<Result<AuthSession>> confirmRegistration({
    required PhoneNumber phone,
    required String otp,
    required String secretCode,
  });

  /// Connexion d'un compte existant.
  Future<Result<SignInResult>> signIn({
    required PhoneNumber phone,
    required String secretCode,
  });

  /// Vérifie le code reçu sur un nouvel appareil.
  Future<Result<AuthSession>> verifyDevice({
    required PhoneNumber phone,
    required String otp,
  });

  /// Code secret oublié — demande le code par SMS.
  Future<Result<void>> requestSecretCodeReset(PhoneNumber phone);

  /// Code secret oublié — pose le nouveau code et ouvre la session.
  Future<Result<AuthSession>> confirmSecretCodeReset({
    required PhoneNumber phone,
    required String otp,
    required String newSecretCode,
  });

  /// Changer son code secret en étant connecté — demande le code par SMS.
  ///
  /// Distincte de la réinitialisation : elle n'ouvre pas de session, elle en
  /// suppose une, et ne révoque aucun appareil.
  Future<Result<void>> requestSecretCodeChange();

  /// Changer son code secret — pose le nouveau code, sans toucher la session.
  Future<Result<void>> confirmSecretCodeChange({
    required String otp,
    required String newSecretCode,
  });

  /// Changer de numéro — demande le code, envoyé au **nouveau** numéro.
  Future<Result<void>> requestPhoneChange(PhoneNumber newPhone);

  /// Changer de numéro — le pose sur le compte, et sur la trace locale.
  Future<Result<AuthSession>> confirmPhoneChange({
    required PhoneNumber newPhone,
    required String otp,
  });

  /// Supprimer son compte — demande le code par SMS.
  Future<Result<void>> requestAccountDeletion();

  /// Supprimer son compte — le serveur efface le contenu et ferme le compte.
  ///
  /// Ne touche pas à ce que l'appareil garde : l'effacement local suit, et
  /// dans cet ordre — un appareil vidé alors que le serveur a refusé
  /// laisserait un compte vivant sans plus rien pour l'atteindre.
  Future<Result<void>> confirmAccountDeletion({required String otp});

  /// Session locale, `null` si personne n'est connecté.
  Future<Result<AuthSession?>> currentSession();

  /// Ferme la session. [everywhere] révoque tous les appareils du compte.
  Future<Result<void>> signOut({bool everywhere});
}
