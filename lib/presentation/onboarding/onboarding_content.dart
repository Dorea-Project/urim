/// Motif dessiné au-dessus du texte d'une étape.
///
/// Tracés en code plutôt qu'importés : trois figures au trait ne justifient ni
/// une dépendance SVG, ni des images en trois densités, et elles suivent les
/// couleurs du thème sans retouche — y compris en mode sombre, où un PNG
/// resterait noir sur noir.
enum OnboardingIllustration {
  /// Deux candidats suspendus à une balance : la phrase écrite, et ce
  /// qu'Urim retient face à ce qu'il écarte.
  weighing,

  /// Deux motifs cités, puis une question posée : Urim s'arrête et rend la
  /// main.
  handback,

  /// Une flèche qui descend, et l'arc rouge qui lui résiste.
  resistance,
}

/// Une étape de la présentation.
final class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.body,
    required this.illustration,
  });

  /// Titre en deux ou trois lignes. Les retours forcés sont voulus : ils
  /// portent le rythme de la phrase, pas la largeur de l'écran.
  final String title;

  final String body;
  final OnboardingIllustration illustration;
}

/// Textes de la présentation, réunis en un seul endroit.
///
/// Les rassembler ici plutôt que de les semer dans les widgets rend leur
/// relecture possible sans lire le code, et fera de la localisation un
/// remplacement mécanique le jour venu.
abstract final class OnboardingContent {
  const OnboardingContent._();

  static const List<OnboardingStep> steps = [
    OnboardingStep(
      title: 'Écris ta phrase.\nUrim cherche le texte dedans.',
      body: 'Une référence, une citation approximative, ou juste une '
          'intention. Tu n\'as aucun mode à choisir — la porte regarde si les '
          'mots se suivent comme dans l\'Écriture.',
      illustration: OnboardingIllustration.weighing,
    ),
    OnboardingStep(
      title: 'Il s\'arrête\net te rend la main.',
      body: 'Chaque étage dit pourquoi il a fait ce qu\'il a fait. Quand il ne '
          'peut pas trancher seul, il te pose la question au lieu de choisir à '
          'ta place.',
      illustration: OnboardingIllustration.handback,
    ),
    OnboardingStep(
      title: 'Il te montre les textes qui te résistent.',
      body: 'Ceux qui ne vont pas dans le sens de ta lecture. C\'est le seul '
          'moyen de ne pas faire dire au texte ce qu\'on avait décidé d\'y '
          'trouver.',
      illustration: OnboardingIllustration.resistance,
    ),
  ];

  static const String next = 'Continuer';
  static const String skip = 'Passer';

  /// Dernière étape. Créer un compte et se connecter mènent au même écran :
  /// le parcours par SMS ne distingue pas encore les deux (Q13).
  static const String enter = 'Créer mon compte';
  static const String signIn = 'J\'ai déjà un compte';

  static const String saveFailed =
      'Impossible d\'enregistrer ta progression. '
      'La présentation réapparaîtra au prochain lancement.';
}
