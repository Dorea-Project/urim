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

  @override
  String get privacyTitle => 'Tes données';

  @override
  String get privacyIntro =>
      'Trois choses qu\'Urim ne fera jamais. Elles sont tenues par le code, pas par une promesse.';

  @override
  String get privacyNoProfilingTitle => 'Aucune analyse de personne';

  @override
  String get privacyNoProfilingBody =>
      'Urim traite des textes. Il ne produit aucun jugement, score ou profil sur un membre, un fidèle ou un collaborateur.';

  @override
  String get privacyOwnershipTitle => 'Tes préparations restent à toi';

  @override
  String get privacyOwnershipBody =>
      'Elles ne sont lues par personne d\'autre — ni par ton église, ni par Dorea, ni par un responsable.';

  @override
  String get privacyNoResaleTitle => 'Rien n\'est revendu';

  @override
  String get privacyNoResaleBody =>
      'Aucun partage à un tiers, aucune publicité, aucun entraînement de modèle sur ton contenu.';

  @override
  String get privacyRetainedLabel => 'CE QUI EST CONSERVÉ';

  @override
  String get privacyRetainedPhone =>
      'Ton numéro de téléphone, pour te reconnaître.';

  @override
  String get privacyRetainedWork =>
      'Tes préparations et enregistrements, jusqu\'à ce que tu les supprimes.';

  @override
  String get privacyRetainedDevices =>
      'Les appareils sur lesquels tu t\'es connecté.';

  @override
  String get privacyLegalNotice =>
      'Traitement soumis à la loi ivoirienne n° 2013-450 relative à la protection des données à caractère personnel. Tu peux supprimer ton compte et tout son contenu à tout moment.';

  @override
  String get privacyAccept => 'J\'ai lu et j\'accepte';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSectionReading => 'Lecture';

  @override
  String get settingsSectionScripture => 'Écriture';

  @override
  String get settingsSectionOffline => 'Hors connexion';

  @override
  String get settingsSectionReminders => 'Rappels';

  @override
  String get settingsSectionContent => 'Contenu';

  @override
  String get settingsTextSize => 'Taille du texte';

  @override
  String get settingsTextSizeSmall => 'Petit';

  @override
  String get settingsTextSizeNormal => 'Normal';

  @override
  String get settingsTextSizeLarge => 'Grand';

  @override
  String get settingsTextSizeExtraLarge => 'Très grand';

  @override
  String get settingsReadingSample =>
      'Ils persévéraient dans l\'enseignement des apôtres…';

  @override
  String get settingsDefaultVersion => 'Version par défaut';

  @override
  String get settingsAlwaysShowReference => 'Toujours afficher la référence';

  @override
  String get settingsAlwaysShowReferenceHint =>
      'Livre, chapitre, verset et version sous chaque citation.';

  @override
  String get settingsBibleDownloaded => 'Texte biblique téléchargé';

  @override
  String get settingsBibleDownloadedPending =>
      'Disponible quand la source du texte biblique aura été choisie.';

  @override
  String get settingsTranscribeOnDevice => 'Transcrire sur l\'appareil';

  @override
  String get settingsTranscribeOnDevicePending =>
      'L\'audio ne quittera jamais le téléphone. Le moteur de transcription reste à retenir.';

  @override
  String get settingsWifiOnly => 'Synchroniser en Wi-Fi seulement';

  @override
  String get settingsWifiOnlyPending =>
      'Rien n\'est encore synchronisé : tes préparations ne quittent pas cet appareil.';

  @override
  String get settingsReminderInProgress => 'Préparation en cours';

  @override
  String get settingsReminderInProgressPending =>
      'Un rappel le samedi si un message n\'est pas terminé — dès qu\'une préparation saura dire qu\'elle ne l\'est pas.';

  @override
  String get settingsExport => 'Exporter mes préparations';

  @override
  String get settingsExportPending =>
      'Texte ou PDF — l\'export arrive avec la synthèse.';

  @override
  String get settingsStorageUsed => 'Espace utilisé';

  @override
  String get settingsStorageUsedPending =>
      'Mesurable une fois le stockage des préparations choisi.';

  @override
  String get settingsTrainingNotice =>
      'Urim n\'utilise jamais tes préparations pour entraîner un modèle.';

  @override
  String get settingsSaveFailed => 'Ce réglage n\'a pas pu être enregistré.';

  @override
  String get settingsReadFailed => 'Les réglages n\'ont pas pu être lus.';

  @override
  String get translationPublicDomain => 'Domaine public';

  @override
  String get translationLicenceNotice =>
      'Les autres traductions demandent une licence : Urim ne les proposera qu\'une fois les droits obtenus.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileNoName => 'Sans nom';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileSectionChurches => 'Églises';

  @override
  String get profileSectionDevices => 'Appareils';

  @override
  String get profileDisplayName => 'Nom affiché';

  @override
  String get profileDisplayNameEmpty => 'À définir';

  @override
  String get profileDisplayNameHint => 'Kouadio Aristide';

  @override
  String get profileDisplayNameExplanation =>
      'Ce nom ne sort pas de l\'application : il sert à te reconnaître sur cet écran, et à former ton monogramme.';

  @override
  String get profileNoNameAvatar => 'Aucun nom défini';

  @override
  String get profilePhone => 'Numéro de téléphone';

  @override
  String get profilePhonePending =>
      'Changer de numéro suppose un nouveau code par SMS.';

  @override
  String get profileSecretCode => 'Code à 4 chiffres';

  @override
  String get profileSecretCodeAction => 'Modifier';

  @override
  String get profileSecretCodePending =>
      'Le changement passera par l\'écran de création, encore réservé au premier accès.';

  @override
  String get profileNoChurch => 'Aucune église rattachée';

  @override
  String get profileNoChurchHint =>
      'Le rattachement viendra de l\'annuaire de la plateforme, pas d\'Urim.';

  @override
  String get profileChurchRecognised =>
      'Ton numéro y est reconnu. Tes préparations n\'y sont pas visibles.';

  @override
  String get profileChurchesNote =>
      'Une seule identité, plusieurs églises possibles. Ce que tu écris dans Urim ne traverse jamais vers elles.';

  @override
  String get profileDeviceCurrent => 'Cet appareil · actif maintenant';

  @override
  String profileDeviceLastSeen(String date) {
    return 'Dernière activité le $date';
  }

  @override
  String get profileDeviceRemove => 'Retirer';

  @override
  String profileDeviceRemoveTitle(String device) {
    return 'Retirer $device ?';
  }

  @override
  String get profileDeviceRemoveBody =>
      'Cet appareil devra se reconnecter par SMS pour ouvrir Urim.';

  @override
  String get profileReadFailed => 'Le profil n\'a pas pu être lu.';

  @override
  String get profileChangeRefused => 'Cette modification a été refusée.';

  @override
  String get profileChangeFailed =>
      'Cette modification n\'a pas pu être enregistrée.';

  @override
  String get profileNoSession => 'Aucune session ouverte.';

  @override
  String get save => 'Enregistrer';
}
