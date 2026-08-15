import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Bandeau du parcours de démonstration.
///
/// N'apparaît qu'en dehors de la production, et le dit franchement : mieux
/// vaut un encadré visible qu'un identifiant caché dans une documentation que
/// personne n'ouvre au moment d'essayer.
///
/// Il disparaîtra de lui-même le jour où un vrai serveur enverra les SMS —
/// aucun écran n'aura à être retouché.
class DemoBanner extends ConsumerWidget {
  const DemoBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appConfigProvider).usesMockCredentials) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 18, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
