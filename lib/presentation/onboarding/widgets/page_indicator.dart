import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Indicateur de progression : la puce active s'allonge et se colore.
///
/// La longueur, et pas seulement la couleur, porte l'information — les puces
/// inactives sont grises et la puce active est brique, deux teintes que
/// certains lecteurs ne distinguent pas.
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Étape ${currentIndex + 1} sur $count',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            height: 8,
            width: isActive ? 22 : 8,
            decoration: BoxDecoration(
              color: isActive ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          );
        }),
      ),
    );
  }
}
