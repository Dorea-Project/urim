/// Un engagement de confidentialité : ce qu'Urim ne fera pas.
final class PrivacyCommitment {
  const PrivacyCommitment({required this.title, required this.body});

  final String title;
  final String body;
}

/// Texte de la politique de confidentialité.
///
/// Réuni ici plutôt que dispersé dans les widgets : c'est un texte à portée
/// juridique, il doit pouvoir être relu et amendé sans lire de code.
///
/// L'application tutoie l'utilisateur sur cet écran, conformément à la
/// maquette.
abstract final class PrivacyContent {
  const PrivacyContent._();

  static const String title = 'Tes données';

  static const String intro = 'Trois choses qu\'Urim ne fera jamais. '
      'Elles sont tenues par le code, pas par une promesse.';

  static const List<PrivacyCommitment> commitments = [
    PrivacyCommitment(
      title: 'Aucune analyse de personne',
      body: 'Urim traite des textes. Il ne produit aucun jugement, score ou '
          'profil sur un membre, un fidèle ou un collaborateur.',
    ),
    PrivacyCommitment(
      title: 'Tes préparations restent à toi',
      body: 'Elles ne sont lues par personne d\'autre — ni par ton église, '
          'ni par Dorea, ni par un responsable.',
    ),
    PrivacyCommitment(
      title: 'Rien n\'est revendu',
      body: 'Aucun partage à un tiers, aucune publicité, aucun entraînement '
          'de modèle sur ton contenu.',
    ),
  ];

  static const String retainedLabel = 'CE QUI EST CONSERVÉ';

  static const List<String> retained = [
    'Ton numéro de téléphone, pour te reconnaître.',
    'Tes préparations et enregistrements, jusqu\'à ce que tu les supprimes.',
    'Les appareils sur lesquels tu t\'es connecté.',
  ];

  static const String legalNotice =
      'Traitement soumis à la loi ivoirienne n° 2013-450 relative à la '
      'protection des données à caractère personnel. Tu peux supprimer ton '
      'compte et tout son contenu à tout moment.';

  static const String accept = 'J\'ai lu et j\'accepte';
}
