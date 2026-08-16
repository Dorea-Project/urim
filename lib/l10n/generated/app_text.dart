import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_text_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppText
/// returned by `AppText.of(context)`.
///
/// Applications need to include `AppText.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_text.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppText.localizationsDelegates,
///   supportedLocales: AppText.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppText.supportedLocales
/// property.
abstract class AppText {
  AppText(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppText of(BuildContext context) {
    return Localizations.of<AppText>(context, AppText)!;
  }

  static const LocalizationsDelegate<AppText> delegate = _AppTextDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// Nom de l'application, affiché par le système.
  ///
  /// In fr, this message translates to:
  /// **'Urim'**
  String get appTitle;

  /// Sortie de la présentation, en haut à droite.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// Bouton principal des deux premières étapes.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get onboardingNext;

  /// Bouton principal de la dernière étape : la porte de l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get onboardingCreateAccount;

  /// La seconde porte : la connexion d'un compte existant.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get onboardingSignIn;

  /// Échec de l'écriture locale. Dit la conséquence, pas la cause technique.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer ta progression. La présentation réapparaîtra au prochain lancement.'**
  String get onboardingSaveFailed;

  /// Annonce vocale de la progression. Lu par les lecteurs d'écran, jamais affiché.
  ///
  /// In fr, this message translates to:
  /// **'Étape {position} sur {total}'**
  String onboardingStep(int position, int total);

  /// Titre de la première étape. Le retour à la ligne porte le rythme de la phrase.
  ///
  /// In fr, this message translates to:
  /// **'Écris ta phrase.\nUrim cherche le texte dedans.'**
  String get onboardingWeighingTitle;

  /// No description provided for @onboardingWeighingBody.
  ///
  /// In fr, this message translates to:
  /// **'Une référence, une citation approximative, ou juste une intention. Tu n\'as aucun mode à choisir — la porte regarde si les mots se suivent comme dans l\'Écriture.'**
  String get onboardingWeighingBody;

  /// No description provided for @onboardingHandbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Il s\'arrête\net te rend la main.'**
  String get onboardingHandbackTitle;

  /// No description provided for @onboardingHandbackBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque étage dit pourquoi il a fait ce qu\'il a fait. Quand il ne peut pas trancher seul, il te pose la question au lieu de choisir à ta place.'**
  String get onboardingHandbackBody;

  /// No description provided for @onboardingResistanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Il te montre les textes qui te résistent.'**
  String get onboardingResistanceTitle;

  /// No description provided for @onboardingResistanceBody.
  ///
  /// In fr, this message translates to:
  /// **'Ceux qui ne vont pas dans le sens de ta lecture. C\'est le seul moyen de ne pas faire dire au texte ce qu\'on avait décidé d\'y trouver.'**
  String get onboardingResistanceBody;

  /// Infobulle du bouton de retour, partout.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Titre de l'écran du numéro, porte « connexion ».
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro'**
  String get authPhoneTitleSignIn;

  /// Titre du même écran, porte « inscription » : le numéro doit être joignable, un SMS y part.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro valide'**
  String get authPhoneTitleRegistration;

  /// Exemple de saisie, format ivoirien.
  ///
  /// In fr, this message translates to:
  /// **'07 47 76 9069'**
  String get authPhoneHint;

  /// No description provided for @authPhoneSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre'**
  String get authPhoneSubmit;

  /// Début de la phrase de consentement. Se termine par le lien ci-dessous — les deux se lisent d'un trait.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai lu et j\'accepte la '**
  String get authPrivacyConsent;

  /// No description provided for @authPrivacyLink.
  ///
  /// In fr, this message translates to:
  /// **'politique de confidentialité'**
  String get authPrivacyLink;

  /// Titre de l'écran du code. La longueur vient du serveur, jamais d'une constante d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser code SMS de {count} chiffres'**
  String authOtpTitle(int count);

  /// No description provided for @authOtpValidate.
  ///
  /// In fr, this message translates to:
  /// **'Validation'**
  String get authOtpValidate;

  /// No description provided for @authOtpResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get authOtpResend;

  /// Remplace « renvoyer » une fois le délai écoulé : ce n'est plus le même geste.
  ///
  /// In fr, this message translates to:
  /// **'Demander un nouveau code'**
  String get authOtpRequestNew;

  /// No description provided for @authOtpExpiredShort.
  ///
  /// In fr, this message translates to:
  /// **'Code expiré'**
  String get authOtpExpiredShort;

  /// Compte à rebours, au-dessus d'une minute.
  ///
  /// In fr, this message translates to:
  /// **'il reste {minutes} min {seconds}'**
  String authOtpRemainingMinutes(int minutes, String seconds);

  /// Compte à rebours, dernière minute.
  ///
  /// In fr, this message translates to:
  /// **'il reste {seconds} s'**
  String authOtpRemainingSeconds(int seconds);

  /// No description provided for @secretCodeChooseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un code secret'**
  String get secretCodeChooseTitle;

  /// No description provided for @secretCodeConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirme ton code secret'**
  String get secretCodeConfirmTitle;

  /// Dit ce que le code engage : il reviendra à chaque fois.
  ///
  /// In fr, this message translates to:
  /// **'{count} chiffres, demandés à chaque ouverture'**
  String secretCodeChooseHelper(int count);

  /// No description provided for @secretCodeConfirmHelper.
  ///
  /// In fr, this message translates to:
  /// **'Saisis-le une seconde fois'**
  String get secretCodeConfirmHelper;

  /// No description provided for @secretCodeUnlockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton code secret'**
  String get secretCodeUnlockTitle;

  /// No description provided for @secretCodeUnlockHelper.
  ///
  /// In fr, this message translates to:
  /// **'Saisis tes chiffres'**
  String get secretCodeUnlockHelper;

  /// No description provided for @secretCodeWrong.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect'**
  String get secretCodeWrong;

  /// No description provided for @signInForgotten.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get signInForgotten;

  /// Traduit AUTH_OTP_EXPIRED. Dit la sortie, pas seulement le problème.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré. Demandes-en un nouveau.'**
  String get errorOtpExpired;

  /// No description provided for @errorOtpInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect.'**
  String get errorOtpInvalid;

  /// No description provided for @errorOtpTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais sur ce code. Demandes-en un nouveau.'**
  String get errorOtpTooManyAttempts;

  /// No description provided for @errorOtpTooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de codes demandés. Patiente quelques minutes.'**
  String get errorOtpTooManyRequests;

  /// No description provided for @errorPhoneAlreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro a déjà un compte. Connecte-toi.'**
  String get errorPhoneAlreadyRegistered;

  /// No description provided for @errorSecretCodeIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Code secret incorrect.'**
  String get errorSecretCodeIncorrect;

  /// Compte verrouillé. Distinct d'un code faux : le dire « incorrect » ferait s'acharner quelqu'un qui doit seulement attendre.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Attends quelques minutes avant de réessayer.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorAccountInactive.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est désactivé.'**
  String get errorAccountInactive;

  /// No description provided for @errorNoConnection.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion.'**
  String get errorNoConnection;

  /// No description provided for @errorVerificationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Vérification impossible pour l\'instant.'**
  String get errorVerificationUnavailable;

  /// No description provided for @errorSignInUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible pour l\'instant.'**
  String get errorSignInUnavailable;

  /// N'apparaît qu'en dehors de la production.
  ///
  /// In fr, this message translates to:
  /// **'Serveur simulé : aucun SMS ne part. Le numéro est prérempli, coche la politique et soumets.'**
  String get demoPhone;

  /// No description provided for @demoOtp.
  ///
  /// In fr, this message translates to:
  /// **'Serveur simulé : le code est {code}.'**
  String demoOtp(String code);

  /// No description provided for @demoSecretCodeSetup.
  ///
  /// In fr, this message translates to:
  /// **'Pour l\'essai : {code}. Un code répété (0000) ou suivi (1234) est refusé.'**
  String demoSecretCodeSetup(String code);

  /// No description provided for @demoSecretCodeUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Celui que tu as choisi à la création — {code} si tu as suivi la suggestion.'**
  String demoSecretCodeUnlock(String code);

  /// No description provided for @demoSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Serveur simulé : le code est celui que tu as posé à l\'inscription — {code} si tu as suivi la suggestion.'**
  String demoSignIn(String code);

  /// Titre de l'écran, et son nom dans le profil.
  ///
  /// In fr, this message translates to:
  /// **'Tes données'**
  String get privacyTitle;

  /// Texte à portée juridique : toute modification engage. À relire avec le même soin qu'un contrat.
  ///
  /// In fr, this message translates to:
  /// **'Trois choses qu\'Urim ne fera jamais. Elles sont tenues par le code, pas par une promesse.'**
  String get privacyIntro;

  /// No description provided for @privacyNoProfilingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune analyse de personne'**
  String get privacyNoProfilingTitle;

  /// No description provided for @privacyNoProfilingBody.
  ///
  /// In fr, this message translates to:
  /// **'Urim traite des textes. Il ne produit aucun jugement, score ou profil sur un membre, un fidèle ou un collaborateur.'**
  String get privacyNoProfilingBody;

  /// No description provided for @privacyOwnershipTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes préparations restent à toi'**
  String get privacyOwnershipTitle;

  /// No description provided for @privacyOwnershipBody.
  ///
  /// In fr, this message translates to:
  /// **'Elles ne sont lues par personne d\'autre — ni par ton église, ni par Dorea, ni par un responsable.'**
  String get privacyOwnershipBody;

  /// No description provided for @privacyNoResaleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est revendu'**
  String get privacyNoResaleTitle;

  /// No description provided for @privacyNoResaleBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partage à un tiers, aucune publicité, aucun entraînement de modèle sur ton contenu.'**
  String get privacyNoResaleBody;

  /// No description provided for @privacyRetainedLabel.
  ///
  /// In fr, this message translates to:
  /// **'CE QUI EST CONSERVÉ'**
  String get privacyRetainedLabel;

  /// No description provided for @privacyRetainedPhone.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro de téléphone, pour te reconnaître.'**
  String get privacyRetainedPhone;

  /// No description provided for @privacyRetainedWork.
  ///
  /// In fr, this message translates to:
  /// **'Tes préparations et enregistrements, jusqu\'à ce que tu les supprimes.'**
  String get privacyRetainedWork;

  /// No description provided for @privacyRetainedDevices.
  ///
  /// In fr, this message translates to:
  /// **'Les appareils sur lesquels tu t\'es connecté.'**
  String get privacyRetainedDevices;

  /// Mention légale. Le numéro de loi ne se traduit pas — il se remplace par la référence locale.
  ///
  /// In fr, this message translates to:
  /// **'Traitement soumis à la loi ivoirienne n° 2013-450 relative à la protection des données à caractère personnel. Tu peux supprimer ton compte et tout son contenu à tout moment.'**
  String get privacyLegalNotice;

  /// No description provided for @privacyAccept.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai lu et j\'accepte'**
  String get privacyAccept;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsSectionReading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get settingsSectionReading;

  /// No description provided for @settingsSectionScripture.
  ///
  /// In fr, this message translates to:
  /// **'Écriture'**
  String get settingsSectionScripture;

  /// No description provided for @settingsSectionOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors connexion'**
  String get settingsSectionOffline;

  /// No description provided for @settingsSectionReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get settingsSectionReminders;

  /// No description provided for @settingsSectionContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get settingsSectionContent;

  /// No description provided for @settingsTextSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSizeSmall.
  ///
  /// In fr, this message translates to:
  /// **'Petit'**
  String get settingsTextSizeSmall;

  /// No description provided for @settingsTextSizeNormal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get settingsTextSizeNormal;

  /// No description provided for @settingsTextSizeLarge.
  ///
  /// In fr, this message translates to:
  /// **'Grand'**
  String get settingsTextSizeLarge;

  /// Les quatre tailles de lecture. Elles quittent le domaine : une échelle est une donnée, son nom est un texte.
  ///
  /// In fr, this message translates to:
  /// **'Très grand'**
  String get settingsTextSizeExtraLarge;

  /// Aperçu de la taille choisie. Un verset connu, en Louis Segond — la seule traduction affichable sans licence.
  ///
  /// In fr, this message translates to:
  /// **'Ils persévéraient dans l\'enseignement des apôtres…'**
  String get settingsReadingSample;

  /// No description provided for @settingsDefaultVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version par défaut'**
  String get settingsDefaultVersion;

  /// No description provided for @settingsAlwaysShowReference.
  ///
  /// In fr, this message translates to:
  /// **'Toujours afficher la référence'**
  String get settingsAlwaysShowReference;

  /// No description provided for @settingsAlwaysShowReferenceHint.
  ///
  /// In fr, this message translates to:
  /// **'Livre, chapitre, verset et version sous chaque citation.'**
  String get settingsAlwaysShowReferenceHint;

  /// No description provided for @settingsBibleDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'Texte biblique téléchargé'**
  String get settingsBibleDownloaded;

  /// No description provided for @settingsBibleDownloadedPending.
  ///
  /// In fr, this message translates to:
  /// **'Disponible quand la source du texte biblique aura été choisie.'**
  String get settingsBibleDownloadedPending;

  /// No description provided for @settingsTranscribeOnDevice.
  ///
  /// In fr, this message translates to:
  /// **'Transcrire sur l\'appareil'**
  String get settingsTranscribeOnDevice;

  /// No description provided for @settingsTranscribeOnDevicePending.
  ///
  /// In fr, this message translates to:
  /// **'L\'audio ne quittera jamais le téléphone. Le moteur de transcription reste à retenir.'**
  String get settingsTranscribeOnDevicePending;

  /// No description provided for @settingsWifiOnly.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser en Wi-Fi seulement'**
  String get settingsWifiOnly;

  /// No description provided for @settingsWifiOnlyPending.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est encore synchronisé : tes préparations ne quittent pas cet appareil.'**
  String get settingsWifiOnlyPending;

  /// No description provided for @settingsReminderInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Préparation en cours'**
  String get settingsReminderInProgress;

  /// No description provided for @settingsReminderInProgressPending.
  ///
  /// In fr, this message translates to:
  /// **'Un rappel le samedi si un message n\'est pas terminé — dès qu\'une préparation saura dire qu\'elle ne l\'est pas.'**
  String get settingsReminderInProgressPending;

  /// No description provided for @settingsExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes préparations'**
  String get settingsExport;

  /// No description provided for @settingsExportPending.
  ///
  /// In fr, this message translates to:
  /// **'Texte ou PDF — l\'export arrive avec la synthèse.'**
  String get settingsExportPending;

  /// No description provided for @settingsStorageUsed.
  ///
  /// In fr, this message translates to:
  /// **'Espace utilisé'**
  String get settingsStorageUsed;

  /// No description provided for @settingsStorageUsedPending.
  ///
  /// In fr, this message translates to:
  /// **'Mesurable une fois le stockage des préparations choisi.'**
  String get settingsStorageUsedPending;

  /// Rappel de la politique, posé là où l'on s'interroge sur ce qui sort de l'appareil.
  ///
  /// In fr, this message translates to:
  /// **'Urim n\'utilise jamais tes préparations pour entraîner un modèle.'**
  String get settingsTrainingNotice;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Ce réglage n\'a pas pu être enregistré.'**
  String get settingsSaveFailed;

  /// No description provided for @settingsReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Les réglages n\'ont pas pu être lus.'**
  String get settingsReadFailed;

  /// No description provided for @translationPublicDomain.
  ///
  /// In fr, this message translates to:
  /// **'Domaine public'**
  String get translationPublicDomain;

  /// No description provided for @translationLicenceNotice.
  ///
  /// In fr, this message translates to:
  /// **'Les autres traductions demandent une licence : Urim ne les proposera qu\'une fois les droits obtenus.'**
  String get translationLicenceNotice;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// En-tête, quand aucun nom n'a été donné. On le dit plutôt que d'en inventer un à partir du numéro.
  ///
  /// In fr, this message translates to:
  /// **'Sans nom'**
  String get profileNoName;

  /// No description provided for @profileSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionChurches.
  ///
  /// In fr, this message translates to:
  /// **'Églises'**
  String get profileSectionChurches;

  /// No description provided for @profileSectionDevices.
  ///
  /// In fr, this message translates to:
  /// **'Appareils'**
  String get profileSectionDevices;

  /// No description provided for @profileDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get profileDisplayName;

  /// No description provided for @profileDisplayNameEmpty.
  ///
  /// In fr, this message translates to:
  /// **'À définir'**
  String get profileDisplayNameEmpty;

  /// Exemple de saisie dans la boîte de dialogue. Un nom ivoirien courant.
  ///
  /// In fr, this message translates to:
  /// **'Kouadio Aristide'**
  String get profileDisplayNameHint;

  /// No description provided for @profileDisplayNameExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom ne sort pas de l\'application : il sert à te reconnaître sur cet écran, et à former ton monogramme.'**
  String get profileDisplayNameExplanation;

  /// Annonce vocale de la silhouette qui remplace les initiales. Jamais affichée.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nom défini'**
  String get profileNoNameAvatar;

  /// No description provided for @profilePhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get profilePhone;

  /// No description provided for @profilePhonePending.
  ///
  /// In fr, this message translates to:
  /// **'Changer de numéro suppose un nouveau code par SMS.'**
  String get profilePhonePending;

  /// No description provided for @profileSecretCode.
  ///
  /// In fr, this message translates to:
  /// **'Code à 4 chiffres'**
  String get profileSecretCode;

  /// No description provided for @profileSecretCodeAction.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get profileSecretCodeAction;

  /// No description provided for @profileSecretCodePending.
  ///
  /// In fr, this message translates to:
  /// **'Le changement passera par l\'écran de création, encore réservé au premier accès.'**
  String get profileSecretCodePending;

  /// No description provided for @profileNoChurch.
  ///
  /// In fr, this message translates to:
  /// **'Aucune église rattachée'**
  String get profileNoChurch;

  /// No description provided for @profileNoChurchHint.
  ///
  /// In fr, this message translates to:
  /// **'Le rattachement viendra de l\'annuaire de la plateforme, pas d\'Urim.'**
  String get profileNoChurchHint;

  /// No description provided for @profileChurchRecognised.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro y est reconnu. Tes préparations n\'y sont pas visibles.'**
  String get profileChurchRecognised;

  /// Promesse d'étanchéité, pas une préférence d'affichage : le code doit la garantir.
  ///
  /// In fr, this message translates to:
  /// **'Une seule identité, plusieurs églises possibles. Ce que tu écris dans Urim ne traverse jamais vers elles.'**
  String get profileChurchesNote;

  /// No description provided for @profileDeviceCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil · actif maintenant'**
  String get profileDeviceCurrent;

  /// No description provided for @profileDeviceLastSeen.
  ///
  /// In fr, this message translates to:
  /// **'Dernière activité le {date}'**
  String profileDeviceLastSeen(String date);

  /// No description provided for @profileDeviceRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get profileDeviceRemove;

  /// No description provided for @profileDeviceRemoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {device} ?'**
  String profileDeviceRemoveTitle(String device);

  /// No description provided for @profileDeviceRemoveBody.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil devra se reconnecter par SMS pour ouvrir Urim.'**
  String get profileDeviceRemoveBody;

  /// No description provided for @profileReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le profil n\'a pas pu être lu.'**
  String get profileReadFailed;

  /// No description provided for @profileChangeRefused.
  ///
  /// In fr, this message translates to:
  /// **'Cette modification a été refusée.'**
  String get profileChangeRefused;

  /// No description provided for @profileChangeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Cette modification n\'a pas pu être enregistrée.'**
  String get profileChangeFailed;

  /// Anomalie, pas un état vide : l'écran n'est atteignable qu'une fois l'accès ouvert.
  ///
  /// In fr, this message translates to:
  /// **'Aucune session ouverte.'**
  String get profileNoSession;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @homeOpenTask.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir une tâche'**
  String get homeOpenTask;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien en cours.'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre une tâche : écris ce que tu veux dire, ou verse un enregistrement.'**
  String get homeEmptyBody;

  /// No description provided for @homeReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'La liste n\'a pas pu être lue.'**
  String get homeReadFailed;

  /// No description provided for @homeGroupThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'CETTE SEMAINE'**
  String get homeGroupThisWeek;

  /// Deux groupes seulement : ce qui est dans la semaine, et le reste. Un découpage plus fin n'apprendrait rien.
  ///
  /// In fr, this message translates to:
  /// **'PLUS TÔT'**
  String get homeGroupEarlier;

  /// No description provided for @homeActivityToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui, {time}'**
  String homeActivityToday(String time);

  /// No description provided for @homeActivityYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier, {time}'**
  String homeActivityYesterday(String time);

  /// No description provided for @homeCardMeta.
  ///
  /// In fr, this message translates to:
  /// **'· {activity}'**
  String homeCardMeta(String activity);

  /// Dernière activité, puis le dimanche visé.
  ///
  /// In fr, this message translates to:
  /// **'· {activity} · dimanche {service}'**
  String homeCardMetaWithService(String activity, String service);

  /// Urim a posé une question et attend. C'est ce qui met la préparation en tête de l'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Rend la main'**
  String get stateHandsBack;

  /// No description provided for @stateServed.
  ///
  /// In fr, this message translates to:
  /// **'Matière servie'**
  String get stateServed;

  /// No description provided for @stateFeedbackReady.
  ///
  /// In fr, this message translates to:
  /// **'Retour disponible'**
  String get stateFeedbackReady;

  /// No description provided for @stateRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refus motivé'**
  String get stateRefused;

  /// No description provided for @taskSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelle tâche ?'**
  String get taskSheetTitle;

  /// No description provided for @taskSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Deux travaux différents, pas deux façons d\'écrire.'**
  String get taskSheetSubtitle;

  /// No description provided for @taskWriteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préparer un message'**
  String get taskWriteTitle;

  /// No description provided for @taskWriteBody.
  ///
  /// In fr, this message translates to:
  /// **'Urim t\'accompagne question par question — l\'axe, le texte, les bornes — jusqu\'à ton squelette.'**
  String get taskWriteBody;

  /// No description provided for @taskTranscribeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transcrire une prédication'**
  String get taskTranscribeTitle;

  /// No description provided for @taskTranscribeBody.
  ///
  /// In fr, this message translates to:
  /// **'Mise en texte, puis une synthèse que tu valides avant qu\'elle ne soit lue à voix haute.'**
  String get taskTranscribeBody;

  /// No description provided for @taskTranscribePending.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur de transcription n\'est pas encore retenu. Un exemple transcrit est visible depuis l\'accueil.'**
  String get taskTranscribePending;

  /// No description provided for @newPreparationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle préparation'**
  String get newPreparationTitle;

  /// No description provided for @newPreparationIntro.
  ///
  /// In fr, this message translates to:
  /// **'Une référence, une phrase que tu as en tête, ou ce que tu veux dire. Écris comme ça vient.'**
  String get newPreparationIntro;

  /// Trois entrées possibles dans le même champ : une référence, une citation, une intention. C'est l'exemple qui le dit, pas un mode à cocher.
  ///
  /// In fr, this message translates to:
  /// **'Romains 8:15 — ou : que l\'amour fraternel continue — ou : je veux parler de la persévérance à des étudiants qui décrochent'**
  String get newPreparationHint;

  /// No description provided for @newPreparationDictate.
  ///
  /// In fr, this message translates to:
  /// **'Ou dicte — Urim te fera confirmer avant d\'aller plus loin. La dictée attend le moteur de reconnaissance.'**
  String get newPreparationDictate;

  /// No description provided for @newPreparationServiceSection.
  ///
  /// In fr, this message translates to:
  /// **'Pour quel dimanche'**
  String get newPreparationServiceSection;

  /// No description provided for @newPreparationServiceDate.
  ///
  /// In fr, this message translates to:
  /// **'Date du culte'**
  String get newPreparationServiceDate;

  /// No description provided for @newPreparationServiceDateEmpty.
  ///
  /// In fr, this message translates to:
  /// **'À définir'**
  String get newPreparationServiceDateEmpty;

  /// No description provided for @newPreparationServiceDateValue.
  ///
  /// In fr, this message translates to:
  /// **'dim. {date}'**
  String newPreparationServiceDateValue(String date);

  /// No description provided for @newPreparationSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace'**
  String get newPreparationSpace;

  /// No description provided for @newPreparationSpacePersonal.
  ///
  /// In fr, this message translates to:
  /// **'Personnel'**
  String get newPreparationSpacePersonal;

  /// No description provided for @newPreparationSpacePending.
  ///
  /// In fr, this message translates to:
  /// **'Le partage avec une église attend que le rattachement existe.'**
  String get newPreparationSpacePending;

  /// No description provided for @newPreparationNoModeNotice.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mode à choisir. Le moteur regarde si les mots que tu écris se suivent comme dans l\'Écriture — c\'est l\'ordre des mots qui décide, jamais le vocabulaire.'**
  String get newPreparationNoModeNotice;

  /// No description provided for @newPreparationOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la préparation'**
  String get newPreparationOpen;

  /// No description provided for @newPreparationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Cette préparation n\'a pas pu être ouverte.'**
  String get newPreparationFailed;

  /// No description provided for @preparationEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Pose ta première idée en bas de l\'écran.'**
  String get preparationEmpty;

  /// No description provided for @preparationLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible.'**
  String get preparationLoadFailed;

  /// No description provided for @preparationComposerHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris ta réponse, ou choisis…'**
  String get preparationComposerHint;

  /// No description provided for @preparationDictationSoon.
  ///
  /// In fr, this message translates to:
  /// **'Dictée — bientôt disponible'**
  String get preparationDictationSoon;

  /// No description provided for @preparationSend.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au fil'**
  String get preparationSend;

  /// Qui parle. Au-dessus de chaque tour d'Urim.
  ///
  /// In fr, this message translates to:
  /// **'URIM'**
  String get blockUrim;

  /// Replié par défaut. C'est ce qui distingue une proposition d'un oracle.
  ///
  /// In fr, this message translates to:
  /// **'Comment j\'en suis arrivé là'**
  String get blockTrace;

  /// No description provided for @blockScripture.
  ///
  /// In fr, this message translates to:
  /// **'ÉCRITURE'**
  String get blockScripture;

  /// No description provided for @blockRecognisedInQuote.
  ///
  /// In fr, this message translates to:
  /// **'RECONNU DANS LA CITATION · {at}'**
  String blockRecognisedInQuote(String at);

  /// No description provided for @blockSynthesis.
  ///
  /// In fr, this message translates to:
  /// **'SYNTHÈSE D\'URIM'**
  String get blockSynthesis;

  /// No description provided for @blockMoreLink.
  ///
  /// In fr, this message translates to:
  /// **'{label} →'**
  String blockMoreLink(String label);

  /// No description provided for @lociUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La liste des loci n\'est pas encore écrite. Les trois axes proposés viennent de ta phrase ; les sept autres attendent que le moteur existe.'**
  String get lociUnavailable;

  /// No description provided for @stanceSubject.
  ///
  /// In fr, this message translates to:
  /// **'Ce texte en fait son sujet'**
  String get stanceSubject;

  /// No description provided for @stanceSupports.
  ///
  /// In fr, this message translates to:
  /// **'Ce texte le soutient'**
  String get stanceSupports;

  /// Ce qui résiste à la lecture. Affiché au même rang que ce qui la porte — un moteur qui ne servirait que l'appui fabriquerait la preuve.
  ///
  /// In fr, this message translates to:
  /// **'Ce texte le complique'**
  String get stanceComplicates;

  /// No description provided for @transcriptionFallbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transcription'**
  String get transcriptionFallbackTitle;

  /// No description provided for @transcriptionOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get transcriptionOptions;

  /// No description provided for @transcriptionResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre l\'enregistrement'**
  String get transcriptionResume;

  /// No description provided for @transcriptionAudioDeleted.
  ///
  /// In fr, this message translates to:
  /// **'L\'audio a été effacé : la reprise repartira d\'une nouvelle capture.'**
  String get transcriptionAudioDeleted;

  /// No description provided for @transcriptionRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get transcriptionRecorded;

  /// No description provided for @transcriptionFragmentsAcknowledged.
  ///
  /// In fr, this message translates to:
  /// **'{count} fragments acquittés'**
  String transcriptionFragmentsAcknowledged(int count);

  /// No description provided for @transcriptionAudioDeletedOn.
  ///
  /// In fr, this message translates to:
  /// **'audio supprimé le {date}'**
  String transcriptionAudioDeletedOn(String date);

  /// No description provided for @transcriptionSectionFragments.
  ///
  /// In fr, this message translates to:
  /// **'Fragments'**
  String get transcriptionSectionFragments;

  /// No description provided for @transcriptionSectionConvoked.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu as convoqué'**
  String get transcriptionSectionConvoked;

  /// No description provided for @transcriptionAllAcknowledged.
  ///
  /// In fr, this message translates to:
  /// **'Tous les fragments sont acquittés.'**
  String get transcriptionAllAcknowledged;

  /// Le pluriel est porté par le format, plus par une fonction écrite à la main.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Un fragment attend le réseau. Il partira seul, dans l\'ordre.} other{{count} fragments attendent le réseau. Ils partiront seuls, dans l\'ordre.}}'**
  String transcriptionFragmentsPending(int count);

  /// No description provided for @transcriptionConvokedAnnounced.
  ///
  /// In fr, this message translates to:
  /// **'ANNONCÉ À VOIX HAUTE'**
  String get transcriptionConvokedAnnounced;

  /// No description provided for @transcriptionConvokedRecognised.
  ///
  /// In fr, this message translates to:
  /// **'RECONNU DANS LA CITATION'**
  String get transcriptionConvokedRecognised;

  /// No description provided for @transcriptionPlanned.
  ///
  /// In fr, this message translates to:
  /// **'{reference} — prévu dans ta préparation'**
  String transcriptionPlanned(String reference);

  /// No description provided for @transcriptionUnplanned.
  ///
  /// In fr, this message translates to:
  /// **'{reference} — non prévu'**
  String transcriptionUnplanned(String reference);

  /// No description provided for @transcriptionSpeakerNotice.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séparation de locuteurs. Les voix éloignées du micro sont écartées avant écriture, jamais enregistrées puis filtrées.'**
  String get transcriptionSpeakerNotice;

  /// No description provided for @transcriptionFixText.
  ///
  /// In fr, this message translates to:
  /// **'Corriger la transcription'**
  String get transcriptionFixText;

  /// No description provided for @transcriptionSeeSynthesis.
  ///
  /// In fr, this message translates to:
  /// **'Voir la synthèse'**
  String get transcriptionSeeSynthesis;

  /// No description provided for @transcriptionOpenPreparation.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la préparation'**
  String get transcriptionOpenPreparation;

  /// No description provided for @transcriptionNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette préparation n\'a pas d\'enregistrement transcrit.'**
  String get transcriptionNotFound;

  /// No description provided for @synthesisTitleDraft.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse — à valider'**
  String get synthesisTitleDraft;

  /// No description provided for @synthesisTitleValidated.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse — validée'**
  String get synthesisTitleValidated;

  /// No description provided for @synthesisNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette prédication n\'a pas de synthèse.'**
  String get synthesisNotFound;

  /// No description provided for @synthesisSealTitleDraft.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est encore parti.'**
  String get synthesisSealTitleDraft;

  /// Promesse tenue par le code : la lecture reste fermée tant que le drapeau est faux.
  ///
  /// In fr, this message translates to:
  /// **'Tant que tu n\'as pas validé, cette synthèse n\'existe que pour toi. Aucun membre ne la voit, aucune voix ne la lit.'**
  String get synthesisSealBodyDraft;

  /// No description provided for @synthesisSealTitleValidated.
  ///
  /// In fr, this message translates to:
  /// **'Validée par toi.'**
  String get synthesisSealTitleValidated;

  /// No description provided for @synthesisSealBodyValidated.
  ///
  /// In fr, this message translates to:
  /// **'Elle peut être lue à voix haute. Tu restes le seul à pouvoir la modifier.'**
  String get synthesisSealBodyValidated;

  /// No description provided for @synthesisSectionCapsules.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu\'Urim a retenu'**
  String get synthesisSectionCapsules;

  /// No description provided for @synthesisCapsuleLabel.
  ///
  /// In fr, this message translates to:
  /// **'CAPSULE {index} · DIT À {at}'**
  String synthesisCapsuleLabel(int index, String at);

  /// No description provided for @synthesisCapsuleSource.
  ///
  /// In fr, this message translates to:
  /// **'Voir où c\'est dit dans ta prédication'**
  String get synthesisCapsuleSource;

  /// No description provided for @synthesisSectionVerse.
  ///
  /// In fr, this message translates to:
  /// **'Le verset, non réécrit'**
  String get synthesisSectionVerse;

  /// No description provided for @synthesisModelNotice.
  ///
  /// In fr, this message translates to:
  /// **'Les capsules sont écrites par un modèle à partir de ta transcription. Les versets, eux, viennent de la Bible — jamais du modèle. Relis avant de valider.'**
  String get synthesisModelNotice;

  /// No description provided for @synthesisValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider cette synthèse'**
  String get synthesisValidate;

  /// No description provided for @synthesisValidated.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse validée'**
  String get synthesisValidated;

  /// No description provided for @synthesisValidatedToast.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse validée. Elle peut maintenant être lue.'**
  String get synthesisValidatedToast;

  /// No description provided for @synthesisSectionReadAloud.
  ///
  /// In fr, this message translates to:
  /// **'Lire à voix haute'**
  String get synthesisSectionReadAloud;

  /// No description provided for @synthesisReadAloudIntro.
  ///
  /// In fr, this message translates to:
  /// **'Pour ceux de l\'assemblée qui écouteront plutôt que de lire.'**
  String get synthesisReadAloudIntro;

  /// No description provided for @synthesisReadAloudLocked.
  ///
  /// In fr, this message translates to:
  /// **'Disponible une fois la synthèse validée.'**
  String get synthesisReadAloudLocked;

  /// No description provided for @synthesisReadAloudOpen.
  ///
  /// In fr, this message translates to:
  /// **'La lecture reprend la synthèse telle que tu l\'as validée.'**
  String get synthesisReadAloudOpen;

  /// No description provided for @synthesisVoiceComing.
  ///
  /// In fr, this message translates to:
  /// **'Lecture à venir'**
  String get synthesisVoiceComing;

  /// No description provided for @synthesisVoiceLocked.
  ///
  /// In fr, this message translates to:
  /// **'Disponible une fois la synthèse validée'**
  String get synthesisVoiceLocked;

  /// No description provided for @synthesisSpokenMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String synthesisSpokenMinutes(int minutes);

  /// No description provided for @synthesisSpokenMinutesSeconds.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min {seconds}'**
  String synthesisSpokenMinutesSeconds(int minutes, int seconds);

  /// Infobulle du menu contextuel, partout.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get options;

  /// Repère d'un bloc écrit aujourd'hui.
  ///
  /// In fr, this message translates to:
  /// **'AUJOURD\'HUI {time}'**
  String blockToday(String time);

  /// No description provided for @blockYesterday.
  ///
  /// In fr, this message translates to:
  /// **'HIER {time}'**
  String blockYesterday(String time);

  /// Au-delà d'hier, la date remplace le mot.
  ///
  /// In fr, this message translates to:
  /// **'{date} {time}'**
  String blockOnDate(String date, String time);

  /// Segment de l'enregistrement dont un point est tiré.
  ///
  /// In fr, this message translates to:
  /// **'  — {from} à {to}'**
  String synthesisPointRange(String from, String to);
}

class _AppTextDelegate extends LocalizationsDelegate<AppText> {
  const _AppTextDelegate();

  @override
  Future<AppText> load(Locale locale) {
    return SynchronousFuture<AppText>(lookupAppText(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppTextDelegate old) => false;
}

AppText lookupAppText(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppTextFr();
  }

  throw FlutterError(
    'AppText.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
