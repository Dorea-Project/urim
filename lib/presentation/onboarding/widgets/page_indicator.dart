import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Progression de la présentation : les étapes franchies s'encrent, les
/// suivantes restent grises.
///
/// C'est le **nombre** de tirets encrés qui porte l'information, et non leur
/// teinte : deux traits noirs sur trois se comptent, y compris pour un lecteur
/// qui ne distingue pas les couleurs.
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
    final colors = context.colors;

    return Semantics(
      label: 'Étape ${currentIndex + 1} sur $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final isReached = index <= currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            height: 4,
            width: 26,
            decoration: BoxDecoration(
              color: isReached ? colors.textPrimary : colors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          );
        }),
      ),
    );
  }
}
