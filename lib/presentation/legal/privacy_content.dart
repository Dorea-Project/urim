import 'package:urim/l10n/generated/app_text.dart';

/// Un engagement de confidentialité : ce qu'Urim ne fera pas.
final class PrivacyCommitment {
  const PrivacyCommitment({required this.title, required this.body});

  final String title;
  final String body;
}

/// Structure de la politique de confidentialité.
///
/// Les textes ont rejoint `lib/l10n/app_fr.arb` — c'est **le même besoin** qui
/// avait fait naître ce fichier : un texte à portée juridique doit pouvoir être
/// relu et amendé sans lire de code. Le fichier de traduction le fait mieux, et
/// pour tous les écrans à la fois.
///
/// Ce qui reste ici est ce qui n'est pas du texte : **combien** d'engagements,
/// dans **quel ordre**, et ce qui est conservé. Réordonner cette liste est une
/// décision, pas une traduction.
abstract final class PrivacyContent {
  const PrivacyContent._();

  static List<PrivacyCommitment> commitments(AppText text) => [
        PrivacyCommitment(
          title: text.privacyNoProfilingTitle,
          body: text.privacyNoProfilingBody,
        ),
        PrivacyCommitment(
          title: text.privacyOwnershipTitle,
          body: text.privacyOwnershipBody,
        ),
        PrivacyCommitment(
          title: text.privacyNoResaleTitle,
          body: text.privacyNoResaleBody,
        ),
      ];

  /// Ce qui est conservé, dans l'ordre où on l'assume : l'identité d'abord, le
  /// contenu ensuite, les appareils en dernier.
  static List<String> retained(AppText text) => [
        text.privacyRetainedPhone,
        text.privacyRetainedWork,
        text.privacyRetainedDevices,
      ];
}
