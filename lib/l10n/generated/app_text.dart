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
