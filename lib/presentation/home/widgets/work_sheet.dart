import 'package:flutter/material.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/home/opening_rule.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// « Voulez-vous basculer à… » — la question que l'icône posait en silence.
///
/// ⚠️ **Une seule destination, jamais deux.** La feuille montrait les deux
/// travaux côte à côte, dont celui qu'on avait déjà sous les yeux, marqué « tu y
/// es ». C'était une liste à relire pour retrouver où l'on était — alors que
/// l'écran le disait déjà. Il ne reste que **l'autre côté** : la carte complète
/// le titre, et la refermer est la réponse « non ».
Future<HomeTab?> showWorkSheet(
  BuildContext context, {
  required HomeTab current,
}) {
  final destination =
      current == HomeTab.prepare ? HomeTab.preach : HomeTab.prepare;

  return showModalBottomSheet<HomeTab>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final text = AppText.of(sheetContext);

      return SafeArea(
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
                text.homeSwitchTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _WorkOption(
                icon: destination == HomeTab.prepare
                    ? Icons.edit_outlined
                    : Icons.record_voice_over_outlined,
                title: destination == HomeTab.prepare
                    ? text.homeSwitchPrepare
                    : text.homeSwitchPreach,
                body: destination == HomeTab.prepare
                    ? text.homeSwitchPrepareBody
                    : text.homeSwitchPreachBody,
                onTap: () => Navigator.of(sheetContext).pop(destination),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _WorkOption extends StatelessWidget {
  const _WorkOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
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
              child: Icon(icon, size: 22, color: colors.textPrimary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
