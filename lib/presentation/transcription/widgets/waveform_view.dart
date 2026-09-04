import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:urim/core/audio/waveform.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Dessiner un culte — **l'instrument, pas la décoration**.
///
/// Un pasteur qui cherche la frontière entre sa prédication et sa prière ne
/// l'entend pas : il faudrait écouter une heure. Il la **voit** — le creux des
/// applaudissements, la reprise du chant, le silence qui précède la prière.
///
/// ## Deux vues, et c'est ce qui rend le geste possible
///
/// 🔴 **Une heure et demie sur un téléphone, c'est huit secondes par pixel.**
/// Placer une coupe à la seconde y est impossible : le doigt couvre une minute.
/// D'où l'aperçu du culte entier **et** le détail zoomé — l'un dit *où l'on
/// est*, l'autre permet de viser. C'est le patron de tous les éditeurs audio
/// sérieux, et pour la même raison.
///
/// ⚠️ **La crête, jamais la moyenne** (voir [Waveform]) : une moyenne
/// écraserait les attaques, et les attaques sont précisément les repères.

/// La fenêtre visible, et ce qu'on y montre.
@immutable
final class WaveformFrame {
  const WaveformFrame({
    required this.onde,
    required this.debut,
    required this.fin,
    this.tete,
    this.selDebut,
    this.selFin,
  });

  final Waveform onde;

  /// Les bornes de ce qu'on dessine — l'aperçu montre tout, le détail une part.
  final Duration debut;
  final Duration fin;

  /// La tête de lecture, si le culte joue.
  final Duration? tete;

  /// La pièce en train d'être taillée.
  final Duration? selDebut;
  final Duration? selFin;

  Duration get etendue => fin - debut;
}

/// Le détail zoomé — celui sur lequel on vise.
class WaveformView extends StatelessWidget {
  const WaveformView({
    super.key,
    required this.frame,
    this.hauteur = 132,
    this.onPointe,
  });

  final WaveformFrame frame;
  final double hauteur;

  /// Un appui pose la tête de lecture là où le doigt est tombé.
  final ValueChanged<Duration>? onPointe;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.colors;
    final schema = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, contraintes) {
        final largeur = contraintes.maxWidth;

        void pointer(Offset local) {
          if (onPointe == null || largeur <= 0) return;
          final part = (local.dx / largeur).clamp(0.0, 1.0);
          onPointe!(
            frame.debut +
                Duration(
                  microseconds:
                      (frame.etendue.inMicroseconds * part).round(),
                ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pointer(d.localPosition),
          onHorizontalDragUpdate: (d) => pointer(d.localPosition),
          child: CustomPaint(
            size: Size(largeur, hauteur),
            painter: _OndePainter(
              frame: frame,
              trait: couleurs.textSecondary,
              traitHorsSelection: couleurs.border,
              selection: schema.primary,
              tete: schema.primary,
              compact: false,
            ),
          ),
        );
      },
    );
  }
}

/// L'aperçu du culte entier — **où l'on est, jamais où l'on vise**.
///
/// Il porte aussi le rectangle de la fenêtre zoomée : sans lui, on se perd dans
/// une heure et demie dès le premier glissement.
class WaveformOverview extends StatelessWidget {
  const WaveformOverview({
    super.key,
    required this.frame,
    required this.fenetreDebut,
    required this.fenetreFin,
    this.hauteur = 44,
    this.onPointe,
  });

