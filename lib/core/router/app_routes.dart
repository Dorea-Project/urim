/// Chemins et noms de routes, centralisés.
///
/// Naviguer par **nom** (`context.goNamed(AppRoutes.homeName)`) plutôt que par
/// chemin littéral : le nom survit à un changement d'URL.
abstract final class AppRoutes {
  const AppRoutes._();

  /// Écran de lancement. Point d'entrée : tant que l'on ignore si la
  /// présentation a déjà été vue, on ne sait pas où aller.
  static const String splashPath = '/lancement';
  static const String splashName = 'splash';

  static const String onboardingPath = '/presentation';
  static const String onboardingName = 'onboarding';

  static const String signInPath = '/connexion';
  static const String signInName = 'signIn';

  static const String otpPath = '/connexion/code';
  static const String otpName = 'otp';

  /// Connexion d'un compte existant : le code secret d'abord, le SMS seulement
  /// si le serveur ne reconnaît pas l'appareil.
  static const String signInSecretCodePath = '/connexion/acces';
  static const String signInSecretCodeName = 'signInSecretCode';

  static const String secretCodeSetupPath = '/code-secret/creation';
  static const String secretCodeSetupName = 'secretCodeSetup';

  static const String secretCodePath = '/code-secret';
  static const String secretCodeName = 'secretCode';

  /// Politique de confidentialité. **Hors de [entryPaths]** : un texte à
  /// portée juridique doit rester atteignable à tout moment, avant comme
  /// après connexion.
  static const String privacyPath = '/politique-confidentialite';
  static const String privacyName = 'privacy';

  static const String homePath = '/';
  static const String homeName = 'home';

  /// Ouverture d'une préparation écrite.
  ///
  /// Déclarée **avant** `/preparation/:id` dans la table : sans cela,
  /// « nouvelle » serait pris pour un identifiant.
  static const String newPreparationPath = '/preparation/nouvelle';
  static const String newPreparationName = 'newPreparation';

  /// Une préparation et son fil.
  static const String preparationPath = '/preparation/:id';
  static const String preparationName = 'preparation';

  /// Relecture d'une prédication transcrite.
  static const String transcriptionPath = '/preparation/:id/transcription';
  static const String transcriptionName = 'transcription';

  /// Synthèse d'une prédication, à valider.
  static const String synthesisPath = '/preparation/:id/synthese';
  static const String synthesisName = 'synthesis';

  static const String profilePath = '/profil';
  static const String profileName = 'profile';

  /// Réglages. Chemin de premier niveau bien qu'on y entre par le profil : ils
  /// ne dépendent pas de lui, et un lien direct doit rester possible.
  static const String settingsPath = '/reglages';
  static const String settingsName = 'settings';

  /// Routes du parcours d'entrée : inaccessibles une fois l'accès ouvert.
  static const Set<String> entryPaths = {
    splashPath,
    onboardingPath,
    signInPath,
    otpPath,
    signInSecretCodePath,
    secretCodeSetupPath,
    secretCodePath,
  };

  /// Les deux écrans qu'un utilisateur **déjà connecté** peut rouvrir pour
  /// changer son code secret : le SMS, puis le nouveau code.
  ///
  /// Ils appartiennent aussi à [entryPaths] — ce sont les mêmes écrans. Seule
  /// la porte empruntée dit laquelle des deux situations on est en train de
  /// vivre.
  static const Set<String> secretCodeChangePaths = {
    otpPath,
    secretCodeSetupPath,
  };

  /// Le seul écran qu'un utilisateur connecté rouvre pour supprimer son
  /// compte : le code reçu par SMS. Il n'y a pas de second écran — après le
  /// code, il n'y a plus de compte.
  static const Set<String> accountDeletionPaths = {otpPath};

  /// Le seul écran du changement de numéro : le code reçu sur le nouveau.
  static const Set<String> phoneChangePaths = {otpPath};

  /// Routes atteignables tant que personne n'est connecté.
  ///
  /// La création du code secret n'en fait pas partie : elle suppose une session
  /// ouverte — sauf à l'inscription, où elle la termine, et où le numéro tenu
  /// en mémoire suffit à distinguer les deux cas.
  static const Set<String> signedOutPaths = {
    signInPath,
    otpPath,
    signInSecretCodePath,
    secretCodeSetupPath,
  };
}
