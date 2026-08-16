import 'package:flutter/material.dart';
import 'package:urim/domain/entities/bible/bible_translation.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Choix de la version par défaut.
///
/// Une seule traduction pour l'instant, et la feuille le dit plutôt que de
/// faire croire à une liste amputée : Louis Segond 1910 est dans le domaine
/// public, toute autre demandera une licence (Q1).
Future<void> showTranslationSheet({
  required BuildContext context,
  required String selectedId,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet<void>(
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
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.settingsDefaultVersion,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final translation in BibleTranslation.available)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(translation.name),
                  subtitle: Text(
                    translation.isPublicDomain
                        ? text.translationPublicDomain
                        : translation.copyright ?? '',
                  ),
                  trailing: translation.id == selectedId
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    onSelected(translation.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                text.translationLicenceNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: sheetContext.colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
