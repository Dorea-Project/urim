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

  /// Rangée destructrice du profil, promise par la politique.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get profileDeleteAccount;

  /// Titre du dialogue de suppression.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer votre compte ?'**
  String get profileDeleteAccountTitle;

  /// Dit ce qui part, et par quoi il faut passer pour le confirmer.
  ///
  /// In fr, this message translates to:
  /// **'Vos préparations, vos enregistrements et votre compte seront effacés — sur cet appareil comme sur le serveur. Rien n\'est récupérable.\n\nUn code va partir par SMS : il faut le saisir pour confirmer.'**
  String get profileDeleteAccountBody;

  /// Bouton qui déclenche l'envoi du SMS de suppression.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get profileDeleteAccountConfirm;

  /// Confirmation après une suppression réussie.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte et son contenu ont été supprimés.'**
  String get profileDeleteAccountDone;

  /// Refus du serveur au moment de demander le code de suppression.
  ///
  /// In fr, this message translates to:
  /// **'Le code n\'est pas parti. Votre compte est intact.'**
  String get profileDeleteAccountFailed;

  /// Ferme la session sur cet appareil, depuis le profil.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profileSignOut;

  /// Titre du dialogue de déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la session ?'**
  String get profileSignOutTitle;

  /// Dit ce que la déconnexion ne détruit pas, et ce qu'il faudra pour revenir.
  ///
  /// In fr, this message translates to:
  /// **'Vos préparations restent sur cet appareil. Il faudra votre code secret, ou un nouveau code par SMS si l\'appareil n\'est plus reconnu.'**
  String get profileSignOutBody;

  /// Option du dialogue : ferme aussi les sessions des autres appareils.
  ///
  /// In fr, this message translates to:
  /// **'Sur tous mes appareils'**
  String get profileSignOutEverywhere;

  /// Bouton de confirmation du dialogue de déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profileSignOutConfirm;

  /// L'effacement local a eu lieu ; l'appel distant a échoué.
  ///
  /// In fr, this message translates to:
  /// **'La session est fermée ici, mais le serveur n\'a pas répondu.'**
  String get profileSignOutFailed;

  /// Mention en bas de l'écran de lancement.
  ///
  /// In fr, this message translates to:
  /// **'Propulsé par Dorea'**
  String get splashPoweredBy;

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
  /// **'Impossible d\'enregistrer votre progression. La présentation réapparaîtra au prochain lancement.'**
  String get onboardingSaveFailed;

  /// Annonce vocale de la progression. Lu par les lecteurs d'écran, jamais affiché.
  ///
  /// In fr, this message translates to:
  /// **'Étape {position} sur {total}'**
  String onboardingStep(int position, int total);

  /// Titre de la première étape. Le retour à la ligne porte le rythme de la phrase.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez votre phrase.\nUrim cherche le texte dedans.'**
  String get onboardingWeighingTitle;

  /// No description provided for @onboardingWeighingBody.
  ///
  /// In fr, this message translates to:
  /// **'Une référence, une citation approximative, ou juste une intention. Vous n\'avez aucun mode à choisir — la porte regarde si les mots se suivent comme dans l\'Écriture.'**
  String get onboardingWeighingBody;

  /// No description provided for @onboardingHandbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Il s\'arrête\net te rend la main.'**
  String get onboardingHandbackTitle;

  /// No description provided for @onboardingHandbackBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque étage dit pourquoi il a fait ce qu\'il a fait. Quand il ne peut pas trancher seul, il vous pose la question au lieu de choisir à votre place.'**
  String get onboardingHandbackBody;

  /// No description provided for @onboardingResistanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Il te montre les textes qui te résistent.'**
  String get onboardingResistanceTitle;

  /// No description provided for @onboardingResistanceBody.
  ///
  /// In fr, this message translates to:
  /// **'Ceux qui ne vont pas dans le sens de votre lecture. C\'est le seul moyen de ne pas faire dire au texte ce qu\'on avait décidé d\'y trouver.'**
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
  /// **'Votre numéro'**
  String get authPhoneTitleSignIn;

  /// Titre du même écran, porte « inscription » : le numéro doit être joignable, un SMS y part.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro valide'**
  String get authPhoneTitleRegistration;

  /// Exemple de saisie, format ivoirien.
  ///
  /// In fr, this message translates to:
  /// **'07 47 76 9069'**
  String get authPhoneHint;

  /// Bascule vers la connexion depuis l’écran du numéro.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get authSwitchToSignIn;

  /// Bascule vers l’inscription depuis l’écran du numéro.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? En créer un'**
  String get authSwitchToRegistration;

  /// Sortie offerte quand le serveur répond que le numéro est déjà inscrit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authGoToSignIn;

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
  /// **'Choisissez un code secret'**
  String get secretCodeChooseTitle;

  /// No description provided for @secretCodeConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre code secret'**
  String get secretCodeConfirmTitle;

  /// Dit ce que le code engage : il reviendra à chaque fois.
  ///
  /// In fr, this message translates to:
  /// **'{count} chiffres, demandés à chaque ouverture'**
  String secretCodeChooseHelper(int count);

  /// No description provided for @secretCodeConfirmHelper.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez-le une seconde fois'**
  String get secretCodeConfirmHelper;

  /// No description provided for @secretCodeUnlockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre code secret'**
  String get secretCodeUnlockTitle;

  /// No description provided for @secretCodeUnlockHelper.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez vos chiffres'**
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
  /// **'Ce numéro a déjà un compte. Connectez-vous.'**
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
  /// **'Celui que vous avez choisi à la création — {code} si vous avez suivi la suggestion.'**
  String demoSecretCodeUnlock(String code);

  /// No description provided for @demoSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Serveur simulé : le code est celui que vous avez posé à l\'inscription — {code} si vous avez suivi la suggestion.'**
  String demoSignIn(String code);

  /// Titre de l'écran, et son nom dans le profil.
  ///
  /// In fr, this message translates to:
  /// **'Vos données'**
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
  /// **'Vos préparations restent les vôtres'**
  String get privacyOwnershipTitle;

  /// No description provided for @privacyOwnershipBody.
  ///
  /// In fr, this message translates to:
  /// **'Elles ne sont lues par personne d\'autre — ni par votre église, ni par Dorea, ni par un responsable.'**
  String get privacyOwnershipBody;

  /// No description provided for @privacyNoResaleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est revendu'**
  String get privacyNoResaleTitle;

  /// ⚠️ Corrigé le 29/08. La phrase disait « aucun partage à un tiers », qui se lit naturellement comme « mon texte ne quitte pas Dorea ». Or le texte des préparations part chez un fournisseur de modèle à chaque tour, pour résoudre les références et peser les axes. La promesse forte reste entière là où elle compte — rien n'est revendu, rien n'entraîne un modèle — mais elle cesse d'affirmer une étanchéité qui n'existe pas. Le prestataire n'est pas nommé : Dorea est responsable du traitement et endosse ce que ses sous-traitants font pour elle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publicité, aucun entraînement de modèle sur votre contenu. Les traitements techniques passent par des prestataires qui agissent pour Dorea, jamais pour leur propre compte.'**
  String get privacyNoResaleBody;

  /// No description provided for @privacyRetainedLabel.
  ///
  /// In fr, this message translates to:
  /// **'CE QUI EST CONSERVÉ'**
  String get privacyRetainedLabel;

  /// No description provided for @privacyRetainedPhone.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro de téléphone, pour vous reconnaître.'**
  String get privacyRetainedPhone;

  /// No description provided for @privacyRetainedWork.
  ///
  /// In fr, this message translates to:
  /// **'Vos préparations et enregistrements, jusqu\'à ce que vous les supprimiez.'**
  String get privacyRetainedWork;

  /// No description provided for @privacyRetainedDevices.
  ///
  /// In fr, this message translates to:
  /// **'Les appareils sur lesquels vous vous êtes connecté.'**
  String get privacyRetainedDevices;

  /// Mention légale. Le numéro de loi ne se traduit pas — il se remplace par la référence locale.
  ///
  /// In fr, this message translates to:
  /// **'Traitement soumis à la loi ivoirienne n° 2013-450 relative à la protection des données à caractère personnel. Vous pouvez supprimer votre compte et tout son contenu à tout moment.'**
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
  /// **'Rien n\'est encore synchronisé : vos préparations ne quittent pas cet appareil.'**
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

  /// Intitulé de l'export : ce que le pasteur avait écrit en ouvrant.
  ///
  /// In fr, this message translates to:
  /// **'Point de départ'**
  String get exportStartingPoint;

  /// Intitulé de l'export : le thème dégagé.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get exportTheme;

  /// Intitulé de l'export : les versets servis.
  ///
  /// In fr, this message translates to:
  /// **'Le texte'**
  String get exportVerses;

  /// Intitulé de l'export : les notes de contexte.
  ///
  /// In fr, this message translates to:
  /// **'Le contexte'**
  String get exportContext;

  /// Menu de la préparation : met son contenu dans le presse-papiers.
  ///
  /// In fr, this message translates to:
  /// **'Copier en texte'**
  String get preparationExport;

  /// Confirmation après copie dans le presse-papiers.
  ///
  /// In fr, this message translates to:
  /// **'Préparation copiée. Collez-la où vous voulez.'**
  String get preparationExportDone;

  /// No description provided for @settingsExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes préparations'**
  String get settingsExport;

  /// No description provided for @settingsExportPending.
  ///
  /// In fr, this message translates to:
  /// **'Une par une, depuis le menu d\'une préparation. L\'export de tout, et le PDF, restent à faire.'**
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
  /// **'Urim n\'utilise jamais vos préparations pour entraîner un modèle.'**
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

  /// Titre du dialogue lancé depuis le profil.
  ///
  /// In fr, this message translates to:
  /// **'Changer votre code secret ?'**
  String get profileSecretCodeChangeTitle;

  /// Dit ce que le changement entraîne, avant de le lancer.
  ///
  /// In fr, this message translates to:
  /// **'Un code vous sera envoyé par SMS au {phone}. Vos autres appareils devront se reconnecter : changer la serrure laisse rarement les anciennes clés en circulation.'**
  String profileSecretCodeChangeBody(String phone);

  /// Bouton qui déclenche l'envoi du SMS.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get profileSecretCodeChangeConfirm;

  /// L'appel au serveur a échoué avant même le SMS.
  ///
  /// In fr, this message translates to:
  /// **'Le code n\'a pas pu être envoyé.'**
  String get profileSecretCodeChangeFailed;

  /// No description provided for @profileSectionDevices.
  ///
  /// In fr, this message translates to:
  /// **'Appareils'**
  String get profileSectionDevices;

  /// Occupation des places d'appareils, à côté du titre de section.
  ///
  /// In fr, this message translates to:
  /// **'{count} sur {max}'**
  String profileDevicesCount(int count, int max);

  /// Affiché quand les deux places sont prises. Dit quoi faire, pas seulement que c'est plein.
  ///
  /// In fr, this message translates to:
  /// **'Deux appareils au maximum. Pour en lier un nouveau, retire d\'abord l\'un de ceux-ci — sinon la connexion y sera refusée.'**
  String get profileDevicesFull;

  /// Affiché quand il reste de la place.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Une place reste pour un autre appareil.} other{{count} places restent pour d\'autres appareils.}}'**
  String profileDevicesRoom(int count);

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
  /// **'Ce nom ne sort pas de l\'application : il sert à vous reconnaître sur cet écran, et à former votre monogramme.'**
  String get profileDisplayNameExplanation;

  /// Annonce vocale de la silhouette qui remplace les initiales. Jamais affichée.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nom défini'**
  String get profileNoNameAvatar;

  /// Titre de l’écran de recherche dans le corpus.
  ///
  /// In fr, this message translates to:
  /// **'Chercher'**
  String get searchTitle;

  /// Libellé de l’écran de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Un passage'**
  String get searchPassageTab;

  /// Libellé de l’écran de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Un mot de l’original'**
  String get searchWordTab;

  /// Exemple de référence, affiché dans le champ.
  ///
  /// In fr, this message translates to:
  /// **'Marc 10:46-52'**
  String get searchPassageHint;

  /// Exemple de lemme, affiché dans le champ.
  ///
  /// In fr, this message translates to:
  /// **'εἴδωλον'**
  String get searchWordHint;

  /// Libellé de l’écran de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Chercher'**
  String get searchAction;

  /// État vide de l’écran de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Rien pour l’instant. Écrivez une référence, ou un mot de l’original.'**
  String get searchEmpty;

  /// Quand le passage chevauche plusieurs unités relues.
  ///
  /// In fr, this message translates to:
  /// **'Les unités qui couvrent votre demande'**
  String get searchUnitsTitle;

  /// Qui a signé l’unité — la seule chose qui distingue un énoncé relu d’un énoncé jamais lu.
  ///
  /// In fr, this message translates to:
  /// **'Relu par {qui}'**
  String searchReviewedBy(String qui);

  /// Ce que porte un énoncé que personne n’a signé.
  ///
  /// In fr, this message translates to:
  /// **'Proposé par le modèle, non relu'**
  String get searchNotReviewed;

  /// Titre du bloc des pesées sur cet écran.
  ///
  /// In fr, this message translates to:
  /// **'Les dix pesées, absentes comprises'**
  String get searchBearingsTitle;

  /// Libellé de l’écran de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Ce que ce texte ne dit pas'**
  String get searchCaveatsTitle;

  /// Libellé de l’écran de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Le contexte'**
  String get searchContextTitle;

  /// Libellé de l’écran de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Ce que les manuscrits portent'**
  String get searchVariantsTitle;

  /// Le compte réel, indépendant de ce qui est montré.
  ///
  /// In fr, this message translates to:
  /// **'{total} occurrences dans le corpus'**
  String searchOccurrences(int total);

  /// Dit qu’on ne montre pas tout.
  ///
  /// In fr, this message translates to:
  /// **'Voici les {montrees} premières — un extrait présenté comme un tout ferait conclure d’un échantillon.'**
  String searchTruncated(int montrees);

  /// Ce qu’Urim répond quand la glose manque.
  ///
  /// In fr, this message translates to:
  /// **'Le corpus ne porte pas le sens de ce mot. Voici où il paraît — c’est ce que je peux soutenir.'**
  String get searchNoGloss;

  /// Titre de l’écran des textes d’appui.
  ///
  /// In fr, this message translates to:
  /// **'Ma chaîne de textes'**
  String get preparationSupportsTitle;

  /// Dit que l’ordre est le sien et que sa notation est comprise.
  ///
  /// In fr, this message translates to:
  /// **'Dans votre ordre, pas celui du canon : l’annonce avant l’accomplissement. Écrivez comme vous notez — « Hb 2v29 » se lit.'**
  String get preparationSupportsIntro;

  /// Libellé de l’écran de la chaîne de textes.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un texte'**
  String get preparationSupportsAdd;

  /// Bouton qui envoie la chaîne au contrôle de référence.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier et enregistrer'**
  String get preparationSupportsSave;

  /// Confirmation après envoi.
  ///
  /// In fr, this message translates to:
  /// **'Votre chaîne est enregistrée.'**
  String get preparationSupportsSaved;

  /// Exemple de notation, affiché dans le champ.
  ///
  /// In fr, this message translates to:
  /// **'Hb 2v29'**
  String get preparationSupportsHint;

  /// Titre de l’écran des diapositives.
  ///
  /// In fr, this message translates to:
  /// **'Ce que l’assemblée verra'**
  String get preparationDeckTitle;

  /// Dit que le contrôle précède le fichier.
  ///
  /// In fr, this message translates to:
  /// **'Chaque diapositive porte une référence et le texte tel qu’il montera à l’écran. Rien ne sort tant qu’un verset projeté n’est pas celui de la Bible.'**
  String get preparationDeckIntro;

  /// Libellé de l’écran des diapositives.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une diapositive'**
  String get preparationDeckAdd;

  /// Bouton qui envoie les diapositives au contrôle des citations.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre au contrôle'**
  String get preparationDeckSubmit;

  /// Libellé de l’écran des diapositives.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette diapositive'**
  String get preparationDeckRemove;

  /// Libellé de l’écran des diapositives.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get preparationDeckReference;

  /// Libellé de l’écran des diapositives.
  ///
  /// In fr, this message translates to:
  /// **'Texte projeté'**
  String get preparationDeckProjected;

  /// En-tête d’une diapositive, numérotée comme le serveur la numérote.
  ///
  /// In fr, this message translates to:
  /// **'Diapositive {rang}'**
  String preparationDeckSlide(int rang);

  /// Pendant la soumission et le rendu.
  ///
  /// In fr, this message translates to:
  /// **'Je prépare le document…'**
  String get preparationDocumentWorking;

  /// Dit où le fichier a été posé.
  ///
  /// In fr, this message translates to:
  /// **'Votre document est dans « {dossier} ».'**
  String preparationDocumentReady(String dossier);

  /// Titre du dossier de refus.
  ///
  /// In fr, this message translates to:
  /// **'Une citation ne correspond pas au corpus'**
  String get preparationDocumentRefusedTitle;

  /// Ce que le refus veut dire, sans accuser.
  ///
  /// In fr, this message translates to:
  /// **'Le document n’est pas produit tant qu’un verset projeté n’est pas celui de la Bible. Corrige, puis redemande.'**
  String get preparationDocumentRefusedBody;

  /// Titre de l’écran du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Mes points'**
  String get preparationPlanTitle;

  /// Ce que l’écran promet en haut, repris du document.
  ///
  /// In fr, this message translates to:
  /// **'Le document met en page ce que vous écrivez. Rien n’est imposé : une section vide reste vide.'**
  String get preparationPlanIntro;

  /// Bouton qui envoie le squelette au serveur.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get preparationPlanSave;

  /// Confirmation après envoi.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan est enregistré.'**
  String get preparationPlanSaved;

  /// Ouvre les sections que Braga ne nomme pas.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une section'**
  String get preparationPlanAdd;

  /// Dit le seuil du livrable, là où il se joue.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un point : c’est ce que le document exige avant de sortir.'**
  String get preparationPlanPointsHint;

  /// Entrée de menu qui ouvre ce que la préparation porte. Il ne se recolle plus à la fin de chaque échange.
  ///
  /// In fr, this message translates to:
  /// **'Le texte et le contexte'**
  String get preparationMaterialTitle;

  /// Ce que dit la bulle pendant que le moteur travaille. « Cherche » et non « écrit » : il ne rédige pas.
  ///
  /// In fr, this message translates to:
  /// **'Urim cherche…'**
  String get preparationThinking;

  /// Ce que le pasteur a écrit dans la conversation en désignant ce point. Gardé, rangé — et pas encore dans son plan.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 note écrite dans le fil} other{{count} notes écrites dans le fil}}'**
  String preparationPlanNotes(int count);

  /// Le seul geste qui fait entrer une note dans le document. Il ajoute à la fin du point, il ne remplace jamais.
  ///
  /// In fr, this message translates to:
  /// **'En faire mon point'**
  String get preparationPlanPromote;

  /// Confirmation après reprise. Dit où le texte est allé, et à qui il appartient maintenant.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à la fin de votre point. À vous de le retailler.'**
  String get preparationPlanPromoted;

  /// Demande une proposition sur un point déjà écrit. La seule prose qu’Urim produise.
  ///
  /// In fr, this message translates to:
  /// **'Faire articuler ce point'**
  String get preparationPlanArticulate;

  /// Titre de la feuille. « Propose » et non « écrit » : le texte reste à côté du plan.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu’Urim propose'**
  String get preparationPlanArticulateTitle;

  /// Intitulé de la phrase de transition, quand le modèle en propose une.
  ///
  /// In fr, this message translates to:
  /// **'Pour enchaîner'**
  String get preparationPlanArticulateTransition;

  /// Ce qui reste vrai quoi qu’il arrive : la proposition vit à côté du plan. La signature du modèle a été retirée le 22/08 — elle est gardée en base, pas montrée.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’entre dans votre document tant que vous ne l’avez pas repris.'**
  String get preparationPlanArticulateNotice;

  /// Le geste explicite qui fait entrer la proposition dans le champ. Jamais automatique.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre dans mon point'**
  String get preparationPlanArticulateTake;

  /// Confirmation après reprise. Dit où le texte est allé, et à qui il appartient maintenant.
  ///
  /// In fr, this message translates to:
  /// **'Repris à la suite de votre point. À vous de le retailler.'**
  String get preparationPlanArticulateTaken;

  /// Referme la feuille sans rien reprendre.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get preparationPlanArticulateClose;

  /// Aucun modèle branché, plafond atteint, ou point vide. État de production, jamais une erreur.
  ///
  /// In fr, this message translates to:
  /// **'Urim n’a pas de proposition ici. Votre point reste écrit, et vous le développez comme vous l’avez toujours fait.'**
  String get preparationPlanArticulateUnavailable;

  /// Le geste est demandé sur une section vide. On ne part pas au serveur pour l’apprendre.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez d’abord ce point : Urim articule ce que vous avez écrit, il ne l’écrit pas.'**
  String get preparationPlanArticulateEmpty;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get preparationSectionTitre;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Introduction'**
  String get preparationSectionIntroduction;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Proposition'**
  String get preparationSectionProposition;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Phrase interrogative'**
  String get preparationSectionPhraseInterrogative;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Phrase de transition'**
  String get preparationSectionPhraseDeTransition;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Les points'**
  String get preparationSectionDivisions;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Les sous-points'**
  String get preparationSectionSubdivisions;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Illustrations'**
  String get preparationSectionIllustrations;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get preparationSectionApplication;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Conclusion'**
  String get preparationSectionConclusion;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get preparationSectionObjectif;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Contexte du livre'**
  String get preparationSectionContexte;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Définitions'**
  String get preparationSectionDefinitions;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'NB'**
  String get preparationSectionNb;

  /// Nom d’une section du squelette homilétique.
  ///
  /// In fr, this message translates to:
  /// **'Témoignage'**
  String get preparationSectionTemoignage;

  /// Motif d'un geste que le contrat sert et que l'application ne sait pas encore ouvrir.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur accepte déjà vos points ; l\'écran pour les écrire n\'existe pas encore.'**
  String get preparationActionAVenir;

  /// No description provided for @profilePhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get profilePhone;

  /// No description provided for @profilePhoneChangeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer de numéro'**
  String get profilePhoneChangeTitle;

  /// No description provided for @profilePhoneChangeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le code partira sur le nouveau numéro : il faut l\'avoir en main.'**
  String get profilePhoneChangeBody;

  /// No description provided for @profilePhoneChangeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get profilePhoneChangeConfirm;

  /// No description provided for @profilePhoneChangeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le code n\'est pas parti. Votre numéro n\'a pas changé.'**
  String get profilePhoneChangeFailed;

  /// No description provided for @profilePhoneChangeDone.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro a été changé.'**
  String get profilePhoneChangeDone;

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
  /// **'Votre numéro y est reconnu. Vos préparations n\'y sont pas visibles.'**
  String get profileChurchRecognised;

  /// Promesse d'étanchéité, pas une préférence d'affichage : le code doit la garantir.
  ///
  /// In fr, this message translates to:
  /// **'Une seule identité, plusieurs églises possibles. Ce que vous écrivez dans Urim ne traverse jamais vers elles.'**
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

  /// Première entrée du tiroir. Ouvre un champ vide : la conversation en cours n'est pas perdue, elle reste dans l'historique juste en dessous.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle préparation'**
  String get drawerNewPreparation;

  /// En-tête de l'historique. Le fil a quitté l'accueil pour le tiroir le jour où l'accueil est devenu la conversation elle-même.
  ///
  /// In fr, this message translates to:
  /// **'PRÉPARATIONS'**
  String get drawerPreparations;

  /// En-tête du tiroir sur l'écran des prédications. Le tiroir suit le travail en cours : l'historique qu'il porte est celui de l'écran où l'on se trouve.
  ///
  /// In fr, this message translates to:
  /// **'PRÉDICATIONS'**
  String get drawerPreached;

  /// No description provided for @drawerEmptyPreached.
  ///
  /// In fr, this message translates to:
  /// **'Rien encore. Enregistrez votre prochain culte.'**
  String get drawerEmptyPreached;

  /// No description provided for @drawerProjects.
  ///
  /// In fr, this message translates to:
  /// **'Projets'**
  String get drawerProjects;

  /// L'entrée s'affiche inactive et dit ce qu'elle attend, plutôt que de disparaître (D13).
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get drawerProjectsPending;

  /// No description provided for @drawerEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien encore. Écrivez votre première phrase.'**
  String get drawerEmpty;

  /// Feuille ouverte par l'icône de bascule. Une icône seule n'explique pas où elle emmène — c'est le reproche fait à tout bouton qui bascule sans rien dire.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous basculer à…'**
  String get homeSwitchTitle;

  /// No description provided for @homeSwitchPrepare.
  ///
  /// In fr, this message translates to:
  /// **'Préparer un message'**
  String get homeSwitchPrepare;

  /// No description provided for @homeSwitchPrepareBody.
  ///
  /// In fr, this message translates to:
  /// **'Faites-vous assister pour accélérer votre préparation.'**
  String get homeSwitchPrepareBody;

  /// No description provided for @homeSwitchPreach.
  ///
  /// In fr, this message translates to:
  /// **'Mes prédications'**
  String get homeSwitchPreach;

  /// No description provided for @homeSwitchPreachBody.
  ///
  /// In fr, this message translates to:
  /// **'Donnez vie à votre prédication.'**
  String get homeSwitchPreachBody;

  /// Le geste, dans le menu de la préparation. Rien ne s'archive parce qu'une date est passée : c'est un geste du pasteur, jamais une déduction du calendrier.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai prêché celle-ci'**
  String get preachedMark;

  /// No description provided for @preachedMarkDone.
  ///
  /// In fr, this message translates to:
  /// **'Consignée comme prêchée le {date}.'**
  String preachedMarkDone(String date);

  /// No description provided for @archiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous avez prêché'**
  String get archiveTitle;

  /// No description provided for @archiveEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien de consigné. Marquez une préparation comme prêchée, ou consignez un message prêché ailleurs.'**
  String get archiveEmpty;

  /// Un sermon sans préparation — prêché ailleurs, ou avant Dorea. Sans lui, l'archive ne mesurerait que ce qui est passé par l'outil, ce qui n'est pas le ministère de quelqu'un.
  ///
  /// In fr, this message translates to:
  /// **'Consigner une prédication'**
  String get archiveRecordManual;

  /// La référence part dans la notation du pasteur : c'est le serveur qui la lit et la vérifie contre le corpus. On n'impose pas un format.
  ///
  /// In fr, this message translates to:
  /// **'Actes 1:1-14 — ou Hb 2v29, comme vous notez'**
  String get archiveRecordHint;

  /// No description provided for @archiveRecordDate.
  ///
  /// In fr, this message translates to:
  /// **'Quand l\'avez-vous prêchée ?'**
  String get archiveRecordDate;

  /// No description provided for @archiveRecordSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Consigner'**
  String get archiveRecordSubmit;

  /// No description provided for @archiveRecordDone.
  ///
  /// In fr, this message translates to:
  /// **'Prédication consignée.'**
  String get archiveRecordDone;

  /// Axe nul. Hors unité curée il n'y a aucun axe à retenir : on le nomme plutôt que de masquer la ligne.
  ///
  /// In fr, this message translates to:
  /// **'Non rangé'**
  String get archiveUnfiled;

  /// No description provided for @coverageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où vous êtes allé'**
  String get coverageTitle;

  /// No description provided for @coverageBooks.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 livre} other{{count} livres}}'**
  String coverageBooks(int count);

  /// Des lieux distincts. Prêcher deux fois le même texte n'élargit pas un canon.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 passage} other{{count} passages}}'**
  String coveragePassages(int count);

  /// Des événements. Deux assemblées ont entendu — ce nombre ne s'additionne jamais au précédent.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 prédication} other{{count} prédications}}'**
  String coveragePreachings(int count);

  /// No description provided for @coverageUntouched.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun livre sans sermon rangé} =1{1 livre sans sermon rangé} other{{count} livres sans sermon rangé}}'**
  String coverageUntouched(int count);

  /// ⚠️ Cet écran ne propose jamais de sermon. Un rayon vide se montre, il ne se comble pas — aucun score, aucune série, aucun pourcentage : ce serait mesurer la fidélité d'un pasteur.
  ///
  /// In fr, this message translates to:
  /// **'« Aucun sermon rangé ici » ne veut pas dire que vous ne l\'avez jamais prêché : un texte peut l\'avoir été sous une autre unité, ou sans axe retenu.'**
  String get coverageNotice;

  /// Le champ du bas de l'accueil. Deux entrées possibles dans le même champ — une référence, une intention — et c'est l'exemple qui le dit, pas un mode à cocher. Il a remplacé un bouton qui menait à un écran qui portait un champ : trois gestes pour une phrase.
  ///
  /// In fr, this message translates to:
  /// **'Une phrase, une référence, ou ce qui pèse cette semaine'**
  String get homeComposerHint;

  /// Infobulle de l'icône qui mène aux prédications. Elle nomme la destination, jamais la page où l'on se trouve — l'inverse fait reculer celui qui croyait avancer.
  ///
  /// In fr, this message translates to:
  /// **'Prédications'**
  String get homeTabPreach;

  /// Infobulle de l'icône du retour, sur la page des prédications.
  ///
  /// In fr, this message translates to:
  /// **'Préparations'**
  String get homeTabPrepare;

  /// Bouton du bas, page « prêcher ». Affiché inactif tant que le moteur de transcription n'est pas retenu (Q2, D13) : masquer sa place ferait croire que la page n'a pas de geste.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la prédication'**
  String get homeRecordSermon;

  /// Dit pourquoi l'application s'est ouverte sur les prédications plutôt que sur les préparations. Un automatisme qui ne se justifie pas passe pour une panne.
  ///
  /// In fr, this message translates to:
  /// **'Culte aujourd\'hui'**
  String get homeServiceToday;

  /// No description provided for @homeServiceTodayPending.
  ///
  /// In fr, this message translates to:
  /// **'rien n\'est encore capté'**
  String get homeServiceTodayPending;

  /// En-tête du corpus. Le compte est l'argument : c'est le nombre qui monte, semaine après semaine, dans la voix du pasteur.
  ///
  /// In fr, this message translates to:
  /// **'PRÊCHÉS · {count}'**
  String homeGroupPreached(int count);

  /// No description provided for @homePreachedEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune prédication captée.'**
  String get homePreachedEmptyTitle;

  /// No description provided for @homePreachedEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez le culte : la prédication s\'ajoutera ici, dans votre voix.'**
  String get homePreachedEmptyBody;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien en cours.'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez ce que vous voulez dire : une phrase, une référence, ou ce qui pèse cette semaine.'**
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

  /// Dernière activité, puis le culte visé. Le jour vient de la date — il était écrit « dimanche » en dur, et un pasteur ne prêche pas que le dimanche.
  ///
  /// In fr, this message translates to:
  /// **'· {activity} · {service}'**
  String homeCardMetaWithService(String activity, String service);

  /// Un geste noté sur l'appareil, pas encore parti. Le tour suivant est ce que le pipeline aurait répondu : on ne peut pas le fabriquer ici sans inventer une phrase d'Urim (D29). L'écran dit donc où en est l'envoi, et rien de plus.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Un geste attend le réseau} other{{count} gestes attendent le réseau}}'**
  String gesturePending(int count);

  /// Ce qui rassure sans mentir : le geste est garde, mais le tour n'existe pas encore.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur répondra dès que la connexion reviendra. Rien n\'est perdu.'**
  String get gesturePendingBody;

  /// `corpus_drifted` du serveur. Le tour n'est pas faux : le moteur rejoue contre un corpus qui a bouge — des unites relues, des pesees ajoutees. Ca se dit une fois, sobrement, et ca n'empeche rien.
  ///
  /// In fr, this message translates to:
  /// **'Le corpus a été relu depuis l\'ouverture — ce qu\'Urim dit ici n\'est plus mot pour mot ce qu\'il disait alors.'**
  String get corpusDrifted;

  /// Ce qui est affiché vient du magasin local, pas du serveur. Le moteur rejoue à chaque lecture : ce qui a été gardé hier soir est ce qu'il disait hier soir, et le faire passer pour une réponse d'aujourd'hui serait un mensonge découvert au pire moment.
  ///
  /// In fr, this message translates to:
  /// **'Gardé sur cet appareil · {when}'**
  String servedFromDevice(String when);

  /// Un homme a relu ce découpage et le signe. Sur 4 561 unités du corpus, une seule est dans ce cas au 22/08/2026.
  ///
  /// In fr, this message translates to:
  /// **'Découpage relu par {signature}'**
  String turnSignature(String signature);

  /// Le cas de 4 552 unités sur 4 561. On ne nomme plus le modèle — le pasteur n’a que faire de « ia-mistral » — mais on dit ce que ça change : personne ne l’a vérifié. Sans cette ligne, une structure générée arriverait à l’écran exactement comme une structure relue par un bibliste.
  ///
  /// In fr, this message translates to:
  /// **'Découpage proposé par l’IA, non relu'**
  String get turnSignatureMachine;

  /// Le decor ambiant replie. Le nombre est dedans exprès : replier n'est pas cacher, et le pasteur doit savoir ce qu'il n'a pas sous les yeux.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ce que le texte porte — 1 axe} other{Ce que le texte porte — {count} axes}}'**
  String turnFoldedBearings(int count);

  /// Idem. Les refuses voyagent toujours avec les faisables, replies sous ce nombre.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Les plans que ce texte tient — 1} other{Les plans que ce texte tient — {count}}}'**
  String turnFoldedFeasibility(int count);

  /// No description provided for @turnFoldedChips.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 autre proposition} other{{count} autres propositions}}'**
  String turnFoldedChips(int count);

  /// No description provided for @turnFoldedUnits.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 texte relu} other{{count} textes relus}}'**
  String turnFoldedUnits(int count);

  /// Les versets servis par le corpus. Aucun bloc du tour ne les porte : le pasteur travaillait sur un passage qu'il ne voyait nulle part.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Le texte — 1 verset} other{Le texte — {count} versets}}'**
  String studyText(int count);

  /// Calcule a l'ouverture et jamais montre. Absent du corpus sur certaines unites : on n'affiche alors rien plutot qu'une section vide.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Le contexte} other{Le contexte — {count} notes}}'**
  String studyContext(int count);

  /// No description provided for @studyContextLiterary.
  ///
  /// In fr, this message translates to:
  /// **'Littéraire'**
  String get studyContextLiterary;

  /// `kind` du corpus, nomme en francais a un seul endroit.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get studyContextHistorical;

  /// Un thème, jamais un titre — le titre, c'est la voix du pasteur.
  ///
  /// In fr, this message translates to:
  /// **'THÈME'**
  String get turnThemeLabel;

  /// Le geste existe de bout en bout côté serveur, et rien ne le disait. Une porte ouverte que personne ne voit est pire qu'une porte fermée : elle a l'air d'une fonctionnalité manquante.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un axe pour prêcher ce texte dessus.'**
  String get turnBearingsSwitchable;

  /// `dominant` du moteur : l'axe est ce dont le texte parle.
  ///
  /// In fr, this message translates to:
  /// **'En fait son sujet'**
  String get strengthDominant;

  /// `porte` du moteur.
  ///
  /// In fr, this message translates to:
  /// **'Le soutient'**
  String get strengthSupports;

  /// `resiste` du moteur. Affiché au même rang que le reste : c'est la seule mécanique anti-proof-texting du produit.
  ///
  /// In fr, this message translates to:
  /// **'Lui résiste'**
  String get strengthResists;

  /// `absent` du moteur : rien ne se construit dessus.
  ///
  /// In fr, this message translates to:
  /// **'Absent'**
  String get strengthAbsent;

  /// `await_decision` du moteur : Urim s'est arrêté sur une question et attend. C'est ce qui met la préparation en tête de l'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Rend la main'**
  String get stateHandsBack;

  /// `continue` du moteur : il est allé au bout du tour sans rien demander.
  ///
  /// In fr, this message translates to:
  /// **'Matière servie'**
  String get stateServed;

  /// `degrade` du moteur : il a servi moins qu'il ne voulait, et l'annonce. À ne pas confondre avec un refus — il y a de la matière, incomplète.
  ///
  /// In fr, this message translates to:
  /// **'Réponse partielle'**
  String get stateDegraded;

  /// `refuse` du moteur : il n'a pas voulu travailler, et dit pourquoi.
  ///
  /// In fr, this message translates to:
  /// **'Refus motivé'**
  String get stateRefused;

  /// Une prédication déjà prêchée dont Urim a quelque chose à dire. Ne vient pas du moteur de préparation mais de la branche transcription, qui reste une maquette.
  ///
  /// In fr, this message translates to:
  /// **'Retour disponible'**
  String get stateFeedbackReady;

  /// No description provided for @homeRecordStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter l\'enregistrement'**
  String get homeRecordStop;

  /// Le bandeau qui traverse les deux pages. Il ne disparaît pas quand on change de travail : un pasteur qui va chercher son plan pendant qu'il prêche croirait avoir coupé le micro.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement'**
  String get homeCaptureRunning;

  /// No description provided for @homeCaptureStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get homeCaptureStop;

  /// A3.2 — onglet 1. Vide tant que le modèle embarqué n'est pas retenu (D52), et il le dit.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui a été dit'**
  String get sermonTabSaid;

  /// A3.3 — onglet 2.
  ///
  /// In fr, this message translates to:
  /// **'La synthèse'**
  String get sermonTabSynthesis;

  /// A3.4 — onglet 3 : ce qu'on porte à la voix.
  ///
  /// In fr, this message translates to:
  /// **'La sortie'**
  String get sermonTabOutput;

  /// A2 — ce qui est POSÉ sur le disque, atomiquement, et survit à une application tuée. Pas « enregistré » : écrit.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun fragment écrit} =1{1 fragment écrit} other{{count} fragments écrits}}'**
  String homeCaptureFragments(int count);

  /// B1.11 — la file monte quand le réseau revient. Rien n'est perdu en attendant.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fragment attend le réseau} other{{count} fragments attendent le réseau}}'**
  String homeCapturePending(int count);

  /// 🔴 A2.4 — la promesse manquante. La capture est le PREMIER objet d'Urim qui ne se synchronise pas, et rien ne le disait. À formuler AVANT le premier pilote : le jour où un pasteur enregistre sur son téléphone et cherche la relecture sur sa tablette, il ne doit pas découvrir le vide.
  ///
  /// In fr, this message translates to:
  /// **'Cet enregistrement reste sur ce téléphone. Il ne se retrouvera pas sur une autre tablette, même connectée au même compte.'**
  String get homeCaptureStaysHere;

  /// Confirmation à l'arrêt. Dit la durée pour que le pasteur sache que quelque chose a bien été écrit.
  ///
  /// In fr, this message translates to:
  /// **'Prédication captée · {duree}'**
  String homeCaptureSaved(String duree);

  /// No description provided for @homeCaptureMicRefused.
  ///
  /// In fr, this message translates to:
  /// **'Urim a besoin du micro pour enregistrer votre prédication. Autorisez-le dans les réglages de l\'appareil.'**
  String get homeCaptureMicRefused;

  /// No description provided for @homeCaptureNoMicrophone.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil n\'a pas de micro utilisable.'**
  String get homeCaptureNoMicrophone;

  /// No description provided for @homeCaptureStorageFull.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a plus de place pour l\'audio. Libérez quelques centaines de mégaoctets.'**
  String get homeCaptureStorageFull;

  /// Quatre refus, quatre phrases : « refusé » tout court laisse le pasteur devant un bouton mort sans savoir quoi faire.
  ///
  /// In fr, this message translates to:
  /// **'L\'enregistrement n\'a pas pu commencer. Réessayez.'**
  String get homeCaptureFailed;

  /// L'enregistrement s'est arrêté seul — application tuée, batterie vide. La capture apparaît quand même : la faire disparaître serait le pire des silences.
  ///
  /// In fr, this message translates to:
  /// **'Interrompue'**
  String get homeCaptureInterrupted;

  /// Le compte à rebours des sept jours, porté par la carte. La disparition ne doit surprendre personne.
  ///
  /// In fr, this message translates to:
  /// **'audio effacé dans {jours} j'**
  String homeCaptureAudioLeft(int jours);

  /// No description provided for @homeCaptureAudioToday.
  ///
  /// In fr, this message translates to:
  /// **'audio effacé aujourd\'hui'**
  String get homeCaptureAudioToday;

  /// L'étape 1 s'arrête à la capture : le transcript attend le moteur (Q2). Le dire évite de laisser croire qu'il y a un texte quelque part.
  ///
  /// In fr, this message translates to:
  /// **'sur cet appareil, pas encore transcrite'**
  String get homeCaptureNotSent;

  /// No description provided for @captureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Culte du {date}'**
  String captureTitle(String date);

  /// No description provided for @captureSectionState.
  ///
  /// In fr, this message translates to:
  /// **'CE QUI A ÉTÉ CAPTÉ'**
  String get captureSectionState;

  /// No description provided for @captureDuration.
  ///
  /// In fr, this message translates to:
  /// **'{duration} enregistrées'**
  String captureDuration(String duration);

  /// No description provided for @captureFragments.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fragment de trente secondes} other{{count} fragments de trente secondes}}'**
  String captureFragments(int count);

  /// No description provided for @captureUploadAllSent.
  ///
  /// In fr, this message translates to:
  /// **'Tout est arrivé au serveur.'**
  String get captureUploadAllSent;

  /// L'attente n'est pas une panne : les fragments restent sept jours sur l'appareil et la file reprend là où elle s'est arrêtée.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fragment attend de partir} other{{count} fragments attendent de partir}}'**
  String captureUploadPending(int count);

  /// 🔴 Le silence le plus coûteux du chantier : sans ce message, le compteur monte et rien ne dit pourquoi rien ne part.
  ///
  /// In fr, this message translates to:
  /// **'Cette capture attend de savoir devant quelle assemblée elle a été prêchée. Sans elle, elle ne peut pas partir.'**
  String get captureUploadNoChurch;

  /// No description provided for @captureInterrupted.
  ///
  /// In fr, this message translates to:
  /// **'L\'enregistrement s\'est arrêté tout seul. Ce qui a été capté avant est intact.'**
  String get captureInterrupted;

  /// No description provided for @capturePurgeIn.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{L\'audio est effacé aujourd\'hui} =1{L\'audio est effacé demain} other{L\'audio est effacé dans {days} jours}}'**
  String capturePurgeIn(int days);

  /// No description provided for @transcribeOfferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lire ce culte'**
  String get transcribeOfferTitle;

  /// 🔴 Le téléchargement se demande, il ne se déclenche pas. L'application promet que l'audio ne quitte pas le téléphone ; faire descendre 31 Mo n'est pas rompre cette promesse, mais c'est du réseau que le pasteur doit voir venir.
  ///
  /// In fr, this message translates to:
  /// **'Urim peut transcrire cet enregistrement sur ce téléphone. Il doit d\'abord télécharger son modèle : {megaoctets} Mo, une seule fois. L\'audio, lui, ne partira pas.'**
  String transcribeOfferBody(int megaoctets);

  /// Le sélecteur de gabarit montre le poids parce que le poids décide : sur un forfait à Abidjan, 466 Mo contre 75 n'est pas un détail d'ergonomie.
  ///
  /// In fr, this message translates to:
  /// **'{gabarit} · {megaoctets} Mo'**
  String transcribeModelChip(String gabarit, int megaoctets);

  /// No description provided for @transcribeDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le modèle'**
  String get transcribeDownload;

  /// ⚠️ En mégaoctets, jamais en pourcentage seul : « 60 % » ne dit pas s'il reste 5 Mo à descendre ou 150, et c'est cette différence qui décide de continuer ou d'attendre le wifi.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement… {received} Mo sur {total}'**
  String transcribeDownloading(int received, int total);

  /// No description provided for @transcribeStart.
  ///
  /// In fr, this message translates to:
  /// **'Transcrire ce culte'**
  String get transcribeStart;

  /// No description provided for @transcribeResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la transcription'**
  String get transcribeResume;

  /// No description provided for @transcribeRunning.
  ///
  /// In fr, this message translates to:
  /// **'{done} fragment sur {total}'**
  String transcribeRunning(int done, int total);

  /// No description provided for @transcribeSectionText.
  ///
  /// In fr, this message translates to:
  /// **'CE QUI A ÉTÉ DIT'**
  String get transcribeSectionText;

  /// D58 — un texte qui se corrige sous les yeux est pire qu'un texte qui tarde.
  ///
  /// In fr, this message translates to:
  /// **'Le texte s\'ajoute par blocs et ne se corrige pas tout seul : ce que vous avez lu ne changera pas.'**
  String get transcribeAdditive;

  /// No description provided for @transcribeFailedModel.
  ///
  /// In fr, this message translates to:
  /// **'Le téléchargement n\'a pas abouti. Réessayez quand le réseau sera meilleur — rien n\'est perdu.'**
  String get transcribeFailedModel;

  /// No description provided for @transcribeFailedAudio.
  ///
  /// In fr, this message translates to:
  /// **'Cet enregistrement n\'est pas lisible.'**
  String get transcribeFailedAudio;

  /// No description provided for @transcribeFailedEngine.
  ///
  /// In fr, this message translates to:
  /// **'La transcription s\'est arrêtée. Ce qui était déjà lu est gardé.'**
  String get transcribeFailedEngine;

  /// D52 — « Whisper » nomme une famille, pas une décision finie. Dire ce qu'on attend vaut mieux qu'un écran vide (D13).
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'a encore été transcrit. Le moteur qui lira cet audio n\'est pas retenu : son gabarit se décide en le mesurant sur un vrai téléphone, pas en le décrétant.'**
  String get captureSaidPending;

  /// No description provided for @captureSynthesisPending.
  ///
  /// In fr, this message translates to:
  /// **'La synthèse résume ce qui a été dit. Elle attend donc la transcription — résumer un enregistrement qu\'on n\'a pas lu serait inventer.'**
  String get captureSynthesisPending;

  /// No description provided for @captureOutputPending.
  ///
  /// In fr, this message translates to:
  /// **'La lecture à voix haute et l\'interprétation partent d\'une synthèse validée. Elles attendent celle-ci.'**
  String get captureOutputPending;

  /// No description provided for @captureListenResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get captureListenResume;

  /// No description provided for @captureListenPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get captureListenPause;

  /// Une date n'est pas un nom : au bout de quatre dimanches, « dim. 6 septembre » ne dit plus rien.
  ///
  /// In fr, this message translates to:
  /// **'Nommer ce culte'**
  String get captureNameIt;

  /// No description provided for @captureNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle naissance, Actes 2…'**
  String get captureNameHint;

  /// No description provided for @captureNameSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get captureNameSave;

  /// No description provided for @captureNameCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get captureNameCancel;

  /// No description provided for @captureNameRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le nom'**
  String get captureNameRemove;

  /// Le repli quand rien n'a été nommé — vrai, mais muet.
  ///
  /// In fr, this message translates to:
  /// **'Culte du {date}'**
  String captureUnnamed(String date);

  /// Le seul geste que la branche « prêcher » offre aujourd'hui : le pasteur entend ce qu'il a dit, sans attendre aucun moteur.
  ///
  /// In fr, this message translates to:
  /// **'Réécouter ce culte'**
  String get captureListen;

  /// No description provided for @captureListenStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get captureListenStop;

  /// No description provided for @captureListenPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de la lecture…'**
  String get captureListenPreparing;

  /// No description provided for @captureListenEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a rien à réécouter : aucun fragment n\'a été écrit.'**
  String get captureListenEmpty;

  /// No description provided for @captureListenFailed.
  ///
  /// In fr, this message translates to:
  /// **'La lecture n\'a pas pu commencer.'**
  String get captureListenFailed;

  /// No description provided for @captureLocalOnly.
  ///
  /// In fr, this message translates to:
  /// **'Cet enregistrement reste sur ce téléphone. Il ne se retrouvera pas sur une autre tablette, même connectée au même compte.'**
  String get captureLocalOnly;

  /// Sous le bouton d'enregistrement inactif. Dit ce qu'il attend plutôt que de disparaître (D13). Les libellés de l'ancienne feuille « quelle tâche ? » sont partis avec elle : la bascule du haut pose la même question sans modale.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur de transcription n\'est pas encore retenu. Les prédications déjà transcrites restent lisibles ici.'**
  String get homeRecordPending;

  /// No description provided for @newPreparationDictateListening.
  ///
  /// In fr, this message translates to:
  /// **'Urim vous écoute. Appuyez pour arrêter.'**
  String get newPreparationDictateListening;

  /// No description provided for @newPreparationDictateStart.
  ///
  /// In fr, this message translates to:
  /// **'Dicter'**
  String get newPreparationDictateStart;

  /// No description provided for @newPreparationDictateStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la dictée'**
  String get newPreparationDictateStop;

  /// No description provided for @newPreparationDictateNoEngine.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil n\'a pas de reconnaissance vocale. Écrivez votre phrase.'**
  String get newPreparationDictateNoEngine;

  /// No description provided for @newPreparationDictateMicRefused.
  ///
  /// In fr, this message translates to:
  /// **'Urim a besoin du micro pour écrire ce que vous dites. Autorisez-le dans les réglages de l\'appareil.'**
  String get newPreparationDictateMicRefused;

  /// No description provided for @newPreparationDictateFailed.
  ///
  /// In fr, this message translates to:
  /// **'La dictée s\'est arrêtée. Réessayez, ou écrivez votre phrase.'**
  String get newPreparationDictateFailed;

  /// No description provided for @newPreparationServiceDate.
  ///
  /// In fr, this message translates to:
  /// **'Date du culte'**
  String get newPreparationServiceDate;

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

  /// La reponse a l'etape 5 de Q4. Ouvrir est le seul geste qui ne peut pas attendre le reseau : lire une phrase demande le corpus, et il n'est pas sur l'appareil. Dit la raison, et que le brouillon garde la phrase (D32) — sans quoi le pasteur croirait avoir perdu ce qu'il venait d'ecrire.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir demande le réseau : Urim consulte les textes pour lire votre phrase. Elle est gardée — vous la retrouverez ici.'**
  String get newPreparationNeedsNetwork;

  /// No description provided for @preparationEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Posez votre première idée en bas de l\'écran.'**
  String get preparationEmpty;

  /// No description provided for @preparationLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible.'**
  String get preparationLoadFailed;

  /// No description provided for @preparationComposerHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez votre réponse, ou choisissez…'**
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
  /// **'La liste des loci n\'est pas encore écrite. Les trois axes proposés viennent de votre phrase ; les sept autres attendent que le moteur existe.'**
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
  /// **'Ce que vous avez convoqué'**
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
  /// **'{reference} — prévu dans votre préparation'**
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
  /// **'Tant que vous n\'avez pas validé, cette synthèse n\'existe que pour vous. Aucun membre ne la voit, aucune voix ne la lit.'**
  String get synthesisSealBodyDraft;

  /// No description provided for @synthesisSealTitleValidated.
  ///
  /// In fr, this message translates to:
  /// **'Validée par vous.'**
  String get synthesisSealTitleValidated;

  /// No description provided for @synthesisSealBodyValidated.
  ///
  /// In fr, this message translates to:
  /// **'Elle peut être lue à voix haute. Vous restez le seul à pouvoir la modifier.'**
  String get synthesisSealBodyValidated;

  /// No description provided for @synthesisSectionCapsules.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu\'Urim a retenu'**
  String get synthesisSectionCapsules;

  /// Une capsule née d'une préparation n'a aucun instant à pointer : le plan n'a pas encore été prêché. Afficher « DIT À 0:00 » ferait mentir l'écran poliment.
  ///
  /// In fr, this message translates to:
  /// **'CAPSULE {index}'**
  String synthesisCapsuleLabelPlain(int index);

  /// No description provided for @synthesisCapsuleLabel.
  ///
  /// In fr, this message translates to:
  /// **'CAPSULE {index} · DIT À {at}'**
  String synthesisCapsuleLabel(int index, String at);

  /// No description provided for @synthesisCapsuleSource.
  ///
  /// In fr, this message translates to:
  /// **'Voir où c\'est dit dans votre prédication'**
  String get synthesisCapsuleSource;

  /// No description provided for @synthesisSectionVerse.
  ///
  /// In fr, this message translates to:
  /// **'Le verset, non réécrit'**
  String get synthesisSectionVerse;

  /// No description provided for @synthesisModelNotice.
  ///
  /// In fr, this message translates to:
  /// **'Les capsules sont écrites par un modèle à partir de votre transcription. Les versets, eux, viennent de la Bible — jamais du modèle. Relisez avant de valider.'**
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
  /// **'La lecture reprend la synthèse telle que vous l\'avez validée.'**
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

  /// No description provided for @synthesisVoiceRead.
  ///
  /// In fr, this message translates to:
  /// **'Écouter la synthèse'**
  String get synthesisVoiceRead;

  /// No description provided for @synthesisVoiceStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la lecture'**
  String get synthesisVoiceStop;

  /// Le refus le plus fréquent, et le seul que le pasteur peut lever lui-même — on lui dit donc où aller.
  ///
  /// In fr, this message translates to:
  /// **'Cette voix n\'est pas installée sur ce téléphone. Elle se télécharge depuis les réglages, dans « Synthèse vocale ».'**
  String get synthesisVoiceNoLanguage;

  /// No description provided for @synthesisVoiceNoEngine.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone n\'a pas de synthèse vocale.'**
  String get synthesisVoiceNoEngine;

  /// No description provided for @synthesisVoiceFailed.
  ///
  /// In fr, this message translates to:
  /// **'La lecture n\'a pas pu commencer.'**
  String get synthesisVoiceFailed;

  /// La garde, dite plutôt que subie : rien ne sort d'une synthèse que le pasteur n'a pas signée.
  ///
  /// In fr, this message translates to:
  /// **'Validez la synthèse avant de la faire lire.'**
  String get synthesisVoiceNotValidated;

  /// No description provided for @synthesisVoiceEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get synthesisVoiceEnglish;

  /// No description provided for @voiceFrenchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get voiceFrenchLabel;

  /// Ce que vaut cette lecture. « Sur cet appareil » n'est pas décoratif : c'est la promesse que rien ne sort pour la produire.
  ///
  /// In fr, this message translates to:
  /// **'Voix de synthèse, sur cet appareil'**
  String get voiceFrenchNote;

  /// No description provided for @voiceEnglishNote.
  ///
  /// In fr, this message translates to:
  /// **'Voix de synthèse, sur cet appareil'**
  String get voiceEnglishNote;

  /// No description provided for @voiceOwnLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre propre voix'**
  String get voiceOwnLabel;

  /// La seule des quatre qui ne demande aucun modèle, et la plus juste : c'est la voix que l'assemblée reconnaît (D60).
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez-vous disant la synthèse dans la langue de votre assemblée — rien à traduire, rien à générer'**
  String get voiceOwnNote;

  /// No description provided for @voiceMalinkeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Malinké'**
  String get voiceMalinkeLabel;

  /// D63 : la proposition dit ce que Dorea sait faire, jamais ce que le pasteur est censé parler. Une langue est une identité ; présumer serait pire que ne rien proposer.
  ///
  /// In fr, this message translates to:
  /// **'Interprétée par l\'équipe Dorea — la langue que nous savons tenir aujourd\'hui'**
  String get voiceMalinkeNote;

  /// Le geste de la piste : le pasteur dit lui-même sa synthèse dans la langue de son assemblée.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer votre voix'**
  String get trackRecordStart;

  /// No description provided for @trackRecordStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter l\'enregistrement'**
  String get trackRecordStop;

  /// No description provided for @trackListen.
  ///
  /// In fr, this message translates to:
  /// **'Écouter votre piste'**
  String get trackListen;

  /// No description provided for @trackListenStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get trackListenStop;

  /// No description provided for @trackRedo.
  ///
  /// In fr, this message translates to:
  /// **'Refaire'**
  String get trackRedo;

  /// No description provided for @trackRedoHint.
  ///
  /// In fr, this message translates to:
  /// **'Un nouvel enregistrement remplace celui-ci.'**
  String get trackRedoHint;

  /// No description provided for @trackLanguageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dans quelle langue ?'**
  String get trackLanguageTitle;

  /// No description provided for @trackLanguageBody.
  ///
  /// In fr, this message translates to:
  /// **'Nommez-la comme vous la nommez. Ce n\'est pas une liste : c\'est la langue de votre assemblée.'**
  String get trackLanguageBody;

  /// No description provided for @trackLanguageHint.
  ///
  /// In fr, this message translates to:
  /// **'Baoulé, dioula, français…'**
  String get trackLanguageHint;

  /// No description provided for @trackLanguageCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get trackLanguageCancel;

  /// No description provided for @trackLanguageConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le micro'**
  String get trackLanguageConfirm;

  /// No description provided for @trackRecordingIn.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement en {language}'**
  String trackRecordingIn(String language);

  /// Ce que l'écran montre d'une piste rangée : la langue telle que le pasteur l'a nommée, et sa durée.
  ///
  /// In fr, this message translates to:
  /// **'Piste enregistrée en {language} · {duration}'**
  String trackSaved(String language, String duration);

  /// La garde du produit, dite plutôt que subie — même règle que la lecture à voix haute.
  ///
  /// In fr, this message translates to:
  /// **'Validez la synthèse avant d\'enregistrer votre voix.'**
  String get trackNotValidated;

  /// Un succès muet serait pire : le pasteur croirait avoir une piste qui n'existe pas.
  ///
  /// In fr, this message translates to:
  /// **'Le micro s\'est fermé sans rien enregistrer. Rien n\'a été gardé.'**
  String get trackEmpty;

  /// No description provided for @trackMicRefused.
  ///
  /// In fr, this message translates to:
  /// **'Le micro n\'est pas autorisé. Ouvrez les réglages du téléphone pour le permettre.'**
  String get trackMicRefused;

  /// No description provided for @trackNoMicrophone.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone n\'a pas de micro utilisable.'**
  String get trackNoMicrophone;

  /// No description provided for @trackStorageFull.
  ///
  /// In fr, this message translates to:
  /// **'Plus assez de place pour enregistrer. Libérez quelques mégaoctets.'**
  String get trackStorageFull;

  /// No description provided for @trackEngineFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'enregistrement n\'a pas pu commencer.'**
  String get trackEngineFailed;

  /// Stockage vidé, appareil restauré : le dire vaut mieux qu'un bouton qui ne fait rien.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier de cette piste n\'est plus sur le téléphone.'**
  String get trackFileMissing;

  /// No description provided for @trackNoPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone ne sait pas jouer cette piste.'**
  String get trackNoPlayer;

  /// No description provided for @trackPlaybackFailed.
  ///
  /// In fr, this message translates to:
  /// **'La lecture n\'a pas pu commencer.'**
  String get trackPlaybackFailed;

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

  /// Titre de l'éditeur audio, où le pasteur découpe son culte.
  ///
  /// In fr, this message translates to:
  /// **'Tailler une pièce'**
  String get editorTitle;

  /// Le condensé de l'onde se calcule ; sur une heure et demie, cela prend quelques secondes.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de l\'onde…'**
  String get editorPreparing;

  /// Une capture vide ne s'édite pas.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a rien à tailler : aucun fragment n\'a été écrit.'**
  String get editorEmpty;

  /// Explique le geste de l'éditeur, parce qu'on ne place pas une coupe au doigt sur une heure et demie.
  ///
  /// In fr, this message translates to:
  /// **'Écoutez, arrêtez-vous à la frontière, puis posez la borne. L\'onde sert à viser ; l\'oreille tranche.'**
  String get editorGesture;

  /// Lance la lecture depuis la tête.
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get editorPlay;

  /// Suspend la lecture sans perdre l'endroit.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get editorPause;

  /// Infobulle du recul.
  ///
  /// In fr, this message translates to:
  /// **'Reculer de dix secondes'**
  String get editorBack;

  /// Infobulle de l'avance.
  ///
  /// In fr, this message translates to:
  /// **'Avancer de dix secondes'**
  String get editorForward;

  /// Réduit la fenêtre affichée pour viser plus fin.
  ///
  /// In fr, this message translates to:
  /// **'Resserrer'**
  String get editorZoomIn;

  /// Élargit la fenêtre affichée pour se repérer.
  ///
  /// In fr, this message translates to:
  /// **'Élargir'**
  String get editorZoomOut;

  /// Où en est la lecture dans le culte entier.
  ///
  /// In fr, this message translates to:
  /// **'{position} sur {duration}'**
  String editorPosition(String position, String duration);

  /// Pose la borne de gauche de la pièce à la position d'écoute.
  ///
  /// In fr, this message translates to:
  /// **'Début ici'**
  String get editorSetStart;

  /// Pose la borne de droite de la pièce à la position d'écoute.
  ///
  /// In fr, this message translates to:
  /// **'Fin ici'**
  String get editorSetEnd;

  /// Titre du bandeau qui récapitule les bornes.
  ///
  /// In fr, this message translates to:
  /// **'La pièce'**
  String get editorPiece;

  /// Les deux bornes de la pièce.
  ///
  /// In fr, this message translates to:
  /// **'{from} → {to}'**
  String editorRange(String from, String to);

  /// Durée de ce qui sera taillé.
  ///
  /// In fr, this message translates to:
  /// **'{duration} de pièce'**
  String editorLength(String duration);

  /// Rejoue les secondes autour de la borne de gauche : une borne posée à l'œil tombe souvent au milieu d'un mot.
  ///
  /// In fr, this message translates to:
  /// **'Écouter le début'**
  String get editorHearStart;

  /// Rejoue les secondes autour de la borne de droite.
  ///
  /// In fr, this message translates to:
  /// **'Écouter la fin'**
  String get editorHearEnd;

  /// Écrit la pièce. Rien n'est détruit : la matière reste entière.
  ///
  /// In fr, this message translates to:
  /// **'Tailler cette pièce'**
  String get editorCut;

  /// La pièce s'écrit.
  ///
  /// In fr, this message translates to:
  /// **'Découpage…'**
  String get editorCutting;

  /// Refus quand les deux bornes se touchent.
  ///
  /// In fr, this message translates to:
  /// **'Une pièce fait au moins une seconde.'**
  String get editorTooShort;

  /// Confirmation, qui dit surtout ce que le pasteur ne peut pas deviner : la pièce survit à la purge, la matière non.
  ///
  /// In fr, this message translates to:
  /// **'Pièce taillée. Elle vit avec sa publication, et ne disparaîtra pas au septième jour.'**
  String get editorCutDone;

  /// Place la borne de gauche à la fin de la pièce qu'on vient de tailler — le geste du dimanche : la prédication, puis la prière.
  ///
  /// In fr, this message translates to:
  /// **'Enchaîner sur la suite'**
  String get editorNext;

  /// Dit que le geste est réversible, parce qu'un pasteur qui craint d'effacer son culte n'osera pas couper.
  ///
  /// In fr, this message translates to:
  /// **'La matière reste entière. Tailler écrit une pièce à côté ; vous pouvez recommencer autant de fois qu\'il faut.'**
  String get editorSafety;

  /// Libellé du champ de titre. Sans nom, deux pièces d'un même dimanche ne se distinguent pas dans une liste.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la pièce'**
  String get editorName;

  /// Exemple de nom, tiré du dimanche réel d'un pasteur : une prédication puis une prière.
  ///
  /// In fr, this message translates to:
  /// **'Prédication, prière…'**
  String get editorNameHint;

  /// Titre de la liste des pièces d'un culte.
  ///
  /// In fr, this message translates to:
  /// **'Les pièces taillées'**
  String get piecesTitle;

  /// Liste vide — et elle dit l'enjeu du délai plutôt que de constater le vide.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'a encore été taillé dans ce culte. L\'audio brut disparaît au septième jour ; une pièce, non.'**
  String get piecesEmpty;

  /// Ouvre l'éditeur depuis le culte.
  ///
  /// In fr, this message translates to:
  /// **'Tailler une pièce'**
  String get piecesCut;

  /// D'où vient une pièce dans le culte d'origine.
  ///
  /// In fr, this message translates to:
  /// **'de {from} à {to}'**
  String piecesFrom(String from, String to);

  /// Joue une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get piecesPlay;

  /// Arrête la lecture d'une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get piecesStop;

  /// Dit ce que le pasteur ne peut pas deviner : la matière disparaît, les pièces restent.
  ///
  /// In fr, this message translates to:
  /// **'Ces pièces survivent à la purge du septième jour.'**
  String get piecesSurvives;

  /// Propose la pièce aux applications du téléphone. Le canal réel d'une assemblée est WhatsApp, pas une plateforme.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get piecesShare;

  /// Refus de partage : l'audio a disparu. Le dire plutôt que de se taire.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n\'est plus sur le téléphone.'**
  String get piecesShareMissing;

  /// Refus de partage : aucun canal, ou le greffon a lâché.
  ///
  /// In fr, this message translates to:
  /// **'Le partage n\'a pas pu s\'ouvrir sur cet appareil.'**
  String get piecesShareFailed;

  /// Change le nom d'une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get piecesRename;

  /// Valide le nouveau nom.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get piecesRenameSave;

  /// Ferme sans renommer.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get piecesRenameCancel;

  /// Retire une pièce et son audio.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get piecesDelete;

  /// Titre de la confirmation.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette pièce ?'**
  String get piecesDeleteTitle;

  /// Dit ce qui est irréversible, et pourquoi : la matière d'origine peut avoir déjà été purgée.
  ///
  /// In fr, this message translates to:
  /// **'L\'audio part avec elle, et ne se retrouvera pas. Si le culte a passé sept jours, il n\'y a plus de quoi la retailler.'**
  String get piecesDeleteBody;
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
