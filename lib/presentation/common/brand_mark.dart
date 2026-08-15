import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_typography.dart';

/// Monogramme « U ».
///
/// Rendu typographique et non image : le monogramme **est** la lettre U de
/// Nova Cut. Un PNG obligerait à gérer trois densités et perdrait la mise à
/// l'échelle ; un SVG ajouterait une dépendance pour un seul glyphe.
class BrandMonogram extends StatelessWidget {
  const BrandMonogram({super.key, required this.color, this.size = 120});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'U',
      // Le monogramme n'est pas du texte à lire : il ne doit pas suivre le
      // réglage de taille de police du système, sous peine de déborder.
      textScaler: TextScaler.noScaling,
      style: AppTypography.monogram.copyWith(color: color, fontSize: size),
      semanticsLabel: 'Urim',
    );
  }
}

/// Logotype « Urim ».
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, required this.color, this.size = 52});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Urim',
      textScaler: TextScaler.noScaling,
      style: AppTypography.wordmark.copyWith(color: color, fontSize: size),
    );
  }
}
