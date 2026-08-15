import 'package:flutter/material.dart';

/// Échelle typographique.
///
/// Deux familles pour deux usages, et c'est délibéré : l'interface se lit par
/// coups d'œil, le texte biblique se lit en continu pendant plusieurs minutes.
/// Les faire cohabiter dans la même police oblige à choisir laquelle des deux
/// sera mal servie.
///
/// Une troisième famille, **Nova Cut**, porte l'identité — et rien d'autre.
/// C'est une police d'affichage : elle n'a ni les graisses ni le dessin
/// qu'exigent un texte d'interface ou une lecture de plusieurs minutes. Elle
/// est superbe à 96 pt sur le monogramme, illisible à 14 pt dans une liste.
abstract final class AppTypography {
  const AppTypography._();

  /// Police de l'interface. `null` = police système.
  static const String? uiFontFamily = null;

  /// Police de lecture. Une serif est préférable pour le texte suivi.
  static const String? readingFontFamily = null;

  /// Police de marque. **Réservée au monogramme et au logotype.**
  static const String brandFontFamily = 'NovaCut';

  /// Monogramme « U » : écran de lancement et onboarding.
  static const TextStyle monogram = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: 120,
    height: 1,
  );

  /// Logotype « Urim ».
  static const TextStyle wordmark = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: 52,
    height: 1.1,
    letterSpacing: 1,
  );

  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, height: 1.45),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );

  /// Style du texte biblique en lecture suivie.
  ///
  /// Interlignage large (1,7) et taille confortable : ce texte se lit par
  /// paragraphes entiers, pas par étiquettes. À combiner avec
  /// `AppBreakpoints.readingColumn` pour borner la longueur de ligne.
  static const TextStyle reading = TextStyle(
    fontFamily: readingFontFamily,
    fontSize: 18,
    height: 1.7,
    letterSpacing: 0.1,
  );

  /// Numéro de verset : nettement plus petit, en exposant visuel, il ne doit
  /// pas hacher la lecture.
  static const TextStyle verseNumber = TextStyle(
    fontSize: 11,
    height: 1.7,
    fontWeight: FontWeight.w700,
  );

  /// Référence citée (`Romains 8.28`), en petites capitales optiques.
  static const TextStyle reference = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );
}
