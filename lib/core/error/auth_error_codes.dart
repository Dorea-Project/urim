/// Codes d'erreur du contexte `auth` du serveur.
///
/// Recopiés depuis `app/contexts/auth/domain/errors.py`, et volontairement
/// figés ici : le message du serveur est technique et change au fil des
/// relectures, le **code** est stable. C'est donc lui qui décide de ce que
/// l'écran raconte, jamais le texte reçu.
abstract final class AuthErrorCodes {
  const AuthErrorCodes._();

  /// Code SMS périmé. **410** — sans traitement dédié, il tombait dans les
  /// erreurs serveur, et l'utilisateur lisait une panne là où il devait lire
  /// « demande un nouveau code ».
  static const String otpExpired = 'AUTH_OTP_EXPIRED';

  /// Code SMS faux. 401.
  static const String otpInvalid = 'AUTH_OTP_INVALID';

  /// Aucun défi en cours : la demande a expiré ou n'a jamais existé. 404.
  static const String otpNotFound = 'AUTH_OTP_NOT_FOUND';

  /// Trop de codes demandés. 429.
  static const String otpTooManyRequests = 'AUTH_OTP_TOO_MANY_REQUESTS';

  /// Trop d'essais sur le même code. 429.
  static const String otpTooManyAttempts = 'AUTH_OTP_TOO_MANY_ATTEMPTS';

  /// Numéro ou code secret refusé. 401.
  static const String invalidCredentials = 'AUTH_INVALID_CREDENTIALS';

  /// Compte verrouillé après cinq échecs. 429.
  static const String tooManyAttempts = 'AUTH_TOO_MANY_ATTEMPTS';

  /// Numéro déjà inscrit — l'inscription ne s'applique pas, la connexion si.
  /// 409.
  static const String phoneAlreadyRegistered = 'AUTH_PHONE_ALREADY_REGISTERED';

  /// Compte désactivé. 401.
  static const String accountInactive = 'AUTH_ACCOUNT_INACTIVE';

  /// Le code secret ne respecte pas le format attendu du serveur. 422.
  static const String invalidSecretCodeFormat = 'AUTH_INVALID_SECRET_CODE_FORMAT';

  /// Vrai lorsque redemander un code est la sortie — l'écran doit alors
  /// proposer le bouton, pas seulement afficher un message.
  static bool needsNewCode(String? code) =>
      code == otpExpired || code == otpNotFound;

  /// Vrai lorsque l'utilisateur doit attendre : rien ne sert de réessayer tout
  /// de suite, et le lui cacher le ferait s'acharner.
  static bool isThrottled(String? code) =>
      code == tooManyAttempts ||
      code == otpTooManyAttempts ||
      code == otpTooManyRequests;
}
