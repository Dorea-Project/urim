import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_colors.dart';

/// Forme d'onde de l'enregistrement.
///
/// Dessinée depuis les amplitudes échantillonnées à la capture : relire
/// quarante minutes d'audio pour afficher une vignette coûterait plus cher que
/// tout le reste de l'écran.
class Waveform extends StatelessWidget {
  const Waveform({
    super.key,
    required this.amplitudes,
    this.height = 64,
    this.barWidth = 3,
  });

  final List<double> amplitudes;
  final double height;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: amplitudes,
          color: context.colors.textMuted,
          barWidth: barWidth,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.barWidth,
  });

  final List<double> amplitudes;
  final Color color;
  final double barWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final step = size.width / amplitudes.length;
    final middle = size.height / 2;

    for (var i = 0; i < amplitudes.length; i++) {
      final x = step * (i + 0.5);
      final half = (amplitudes[i].clamp(0, 1) * size.height) / 2;

      canvas.drawLine(Offset(x, middle - half), Offset(x, middle + half), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.amplitudes != amplitudes ||
      oldDelegate.color != color ||
      oldDelegate.barWidth != barWidth;
}

/// Bandeau des fragments : ce qui est acquitté, ce qui attend le réseau.
///
/// Une barre par tranche, dans l'ordre de la capture. L'utilisateur n'a pas à
/// comprendre le découpage — il doit seulement voir qu'il ne manque rien, et
/// que ce qui reste partira.
class FragmentStrip extends StatelessWidget {
  const FragmentStrip({
    super.key,
    required this.total,
    required this.acknowledged,
    this.height = 10,
  });

  final int total;
  final int acknowledged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: i < acknowledged ? colors.success : colors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}
