/// Marque affichée en haut d'une étape.
enum OnboardingMark { monogram, wordmark }

/// Motif dessiné autour de la marque.
///
/// Tracés en code plutôt qu'importés : trois figures géométriques simples ne
/// justifient ni une dépendance SVG, ni des images en trois densités, et elles
/// suivent la couleur du thème sans retouche. À remplacer par de vrais visuels
/// le jour où il y en aura.
enum OnboardingIllustration {
  /// Boussole : l'orientation.
  compass,

  /// Chemin qui bifurque : la décision.
  crossroads,

  /// Rayons : l'inspiration.
  rays,
}

/// Une étape de la présentation.
final class OnboardingStep {
  const OnboardingStep({
    required this.message,
    required this.illustration,
    this.mark = OnboardingMark.monogram,
  });

  final String message;
  final OnboardingIllustration illustration;
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
      illustration: OnboardingIllustration.compass,
    ),
    OnboardingStep(
      message: 'Devenez plus productif, Urim vous amène\n'
          'à prendre de bonnes décisions',
      illustration: OnboardingIllustration.crossroads,
    ),
    OnboardingStep(
      message: 'Lancez-vous maintenant, pour des\nsermons inspirés',
      illustration: OnboardingIllustration.rays,
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
