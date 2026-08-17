import 'package:flutter/material.dart';
import 'package:urim/domain/entities/preparation/pending_gesture.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Dit qu'un geste est noté et n'est pas encore parti.
///
/// **Pourquoi il n'y a rien de plus à dire.** Le tour suivant est ce que le
/// pipeline aurait répondu ; l'écran ne peut pas le fabriquer sans inventer une
/// phrase d'Urim (D29). Il ne reste donc que l'état de l'envoi — et le fait que
/// rien n'est perdu, qui est la seule chose qui inquiète vraiment.
class PendingBanner extends StatelessWidget {
  const PendingBanner({super.key, required this.pending});

  final List<PendingGesture> pending;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: context.colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.gesturePending(pending.length),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text.gesturePendingBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
