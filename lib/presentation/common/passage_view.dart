import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/settings/settings_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/theme/app_typography.dart';

/// Un passage cité : le texte en police de lecture, puis sa provenance.
///
/// Le fil, la transcription et la synthèse l'affichent de la même façon, et
/// c'est voulu — un verset ne change pas d'allure selon l'écran qui le montre.
class PassageView extends ConsumerWidget {
  const PassageView({super.key, required this.passage, this.rule = true});

  final QuotedPassage passage;

  /// Filet vertical à gauche. Absent lorsque le passage est déjà dans une
  /// carte qui en porte un.
  final bool rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(effectiveSettingsProvider);

    final attribution = [
      '${passage.referenceLabel} — ${passage.translationLabel}',
      if (passage.pericopeLabel case final String pericope) pericope,
    ].join(' · ');

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          passage.text,
          style: AppTypography.reading.copyWith(
            fontSize:
                AppTypography.reading.fontSize! * settings.readingTextSize.scale,
            color: context.colors.textPrimary,
          ),
        ),
        if (settings.alwaysShowReference) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            attribution,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    if (!rule) return content;

    return RuledContent(
      color: context.colors.success,
      gap: AppSpacing.md,
      child: content,
    );
  }
}

/// `03:10` ou `1:04:22`.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');

  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}

/// Étiquette temporelle d'un bloc, selon son repère.
///
/// Prend les textes en paramètre plutôt que le contexte : la fonction est
/// appelée depuis des tests qui n'ont pas d'arbre de widgets, et lui faire
/// chercher un `BuildContext` la rendrait inutilisable là où elle est le plus
/// simple à vérifier.
String formatAnchor(AppText text, BlockAnchor anchor, {DateTime? now}) =>
    switch (anchor) {
      MediaAnchor(:final offset) => formatDuration(offset),
      ClockAnchor(:final at) => _formatClock(text, at, now ?? DateTime.now()),
    };

String _formatClock(AppText text, DateTime at, DateTime now) {
  final time = '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final difference = today.difference(day).inDays;

  return switch (difference) {
    0 => text.blockToday(time),
    1 => text.blockYesterday(time),
    _ => text.blockOnDate(frenchDayMonth(at).toUpperCase(), time),
  };
}
