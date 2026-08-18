import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_palette.dart';

/// Rôles de couleur qui n'existent pas dans [ColorScheme].
///
/// Accessible partout via `Theme.of(context).extension<AppColors>()!`, ou plus
/// simplement `context.colors` (voir l'extension en bas de fichier).
///
/// Les couleurs métier vivent ici, et non dans une table figée, parce qu'elles
/// doivent changer entre le mode clair et le mode sombre — un marine profond
/// illisible sur fond noir devient un bleu clair.
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.surfaceWarm,
    required this.success,
    required this.warning,
  });

  /// Texte courant. Contraste très élevé sur le fond correspondant.
  final Color textPrimary;

  /// Texte d'accompagnement : métadonnées, légendes. Reste au-dessus de 4,5:1.
  final Color textSecondary;

  /// Texte désactivé ou placeholder. **Sous le seuil de lisibilité** : ne
  /// jamais l'employer pour une information nécessaire.
  final Color textMuted;

  final Color border;

  /// Surface chaude des longues lectures. Le sable fatigue moins l'œil que le
  /// blanc pur sur un chapitre entier.
  final Color surfaceWarm;

  final Color success;
  final Color warning;

  static const AppColors light = AppColors(
    textPrimary: AppPalette.navy800,
    textSecondary: AppPalette.gray500,
    textMuted: AppPalette.gray400,
    border: AppPalette.gray200,
    surfaceWarm: AppPalette.sand100,
    success: Color(0xFF2F6B4F),
    warning: AppPalette.orange700,
  );

  static const AppColors dark = AppColors(
    textPrimary: AppPalette.offWhite,
    textSecondary: AppPalette.gray300,
    textMuted: AppPalette.gray400,
    border: AppPalette.navy600,
    surfaceWarm: AppPalette.navy700,
    success: Color(0xFF7FBF9B),
    warning: AppPalette.orange300,
  );

  @override
  AppColors copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? surfaceWarm,
    Color? success,
    Color? warning,
  }) =>
      AppColors(
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        border: border ?? this.border,
        surfaceWarm: surfaceWarm ?? this.surfaceWarm,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      border: mix(border, other.border),
      surfaceWarm: mix(surfaceWarm, other.surfaceWarm),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
    );
  }
}

extension AppColorsAccess on BuildContext {
  /// Raccourci : `context.colors.textSecondary`.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
