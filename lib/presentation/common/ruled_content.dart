import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Contenu marqué d'un filet vertical à gauche.
///
/// Le motif revient partout où quelque chose est *cité* : un engagement de la
/// politique, un bloc du fil, un aperçu de verset.
///
/// Il est dessiné par une bordure, et non par une `Row` étirée : dans une
/// liste, la hauteur d'un élément n'est pas connue au moment de la mise en
/// page, et étirer un enfant sur une hauteur infinie fait échouer le rendu —
/// « BoxConstraints forces an infinite height ». Une bordure gauche épouse la
/// hauteur du contenu sans rien exiger de son parent.
class RuledContent extends StatelessWidget {
  const RuledContent({
    super.key,
    required this.color,
    required this.child,
    this.width = 3,
    this.gap = AppSpacing.lg,
  });

  final Color color;
  final Widget child;

  /// Épaisseur du filet.
  final double width;

  /// Espace entre le filet et le contenu.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: gap),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: width)),
      ),
      child: child,
    );
  }
}

/// Même filet, en pointillé : ce qu'Urim dit, par opposition au trait plein de
/// l'Écriture.
///
/// Peint par-derrière plutôt que posé à côté : un `CustomPaint` prend la
/// hauteur de son enfant, là où une colonne étirée exigerait de la connaître
/// d'avance.
class DottedRuledContent extends StatelessWidget {
  const DottedRuledContent({
    super.key,
    required this.color,
    required this.child,
    this.width = 3,
    this.gap = AppSpacing.lg,
  });

  final Color color;
  final Widget child;
  final double width;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedRulePainter(color: color, width: width),
      child: Padding(
        padding: EdgeInsets.only(left: gap),
        child: child,
      ),
    );
  }
}

class _DottedRulePainter extends CustomPainter {
  const _DottedRulePainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final step = width * 2;

    for (var y = 0.0; y + width <= size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, width, width), paint);
    }
  }

  @override
  bool shouldRepaint(_DottedRulePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.width != width;
}