  final WaveformFrame frame;
  final Duration fenetreDebut;
  final Duration fenetreFin;
  final double hauteur;
  final ValueChanged<Duration>? onPointe;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.colors;
    final schema = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, contraintes) {
        final largeur = contraintes.maxWidth;

        void pointer(Offset local) {
          if (onPointe == null || largeur <= 0) return;
          final part = (local.dx / largeur).clamp(0.0, 1.0);
          onPointe!(
            Duration(
              microseconds: (frame.etendue.inMicroseconds * part).round(),
            ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pointer(d.localPosition),
          onHorizontalDragUpdate: (d) => pointer(d.localPosition),
          child: CustomPaint(
            size: Size(largeur, hauteur),
            painter: _OndePainter(
              frame: frame,
              trait: couleurs.border,
              traitHorsSelection: couleurs.border,
              selection: schema.primary,
              tete: schema.primary,
              compact: true,
              fenetreDebut: fenetreDebut,
              fenetreFin: fenetreFin,
              cadre: couleurs.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _OndePainter extends CustomPainter {
  const _OndePainter({
    required this.frame,
    required this.trait,
    required this.traitHorsSelection,
    required this.selection,
    required this.tete,
    required this.compact,
    this.fenetreDebut,
    this.fenetreFin,
    this.cadre,
  });

  final WaveformFrame frame;
  final Color trait;
  final Color traitHorsSelection;
  final Color selection;
  final Color tete;
  final bool compact;
  final Duration? fenetreDebut;
  final Duration? fenetreFin;
  final Color? cadre;

  /// Une barre et son intervalle. Plus fin serait illisible sur un A07, plus
  /// large ferait perdre les attaques courtes.
  static const double _pas = 3;

  @override
  void paint(Canvas canvas, Size taille) {
    if (taille.width <= 0 || taille.height <= 0) return;

    final colonnes = math.max(1, (taille.width / _pas).floor());
    final cretes = frame.onde.fenetre(frame.debut, frame.fin, colonnes);
    final milieu = taille.height / 2;
    final demi = milieu - (compact ? 2 : 6);

    double? x(Duration? instant) {
      if (instant == null || frame.etendue.inMicroseconds <= 0) return null;
      final part = (instant - frame.debut).inMicroseconds /
          frame.etendue.inMicroseconds;
      return part.clamp(0.0, 1.0) * taille.width;
    }

    final xDebut = x(frame.selDebut);
    final xFin = x(frame.selFin);

    // Le voile de la sélection passe **sous** l'onde : posé au-dessus, il
    // laverait les crêtes qu'on vient chercher.
    if (xDebut != null && xFin != null && xFin > xDebut) {
      canvas.drawRect(
        Rect.fromLTRB(xDebut, 0, xFin, taille.height),
        Paint()..color = selection.withValues(alpha: compact ? .16 : .10),
      );
    }

    final dedans = Paint()..color = trait;
    final dehors = Paint()..color = traitHorsSelection;
    final rayon = Radius.circular(compact ? .5 : 1);

    for (var colonne = 0; colonne < cretes.length; colonne++) {
      final gauche = colonne * _pas;
      // Une barre d'au moins un demi-pixel : le silence doit se voir comme une
      // ligne, pas comme un trou. Un trou se lirait « il manque de l'audio ».
      final hauteur = math.max(demi * cretes[colonne] / 255, .5);

      final horsSelection = xDebut != null &&
          xFin != null &&
          (gauche + _pas < xDebut || gauche > xFin);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(gauche, milieu - hauteur, gauche + _pas - 1,
              milieu + hauteur),
          rayon,
        ),
        horsSelection ? dehors : dedans,
      );
    }

    // Les bornes de la pièce : deux traits pleins, plus francs que le voile.
    if (!compact) {
      for (final borne in [xDebut, xFin]) {
        if (borne == null) continue;
        canvas.drawLine(
          Offset(borne, 0),
          Offset(borne, taille.height),
          Paint()
            ..color = selection
            ..strokeWidth = 2,
        );
      }
    }

    // Le rectangle de la fenêtre zoomée, sur l'aperçu seulement.
    if (compact && fenetreDebut != null && fenetreFin != null) {
      final g = x(fenetreDebut);
      final d = x(fenetreFin);
      if (g != null && d != null && d > g) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(g, 0, d, taille.height),
            const Radius.circular(AppRadius.sm),
          ),
          Paint()
            ..color = cadre ?? trait
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // La tête de lecture en dernier : rien ne doit passer devant elle.
    final xTete = x(frame.tete);
    if (xTete != null) {
      canvas.drawLine(
        Offset(xTete, 0),
        Offset(xTete, taille.height),
        Paint()
          ..color = tete
          ..strokeWidth = 2,
      );
      if (!compact) {
        canvas.drawCircle(Offset(xTete, 0), 4, Paint()..color = tete);
      }
    }
  }

  @override
  bool shouldRepaint(_OndePainter ancien) =>
      ancien.frame.onde != frame.onde ||
      ancien.frame.debut != frame.debut ||
      ancien.frame.fin != frame.fin ||
      ancien.frame.tete != frame.tete ||
      ancien.frame.selDebut != frame.selDebut ||
      ancien.frame.selFin != frame.selFin ||
      ancien.fenetreDebut != fenetreDebut ||
      ancien.fenetreFin != fenetreFin ||
      ancien.trait != trait;
}
