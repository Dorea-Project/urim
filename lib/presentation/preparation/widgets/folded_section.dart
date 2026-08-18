import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Ce qui accompagne, rangé sous son intitulé — **et pas caché**.
///
/// L'intitulé dit ce qu'il y a dedans et combien, et une touche l'ouvre : c'est
/// la différence entre ranger et escamoter (D43). Deux endroits l'appliquent —
/// le décor ambiant d'un tour, et la matière que la préparation porte — et ils
/// doivent se replier de la même façon, sinon le pasteur apprend deux
/// grammaires pour un seul geste.
///
/// Le contenu est construit **à l'ouverture** : replié, il ne coûte rien.
class FoldedSection extends StatefulWidget {
  const FoldedSection({super.key, required this.label, required this.builder});

  /// Ce que le repli annonce — avec son nombre, pour que le pasteur sache ce
  /// qu'il n'a pas sous les yeux.
  final String label;

  final WidgetBuilder builder;

  @override
  State<FoldedSection> createState() => _FoldedSectionState();
}

class _FoldedSectionState extends State<FoldedSection> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _ouvert = !_ouvert),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _ouvert ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_ouvert) ...[
          const SizedBox(height: AppSpacing.sm),
          widget.builder(context),
        ],
      ],
    );
  }
}
