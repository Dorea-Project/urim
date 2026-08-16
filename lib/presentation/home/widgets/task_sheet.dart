import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// « Quelle tâche ? »
///
/// Deux travaux, et non deux façons de saisir : préparer part d'une intention
/// et remonte vers un texte ; transcrire part d'un message déjà prêché et
/// redescend vers ce qui en reste. Les confondre ferait de la dictée un
/// « mode », ce qu'elle n'est pas.
Future<void> showTaskSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppText.of(sheetContext).taskSheetTitle,
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppText.of(sheetContext).taskSheetSubtitle,
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: sheetContext.colors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _TaskOption(
              icon: Icons.edit_outlined,
              title: AppText.of(sheetContext).taskWriteTitle,
              body: AppText.of(sheetContext).taskWriteBody,
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.pushNamed(AppRoutes.newPreparationName);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _TaskOption(
              icon: Icons.mic_none,
              title: AppText.of(sheetContext).taskTranscribeTitle,
              body: AppText.of(sheetContext).taskTranscribeBody,
              pending: AppText.of(sheetContext).taskTranscribePending,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(AppText.of(sheetContext).cancel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TaskOption extends StatelessWidget {
  const _TaskOption({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
    this.pending,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  /// Renseigné quand la tâche ne peut pas encore être ouverte : la carte
  /// s'affiche, inactive, et dit ce qu'elle attend (D13).
  final String? pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final isPending = pending != null;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isPending ? colors.textSecondary : colors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isPending ? colors.textSecondary : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (pending case final String pending) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pending,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: card,
    );
  }
}
