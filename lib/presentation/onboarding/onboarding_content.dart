/// Marque affichée en haut d'une étape.
enum OnboardingMark { monogram, wordmark }

/// Une étape de la présentation.
final class OnboardingStep {
  const OnboardingStep({
    required this.message,
    this.mark = OnboardingMark.monogram,
  });

  final String message;
  final OnboardingMark mark;
}

/// Textes de la présentation, réunis en un seul endroit.
///
/// Les rassembler ici plutôt que de les semer dans les widgets rend leur
/// relecture possible sans lire le code, et fera de la localisation un
/// remplacement mécanique le jour venu.
///
/// La copie de la maquette a été reprise pour l'orthographe et l'accord :
/// « intelligemment », « productif », « amène », « de bonnes décisions ».
abstract final class OnboardingContent {
  const OnboardingContent._();

  static const List<OnboardingStep> steps = [
    OnboardingStep(
      message: 'Plus qu\'un compagnon\nUrim vous oriente intelligemment',
    ),
    OnboardingStep(
      message: 'Devenez plus productif, Urim vous amène\n'
          'à prendre de bonnes décisions',
    ),
    OnboardingStep(
      message: 'Lancez-vous maintenant, pour des\nsermons inspirés',
      mark: OnboardingMark.wordmark,
    ),
  ];

  static const String next = 'Suivant';
  static const String skip = 'Passer';
  static const String previous = 'Précédent';
  static const String enter = 'Accédez à votre espace';
  static const String alreadyRegistered = 'Avez-vous déjà un compte ?';
  static const String signIn = 'Se connecter';
  static const String saveFailed =
      'Impossible d\'enregistrer votre progression. '
      'La présentation réapparaîtra au prochain lancement.';
}
