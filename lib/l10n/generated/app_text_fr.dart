// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_text.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppTextFr extends AppText {
  AppTextFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Urim';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Continuer';

  @override
  String get onboardingCreateAccount => 'Créer mon compte';

  @override
  String get onboardingSignIn => 'J\'ai déjà un compte';

  @override
  String get onboardingSaveFailed =>
      'Impossible d\'enregistrer ta progression. La présentation réapparaîtra au prochain lancement.';

  @override
  String onboardingStep(int position, int total) {
    return 'Étape $position sur $total';
  }

  @override
  String get onboardingWeighingTitle =>
      'Écris ta phrase.\nUrim cherche le texte dedans.';

  @override
  String get onboardingWeighingBody =>
      'Une référence, une citation approximative, ou juste une intention. Tu n\'as aucun mode à choisir — la porte regarde si les mots se suivent comme dans l\'Écriture.';

  @override
  String get onboardingHandbackTitle => 'Il s\'arrête\net te rend la main.';

  @override
  String get onboardingHandbackBody =>
      'Chaque étage dit pourquoi il a fait ce qu\'il a fait. Quand il ne peut pas trancher seul, il te pose la question au lieu de choisir à ta place.';

  @override
  String get onboardingResistanceTitle =>
      'Il te montre les textes qui te résistent.';

  @override
  String get onboardingResistanceBody =>
      'Ceux qui ne vont pas dans le sens de ta lecture. C\'est le seul moyen de ne pas faire dire au texte ce qu\'on avait décidé d\'y trouver.';

  @override
  String get back => 'Retour';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get authPhoneTitleSignIn => 'Ton numéro';

  @override
  String get authPhoneTitleRegistration => 'Ton numéro valide';

  @override
  String get authPhoneHint => '07 47 76 9069';

  @override
  String get authPhoneSubmit => 'Soumettre';

  @override
  String get authPrivacyConsent => 'J\'ai lu et j\'accepte la ';

  @override
  String get authPrivacyLink => 'politique de confidentialité';

  @override
  String authOtpTitle(int count) {
    return 'Utiliser code SMS de $count chiffres';
  }

  @override
  String get authOtpValidate => 'Validation';

  @override
  String get authOtpResend => 'Renvoyer le code';

  @override
  String get authOtpRequestNew => 'Demander un nouveau code';

  @override
  String get authOtpExpiredShort => 'Code expiré';

  @override
  String authOtpRemainingMinutes(int minutes, String seconds) {
    return 'il reste $minutes min $seconds';
  }

  @override
  String authOtpRemainingSeconds(int seconds) {
    return 'il reste $seconds s';
  }

  @override
  String get secretCodeChooseTitle => 'Choisis un code secret';

  @override
  String get secretCodeConfirmTitle => 'Confirme ton code secret';

  @override
  String secretCodeChooseHelper(int count) {
    return '$count chiffres, demandés à chaque ouverture';
  }

  @override
  String get secretCodeConfirmHelper => 'Saisis-le une seconde fois';

  @override
  String get secretCodeUnlockTitle => 'Ton code secret';

  @override
  String get secretCodeUnlockHelper => 'Saisis tes chiffres';

  @override
  String get secretCodeWrong => 'Code incorrect';

  @override
  String get signInForgotten => 'Code oublié ?';

  @override
  String get errorOtpExpired => 'Ce code a expiré. Demandes-en un nouveau.';

  @override
  String get errorOtpInvalid => 'Code incorrect.';

  @override
  String get errorOtpTooManyAttempts =>
      'Trop d\'essais sur ce code. Demandes-en un nouveau.';

  @override
  String get errorOtpTooManyRequests =>
      'Trop de codes demandés. Patiente quelques minutes.';

  @override
  String get errorPhoneAlreadyRegistered =>
      'Ce numéro a déjà un compte. Connecte-toi.';

  @override
  String get errorSecretCodeIncorrect => 'Code secret incorrect.';

  @override
  String get errorTooManyAttempts =>
      'Trop d\'essais. Attends quelques minutes avant de réessayer.';

  @override
  String get errorAccountInactive => 'Ce compte est désactivé.';

  @override
  String get errorNoConnection => 'Pas de connexion.';

  @override
  String get errorVerificationUnavailable =>
      'Vérification impossible pour l\'instant.';

  @override
  String get errorSignInUnavailable => 'Connexion impossible pour l\'instant.';

  @override
  String get demoPhone =>
      'Serveur simulé : aucun SMS ne part. Le numéro est prérempli, coche la politique et soumets.';

  @override
  String demoOtp(String code) {
    return 'Serveur simulé : le code est $code.';
  }

  @override
  String demoSecretCodeSetup(String code) {
    return 'Pour l\'essai : $code. Un code répété (0000) ou suivi (1234) est refusé.';
  }

  @override
  String demoSecretCodeUnlock(String code) {
    return 'Celui que tu as choisi à la création — $code si tu as suivi la suggestion.';
  }

  @override
  String demoSignIn(String code) {
    return 'Serveur simulé : le code est celui que tu as posé à l\'inscription — $code si tu as suivi la suggestion.';
  }
}
