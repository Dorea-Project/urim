import 'package:urim/l10n/generated/app_text.dart';

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
  resistance;

  /// Titre et corps de l'étape, dans la langue de l'appareil.
  ///
  /// Les textes ne sont plus des constantes : ils vivent dans `lib/l10n`, et
  /// l'étape ne connaît que sa clé. C'est ce qui permet d'ajouter une langue
  /// sans rouvrir ce fichier.
  String title(AppText text) => switch (this) {
        weighing => text.onboardingWeighingTitle,
        handback => text.onboardingHandbackTitle,
        resistance => text.onboardingResistanceTitle,
      };

  String body(AppText text) => switch (this) {
        weighing => text.onboardingWeighingBody,
        handback => text.onboardingHandbackBody,
        resistance => text.onboardingResistanceBody,
      };
}

/// Les étapes de la présentation, dans l'ordre.
///
/// La liste reste ici — c'est une décision de produit, pas une traduction :
/// combien d'étapes, dans quel ordre, avec quel motif.
abstract final class OnboardingContent {
  const OnboardingContent._();

  static const List<OnboardingIllustration> steps = [
    OnboardingIllustration.weighing,
    OnboardingIllustration.handback,
    OnboardingIllustration.resistance,
  ];
}
