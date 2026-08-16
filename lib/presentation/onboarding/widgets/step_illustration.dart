import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:urim/presentation/onboarding/onboarding_content.dart';
import 'package:urim/presentation/theme/app_colors.dart';

/// Motif animé de l'étape.
///
/// L'animation se joue **une fois**, à l'entrée, et se construit : chaque
/// figure se dessine dans l'ordre où elle se lit. Rien ne tourne en boucle —
/// une boucle attirerait l'œil en permanence alors que le texte est ce qu'il
/// faut lire, et empêcherait tout test d'atteindre un état stable.
class StepIllustration extends StatefulWidget {
  const StepIllustration({
    super.key,
    required this.illustration,
    this.size = 220,
  });

  final OnboardingIllustration illustration;
  final double size;

  @override
  State<StepIllustration> createState() => _StepIllustrationState();
}

class _StepIllustrationState extends State<StepIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Respecte le réglage système « réduire les animations » : le motif
    // s'affiche alors d'emblée dans son état final.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final palette = _IllustrationPalette(
      ink: colors.textPrimary,
      kept: colors.success,
      asks: Theme.of(context).colorScheme.primary,
      muted: colors.textMuted,
    );

    // Le dessin ne dit rien de plus que le titre : le lecteur d'écran n'a pas
    // à l'annoncer.
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            size: Size.square(widget.size),
            painter: _IllustrationPainter(
              illustration: widget.illustration,
              progress: _controller.value,
              palette: palette,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rôles de couleur du trait.
@immutable
final class _IllustrationPalette {
  const _IllustrationPalette({
    required this.ink,
    required this.kept,
    required this.asks,
    required this.muted,
  });

  /// Trait principal.
  final Color ink;

  /// Ce qui est retenu.
  final Color kept;

  /// Ce qui interpelle ou résiste.
  final Color asks;

  /// Ce qui est écarté ou secondaire.
  final Color muted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _IllustrationPalette &&
          other.ink == ink &&
          other.kept == kept &&
          other.asks == asks &&
          other.muted == muted;

  @override
  int get hashCode => Object.hash(ink, kept, asks, muted);
}

/// Dessine les trois figures.
///
/// Les coordonnées sont écrites dans un carré de 240 unités, puis mises à
/// l'échelle : on raisonne sur une grille fixe plutôt qu'en fractions
/// illisibles.
class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter({
    required this.illustration,
    required this.progress,
    required this.palette,
  });

  final OnboardingIllustration illustration;
  final double progress;
  final _IllustrationPalette palette;

  static const double _grid = 240;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _grid;

    canvas.save();
    canvas.scale(scale);

    switch (illustration) {
      case OnboardingIllustration.weighing:
        _paintWeighing(canvas);
      case OnboardingIllustration.handback:
        _paintHandback(canvas);
      case OnboardingIllustration.resistance:
        _paintResistance(canvas);
    }

    canvas.restore();
  }

  /// Segment de l'animation, ramené sur 0..1.
  double _phase(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0, 1);

  /// L'opacité est bornée ici : les courbes à rebond (`easeOutBack`) dépassent
  /// 1 en cours de route, et une couleur n'accepte pas cela.
  Paint _stroke(Color color, double width, {double alpha = 1}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: alpha.clamp(0, 1));

  /// Trace le début d'un chemin, sur une fraction de sa longueur.
  void _drawPortion(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 7,
    double gap = 5,
  }) {
    for (final metric in path.computeMetrics()) {
      var travelled = 0.0;
      while (travelled < metric.length) {
        final end = math.min(travelled + dash, metric.length);
        canvas.drawPath(metric.extractPath(travelled, end), paint);
        travelled = end + gap;
      }
    }
  }

  Path _line(Offset from, Offset to) => Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(to.dx, to.dy);

  // --- 1. La balance ---------------------------------------------------------
  //
  // Une phrase est écrite en haut ; deux candidats pendent en dessous. Le
  // retenu se ferme d'un trait plein, l'écarté reste en pointillé. La balance
  // oscille une fois, puis revient à l'horizontale : elle a tranché.

  void _paintWeighing(Canvas canvas) {
    const stemTop = Offset(120, 42);
    const pivot = Offset(120, 100);

    _drawPortion(
      canvas,
      _line(stemTop, pivot),
      Curves.easeOut.transform(_phase(0, 0.25)),
      _stroke(palette.muted, 2.5),
    );

    final swing = Curves.easeInOut.transform(_phase(0.55, 1));
    final angle = -0.10 * math.sin(math.pi * swing);

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);

    // Le fléau se déploie depuis le centre, vers les deux côtés à la fois.
    final beam = Curves.easeOutCubic.transform(_phase(0.18, 0.45));
    if (beam > 0) {
      canvas.drawLine(
        Offset(pivot.dx - 62 * beam, pivot.dy),
        Offset(pivot.dx + 62 * beam, pivot.dy),
        _stroke(palette.ink, 4),
      );
    }

    final drop = Curves.easeOut.transform(_phase(0.4, 0.62));
    for (final x in const [84.0, 156.0]) {
      _drawPortion(
        canvas,
        _line(Offset(x, 100), Offset(x, 130)),
        drop,
        _stroke(palette.muted, 2),
      );
    }

    _paintCandidate(
      canvas,
      center: const Offset(84, 164),
      reveal: Curves.easeOutBack.transform(_phase(0.55, 0.82)),
      kept: true,
    );
    _paintCandidate(
      canvas,
      center: const Offset(156, 164),
      reveal: Curves.easeOut.transform(_phase(0.62, 0.9)),
      kept: false,
    );

    canvas.restore();
  }

  /// Une fiche de texte : pleine si elle est retenue, en pointillé sinon.
  void _paintCandidate(
    Canvas canvas, {
    required Offset center,
    required double reveal,
    required bool kept,
  }) {
    if (reveal <= 0) return;

    final color = kept ? palette.kept : palette.muted;
    final rect = Rect.fromCenter(
      center: center.translate(0, 10 * (1 - reveal)),
      width: 64,
      height: 62,
    );
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));

    final border = _stroke(color, kept ? 2.5 : 2, alpha: reveal);

    if (kept) {
      canvas.drawPath(card, border);
    } else {
      _drawDashed(canvas, card, border, dash: 6, gap: 5);
    }

    final text = _stroke(color, 2.5, alpha: reveal * (kept ? 0.9 : 0.55));
    canvas.drawLine(
      Offset(rect.left + 12, rect.center.dy - 7),
      Offset(rect.right - 12, rect.center.dy - 7),
      text,
    );
    canvas.drawLine(
      Offset(rect.left + 12, rect.center.dy + 7),
      Offset(rect.right - 24, rect.center.dy + 7),
      text,
    );
  }

  // --- 2. La main rendue -----------------------------------------------------
  //
  // Deux motifs cités s'écrivent l'un après l'autre, puis la barre de saisie
  // se referme et le point rouge s'allume : la question revient à celui qui
  // prêche.

  void _paintHandback(Canvas canvas) {
    _paintReason(canvas, top: 60, widths: const [104, 82], start: 0);
    _paintReason(canvas, top: 98, widths: const [94, 70], start: 0.25);

    final box = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(40, 142, 200, 198),
          const Radius.circular(16),
        ),
      );
    _drawPortion(
      canvas,
      box,
      Curves.easeOutCubic.transform(_phase(0.5, 0.82)),
      _stroke(palette.ink, 3),
    );

    _drawPortion(
      canvas,
      _line(const Offset(62, 170), const Offset(128, 170)),
      Curves.easeOut.transform(_phase(0.72, 0.88)),
      _stroke(palette.ink, 3),
    );

    // Le point rouge : ce qui attend une réponse. Il arrive en dernier, et
    // une onde s'en échappe une fois — juste assez pour qu'on le voie.
    final dot = Curves.easeOutBack.transform(_phase(0.8, 1));
    if (dot <= 0) return;

    const dotCenter = Offset(168, 170);
    canvas.drawCircle(
      dotCenter,
      12 * dot,
      _stroke(palette.asks, 3, alpha: dot.clamp(0, 1)),
    );

    final wave = _phase(0.86, 1);
    if (wave > 0 && wave < 1) {
      canvas.drawCircle(
        dotCenter,
        12 + 14 * wave,
        _stroke(palette.asks, 2, alpha: (1 - wave) * 0.5),
      );
    }
  }

  /// Un motif cité : le filet, puis les lignes qui s'écrivent.
  void _paintReason(
    Canvas canvas, {
    required double top,
    required List<double> widths,
    required double start,
  }) {
    final rule = Curves.easeOut.transform(_phase(start, start + 0.15));
    _drawPortion(
      canvas,
      _line(Offset(52, top), Offset(52, top + 24)),
      rule,
      _stroke(palette.ink, 3),
    );

    for (var i = 0; i < widths.length; i++) {
      final from = start + 0.08 + i * 0.08;
      final written = Curves.easeOut.transform(_phase(from, from + 0.18));
      if (written <= 0) continue;

      final y = top + 6 + i * 14;
      canvas.drawLine(
        Offset(68, y),
        Offset(68 + widths[i] * written, y),
        _stroke(palette.muted, 3, alpha: i == 0 ? 0.9 : 0.6),
      );
    }
  }

  // --- 3. Ce qui résiste -----------------------------------------------------
  //
  // La flèche descend dans le sens de la lecture ; l'arc rouge la traverse à
  // contresens. La flèche recule d'un cheveu au moment du croisement — c'est
  // toute l'idée de l'étape.

  void _paintResistance(Canvas canvas) {
    final ground = Curves.easeOut.transform(_phase(0, 0.18));
    if (ground > 0) {
      canvas.drawLine(
        Offset(120 - 54 * ground, 202),
        Offset(120 + 54 * ground, 202),
        _stroke(palette.muted, 4, alpha: 0.6),
      );
    }

    final recoil = -3 * math.sin(math.pi * _phase(0.7, 1));

    canvas.save();
    canvas.translate(0, recoil);

    _drawPortion(
      canvas,
      _line(const Offset(120, 50), const Offset(120, 168)),
      Curves.easeOutCubic.transform(_phase(0.15, 0.62)),
      _stroke(palette.kept, 3),
    );

    final head = Path()
      ..moveTo(98, 150)
      ..lineTo(120, 176)
      ..lineTo(142, 150);
    _drawPortion(
      canvas,
      head,
      Curves.easeOut.transform(_phase(0.55, 0.74)),
      _stroke(palette.kept, 3),
    );

    canvas.restore();

    final arc = Path()
      ..moveTo(84, 100)
      ..quadraticBezierTo(120, 56, 156, 98);
    _drawPortion(
      canvas,
      arc,
      Curves.easeOutCubic.transform(_phase(0.68, 1)),
      _stroke(palette.asks, 3),
    );
  }

  @override
  bool shouldRepaint(_IllustrationPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.palette != palette ||
      oldDelegate.illustration != illustration;
}
