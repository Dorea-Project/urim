import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/onboarding/onboarding_content.dart';

/// Motif animé entourant la marque de l'étape.
///
/// L'animation se joue **une fois**, à l'entrée. Rien ne tourne en boucle :
/// une boucle attirerait l'œil en permanence alors que le texte est ce qu'il
/// faut lire, et empêcherait tout test d'atteindre un état stable.
class StepIllustration extends StatefulWidget {
  const StepIllustration({super.key, required this.step, this.size = 240});

  final OnboardingStep step;
  final double size;

  @override
  State<StepIllustration> createState() => _StepIllustrationState();
}

class _StepIllustrationState extends State<StepIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              size: Size.square(widget.size),
              painter: _IllustrationPainter(
                illustration: widget.step.illustration,
                progress: _controller.value,
                color: color,
              ),
            ),
          ),
          _MarkEntrance(
            controller: _controller,
            child: switch (widget.step.mark) {
              OnboardingMark.monogram => BrandMonogram(color: color, size: 96),
              OnboardingMark.wordmark => BrandWordmark(color: color, size: 46),
            },
          ),
        ],
      ),
    );
  }
}

/// Apparition de la marque : fondu et léger agrandissement.
class _MarkEntrance extends StatelessWidget {
  const _MarkEntrance({required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    final scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter({
    required this.illustration,
    required this.progress,
    required this.color,
  });

  final OnboardingIllustration illustration;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;

    switch (illustration) {
      case OnboardingIllustration.compass:
        _paintCompass(canvas, center, radius);
      case OnboardingIllustration.crossroads:
        _paintCrossroads(canvas, center, radius);
      case OnboardingIllustration.rays:
        _paintRays(canvas, center, radius);
    }
  }

  /// Interpolation d'un segment de l'animation, ramenée sur 0..1.
  double _phase(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0, 1);

  // --- Boussole --------------------------------------------------------------

  void _paintCompass(Canvas canvas, Offset center, double radius) {
    final ringProgress = Curves.easeOutCubic.transform(_phase(0, 0.75));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ringProgress,
      false,
      ring,
    );

    // Graduations : une par tranche de 30°, révélées avec le tracé du cercle.
    final tick = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5);

    for (var i = 0; i < 12; i++) {
      final revealed = (i + 1) / 12;
      if (ringProgress < revealed) continue;

      final angle = -math.pi / 2 + i * math.pi / 6;
      final isCardinal = i % 3 == 0;
      final inner = radius - (isCardinal ? 14 : 8);
      final direction = Offset(math.cos(angle), math.sin(angle));

      canvas.drawLine(
        center + direction * inner,
        center + direction * (radius - 2),
        tick,
      );
    }

    // Aiguille : arrive en dernier et se cale au nord.
    final needleProgress = Curves.easeOutBack.transform(_phase(0.45, 1));
    if (needleProgress <= 0) return;

    final angle = -math.pi / 2 - (1 - needleProgress) * math.pi / 3;
    final tip = center +
        Offset(math.cos(angle), math.sin(angle)) * (radius - 22) * needleProgress;
    final tail = center -
        Offset(math.cos(angle), math.sin(angle)) * (radius - 46) * needleProgress;

    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.85 * needleProgress),
    );
  }

  // --- Bifurcation -----------------------------------------------------------

  void _paintCrossroads(Canvas canvas, Offset center, double radius) {
    final trunk = Curves.easeOut.transform(_phase(0, 0.5));
    final branches = Curves.easeOutCubic.transform(_phase(0.4, 1));

    final bottom = center + Offset(0, radius);
    final fork = center + Offset(0, radius * 0.15);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5);

    canvas.drawLine(bottom, Offset.lerp(bottom, fork, trunk)!, stroke);

    if (branches <= 0) return;

    // La branche retenue est pleine, l'écartée reste en pointillé : une
    // décision, c'est aussi ce qu'on laisse.
    final chosen = fork + Offset(radius * 0.72, -radius * 0.72);
    canvas.drawLine(
      fork,
      Offset.lerp(fork, chosen, branches)!,
      stroke..color = color.withValues(alpha: 0.85),
    );

    final discarded = fork + Offset(-radius * 0.72, -radius * 0.72);
    _drawDashedLine(
      canvas,
      fork,
      Offset.lerp(fork, discarded, branches)!,
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.28),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 7.0;
    const gap = 6.0;
    final total = (to - from).distance;
    if (total <= 0) return;

    final direction = (to - from) / total;
    var travelled = 0.0;

    while (travelled < total) {
      final end = math.min(travelled + dash, total);
      canvas.drawLine(
        from + direction * travelled,
        from + direction * end,
        paint,
      );
      travelled = end + gap;
    }
  }

  // --- Rayons ----------------------------------------------------------------

  void _paintRays(Canvas canvas, Offset center, double radius) {
    const count = 16;

    for (var i = 0; i < count; i++) {
      // Décalage progressif : les rayons ne jaillissent pas tous ensemble.
      final start = 0.05 * (i % 4);
      final reveal = Curves.easeOut.transform(_phase(start, start + 0.7));
      if (reveal <= 0) continue;

      final angle = i * 2 * math.pi / count;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final isLong = i.isEven;
      final inner = radius * 0.62;
      final outer = inner + (isLong ? radius * 0.34 : radius * 0.18) * reveal;

      canvas.drawLine(
        center + direction * inner,
        center + direction * outer,
        Paint()
          ..strokeWidth = isLong ? 3 : 2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: (isLong ? 0.7 : 0.4) * reveal),
      );
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.illustration != illustration;
}
