import 'package:flutter/material.dart';

/// Palette brute : les teintes et leurs variantes, sans aucun sens d'usage.
///
/// **Ne jamais référencer ces constantes depuis un widget.** Elles n'ont pas
/// de rôle — `brick500` ne veut pas dire « bouton principal ». Passer par
/// `AppColors` (rôles sémantiques) ou par le `ColorScheme` du thème, sans
/// quoi un changement de charte imposerait de relire tous les écrans.
///
/// Seule `brick500` est une valeur fournie. Les sept autres teintes de base
/// sont relevées sur la maquette et restent à confirmer ; les variantes en
/// sont dérivées par éclaircissement et assombrissement.
abstract final class AppPalette {
  const AppPalette._();

  // --- Brique : couleur d'identité -----------------------------------------

  static const Color brick50 = Color(0xFFFDF2EF);
  static const Color brick100 = Color(0xFFFADFD8);
  static const Color brick200 = Color(0xFFF4BCAE);
  static const Color brick300 = Color(0xFFEC9782);
  static const Color brick400 = Color(0xFFDE6A4E);
  static const Color brick500 = Color(0xFFCC3C1F); // valeur de reference
  static const Color brick600 = Color(0xFFAE3119);
  static const Color brick700 = Color(0xFF8E2714);
  static const Color brick800 = Color(0xFF6D1D0F);
  static const Color brick900 = Color(0xFF4A130A);

  // --- Orange : accent chaud -----------------------------------------------

  static const Color orange50 = Color(0xFFFEF6EA);
  static const Color orange100 = Color(0xFFFDE7C6);
  static const Color orange200 = Color(0xFFFBCE8C);
  static const Color orange300 = Color(0xFFF9B45A);
  static const Color orange400 = Color(0xFFF7A03A);
  static const Color orange500 = Color(0xFFF5901E);
  static const Color orange600 = Color(0xFFD2760F);
  static const Color orange700 = Color(0xFFA85C0B);
  static const Color orange800 = Color(0xFF7C4308);
  static const Color orange900 = Color(0xFF532C05);

  // --- Ambre : accent secondaire -------------------------------------------

  static const Color amber100 = Color(0xFFFEF0D2);
  static const Color amber300 = Color(0xFFFDD68A);
  static const Color amber500 = Color(0xFFFDBB42);
  static const Color amber700 = Color(0xFFC8902A);
  static const Color amber900 = Color(0xFF7E5A17);

  // --- Sable : surfaces chaudes, longues lectures --------------------------

  static const Color sand100 = Color(0xFFF7F4E4);
  static const Color sand300 = Color(0xFFEFE9CB);
  static const Color sand500 = Color(0xFFE6DEB2);
  static const Color sand700 = Color(0xFFB5AD84);
  static const Color sand900 = Color(0xFF736D50);

  // --- Marine : texte, surfaces sombres, ancrage ---------------------------

  static const Color navy50 = Color(0xFFE8EEF2);
  static const Color navy100 = Color(0xFFC6D4DD);
  static const Color navy200 = Color(0xFF8FA9B9);
  static const Color navy300 = Color(0xFF5A8098);
  static const Color navy400 = Color(0xFF2D5B77);
  static const Color navy500 = Color(0xFF003049);
  static const Color navy600 = Color(0xFF00293E);
  static const Color navy700 = Color(0xFF002132);
  static const Color navy800 = Color(0xFF001926);
  static const Color navy900 = Color(0xFF001019);

  // --- Gris : texte secondaire, bordures, états éteints --------------------

  static const Color gray50 = Color(0xFFF4F5F5);
  static const Color gray100 = Color(0xFFE4E5E6);
  static const Color gray200 = Color(0xFFCED3D6);
  static const Color gray300 = Color(0xFFA9AEB2);
  static const Color gray400 = Color(0xFF85898D);
  static const Color gray500 = Color(0xFF63666A);
  static const Color gray600 = Color(0xFF515458);
  static const Color gray700 = Color(0xFF3F4245);
  static const Color gray800 = Color(0xFF2D2F32);
  static const Color gray900 = Color(0xFF1B1D1F);

  // --- Neutres absolus ------------------------------------------------------

  static const Color offWhite = Color(0xFFF6F9FB);
  static const Color white = Color(0xFFFFFFFF);
}
