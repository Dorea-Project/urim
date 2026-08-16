import 'package:flutter/material.dart';
import 'package:urim/domain/entities/settings/app_settings.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/theme/app_typography.dart';

/// Taille du texte de lecture, avec l'aperçu qui va avec.
///
/// L'aperçu n'est pas un ornement : c'est le seul endroit de l'écran où l'on
/// voit ce que le réglage change. Sans lui, « Grand » ne veut rien dire tant
/// qu'on n'a pas quitté les réglages pour aller vérifier.
class ReadingSizeSelector extends StatelessWidget {
  const ReadingSizeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ReadingTextSize selected;
  final ValueChanged<ReadingTextSize> onSelected;

  /// Nomme une taille.
  ///
  /// L'échelle vient du domaine, le mot vient de l'écran : « Grand » est un
  /// texte affichable, et le domaine n'en produit pas.
  static String labelOf(AppText text, ReadingTextSize size) => switch (size) {
        ReadingTextSize.small => text.settingsTextSizeSmall,
        ReadingTextSize.normal => text.settingsTextSizeNormal,
        ReadingTextSize.large => text.settingsTextSizeLarge,
        ReadingTextSize.extraLarge => text.settingsTextSizeExtraLarge,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.settingsTextSize, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ReadingTextSize>(
              segments: [
                for (final size in ReadingTextSize.values)
                  ButtonSegment<ReadingTextSize>(
                    value: size,
                    label: Text(labelOf(text, size)),
                  ),
              ],
              selected: {selected},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onSelected(selection.first),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ReadingSamplePreview(size: selected),
      ],
    );
  }
}

/// Aperçu du texte de lecture à la taille retenue.
class ReadingSamplePreview extends StatelessWidget {
  const ReadingSamplePreview({super.key, required this.size});

  final ReadingTextSize size;

  @override
  Widget build(BuildContext context) {
    return RuledContent(
      color: Theme.of(context).colorScheme.primary,
      child: Text(
        AppText.of(context).settingsReadingSample,
        style: AppTypography.reading.copyWith(
          fontSize: AppTypography.reading.fontSize! * size.scale,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
