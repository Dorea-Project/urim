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
