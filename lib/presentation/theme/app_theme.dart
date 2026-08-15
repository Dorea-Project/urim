import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/theme/app_palette.dart';
import 'package:urim/presentation/theme/app_typography.dart';

/// Thèmes clair et sombre de l'application.
///
/// Point d'entrée unique : aucun widget ne construit son propre `ThemeData`,
/// et aucun ne code une couleur en dur.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(_lightScheme, AppColors.light);

  static ThemeData get dark => _build(_darkScheme, AppColors.dark);

  // --- Schémas ---------------------------------------------------------------

  /// La brique sert l'action principale ; l'erreur emprunte une brique plus
  /// sombre. Les deux restent proches — d'où la règle : **jamais d'erreur
  /// signalée par la seule couleur**, toujours une icône et un texte. Cela
  /// vaut aussi pour les daltoniens, qui ne distinguent ni l'une ni l'autre.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.brick500,
    onPrimary: AppPalette.white,
    primaryContainer: AppPalette.brick100,
    onPrimaryContainer: AppPalette.brick900,
    secondary: AppPalette.orange500,
    onSecondary: AppPalette.navy900,
    secondaryContainer: AppPalette.orange100,
    onSecondaryContainer: AppPalette.orange900,
    tertiary: AppPalette.amber500,
    onTertiary: AppPalette.navy900,
    tertiaryContainer: AppPalette.amber100,
    onTertiaryContainer: AppPalette.amber900,
    error: AppPalette.brick700,
    onError: AppPalette.white,
    errorContainer: AppPalette.brick100,
    onErrorContainer: AppPalette.brick900,
    surface: AppPalette.white,
    onSurface: AppPalette.navy800,
    surfaceContainerLowest: AppPalette.white,
    surfaceContainerLow: AppPalette.offWhite,
    surfaceContainer: AppPalette.gray50,
    surfaceContainerHigh: AppPalette.gray100,
    surfaceContainerHighest: AppPalette.gray200,
    onSurfaceVariant: AppPalette.gray500,
    outline: AppPalette.gray300,
    outlineVariant: AppPalette.gray200,
    inverseSurface: AppPalette.navy800,
    onInverseSurface: AppPalette.offWhite,
    inversePrimary: AppPalette.brick300,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.brick400,
    onPrimary: AppPalette.navy900,
    primaryContainer: AppPalette.brick800,
    onPrimaryContainer: AppPalette.brick100,
    secondary: AppPalette.orange400,
    onSecondary: AppPalette.navy900,
    secondaryContainer: AppPalette.orange800,
    onSecondaryContainer: AppPalette.orange100,
    tertiary: AppPalette.amber300,
    onTertiary: AppPalette.navy900,
    tertiaryContainer: AppPalette.amber900,
    onTertiaryContainer: AppPalette.amber100,
    error: AppPalette.brick300,
    onError: AppPalette.navy900,
    errorContainer: AppPalette.brick800,
    onErrorContainer: AppPalette.brick100,
    surface: AppPalette.navy800,
    onSurface: AppPalette.offWhite,
    surfaceContainerLowest: AppPalette.navy900,
    surfaceContainerLow: AppPalette.navy800,
    surfaceContainer: AppPalette.navy700,
    surfaceContainerHigh: AppPalette.navy600,
    surfaceContainerHighest: AppPalette.navy500,
    onSurfaceVariant: AppPalette.gray300,
    outline: AppPalette.navy400,
    outlineVariant: AppPalette.navy600,
    inverseSurface: AppPalette.offWhite,
    onInverseSurface: AppPalette.navy800,
    inversePrimary: AppPalette.brick600,
  );

  // --- Assemblage ------------------------------------------------------------

  static ThemeData _build(ColorScheme scheme, AppColors colors) {
    final textTheme = AppTypography.textTheme.apply(
      fontFamily: AppTypography.uiFontFamily,
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: [colors],
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        side: BorderSide(color: colors.border),
        labelStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
