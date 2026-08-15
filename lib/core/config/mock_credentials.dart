import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Identifiants du parcours de démonstration.
///
/// Aucune passerelle SMS n'existe encore : sans code connu d'avance,
/// l'application compilée est infranchissable — le code tiré au hasard n'était
/// visible que dans les journaux de débogage, absents d'un APK de production.
///
/// Ces valeurs ne sont **jamais** actives en production : `AppConfig` en
/// commande l'affichage, et le vrai serveur remplacera `DevAuthDataSource`
/// avant toute mise en ligne.
abstract final class MockCredentials {
  const MockCredentials._();

  static const String dialCode = PhoneNumber.defaultDialCode;

  /// Numéro prérempli sur l'écran de connexion.
  static const String nationalNumber = '0700000000';

  /// Code « reçu par SMS », accepté par la source de démonstration.
  ///
  /// Six chiffres, comme ceux du serveur : le jour où l'on bascule sur le vrai
  /// backend, seule la provenance du code change, pas la saisie.
  static const String otp = '000000';

  /// Code secret suggéré à la création. Ni répété ni suivi : les deux sont
  /// refusés par la politique, et le suggérer trivialement enseignerait la
  /// mauvaise habitude.
  static const String secretCode = '2749';

  /// Garde-fou : si la longueur du code SMS change, le code de démonstration
  /// doit suivre.
  static bool get isCoherent => otp.length == OtpChallenge.defaultCodeLength;
}
