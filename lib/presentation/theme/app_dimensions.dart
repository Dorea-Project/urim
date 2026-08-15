/// Rythme d'espacement, sur une base de 4.
///
/// N'écrire aucune valeur d'espacement en dur dans un widget : c'est
/// l'irrégularité, plus que le mauvais choix d'écart, qui fait qu'une
/// interface « fait bricolé ».
abstract final class AppSpacing {
  const AppSpacing._();

  /// 4 — séparation de deux éléments d'un même bloc (icône et son libellé).
  static const double xs = 4;

  /// 8 — écart interne d'un composant.
  static const double sm = 8;

  /// 12 — respiration d'une carte.
  static const double md = 12;

  /// 16 — marge d'écran, gouttière par défaut.
  static const double lg = 16;

  /// 24 — séparation de deux blocs distincts.
  static const double xl = 24;

  /// 32 — séparation de deux sections.
  static const double xxl = 32;

  /// 48 — respiration d'un écran vide ou d'un titre isolé.
  static const double xxxl = 48;
}

/// Rayons d'arrondi.
abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;

  /// Pastilles et puces : arrondi complet.
  static const double pill = 999;
}

/// Seuils de mise en page.
///
/// Le lecteur biblique passe en deux volets à partir de [tablet] : sommaire
/// des chapitres à gauche, texte à droite.
abstract final class AppBreakpoints {
  const AppBreakpoints._();

  static const double phone = 600;
  static const double tablet = 905;
  static const double desktop = 1240;

  /// Largeur maximale d'une colonne de texte suivi. Au-delà, l'œil perd la
  /// ligne en revenant à la marge gauche.
  static const double readingColumn = 680;
}
