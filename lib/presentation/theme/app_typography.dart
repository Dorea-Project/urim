import 'package:flutter/material.dart';

/// Échelle typographique.
///
/// Deux familles pour deux usages, et c'est délibéré : l'interface se lit par
/// coups d'œil, le texte biblique se lit en continu pendant plusieurs minutes.
/// Les faire cohabiter dans la même police oblige à choisir laquelle des deux
/// sera mal servie.
///
/// Aucune police n'est embarquée pour l'instant : `fontFamily` est laissé nul,
/// Flutter retombe donc sur la police système. Embarquer une famille est une
/// décision à prendre avant de multiplier les écrans — voir le bas de fichier.
abstract final class AppTypography {
  const AppTypography._();

  /// Police de l'interface. `null` = police système.
  static const String? uiFontFamily = null;

  /// Police de lecture. Une serif est préférable pour le texte suivi.
  static const String? readingFontFamily = null;

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
