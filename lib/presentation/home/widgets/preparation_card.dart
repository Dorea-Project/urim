import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/common/french_dates.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Une préparation sur l'accueil : ce qu'elle est, où elle en est, et quand.
///
/// Ce qu'elle n'affiche pas : la phrase d'Urim. Le fil ne la reçoit pas — elle
/// naît du rejeu du moteur, et vingt cartes feraient vingt rejeux. Elle attend
/// derrière la carte, sur l'écran de la préparation.
class PreparationCard extends ConsumerWidget {
  const PreparationCard({super.key, required this.summary});

  final StudySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ce que le pasteur a écrit en ouvrant, tant que rien n'est résolu.
          Text(
            summary.rawInput,
            style: theme.textTheme.titleLarge,
          ),
          if (summary.subtitle case final String subtitle) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Pas de pastille tant que le moteur n'a rendu aucun tour : une
              // préparation qui vient de naître n'a pas d'état, et lui en
              // inventer un serait revenir d'où l'on vient.
              if (summary.lastOutcome case final TurnOutcome outcome) ...[
                _OutcomeChip(outcome: outcome),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  _meta(text, summary),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      // Une prédication transcrite s'ouvre sur sa relecture, pas sur le fil :
      // ce qu'on vient y chercher, c'est ce qui a été dit.
      onTap: () => context.pushNamed(
        summary.origin == PreparationOrigin.transcribed
            ? AppRoutes.transcriptionName
            : AppRoutes.preparationName,
        pathParameters: {'id': summary.id},
      ),
      // Ce qui attend une réponse porte un filet : la pastille dit l'état, le
      // filet le rend visible d'un coup d'œil sur la liste entière.
      child: summary.waitsForUser
          ? RuledContent(
              color: colors.textPrimary,
              gap: AppSpacing.md,
              child: card,
            )
          : card,
    );
  }
}

/// Pastille du dernier tour : « Rend la main », « Matière servie »…
class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.outcome});

  final TurnOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        turnOutcomeLabel(AppText.of(context), outcome),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: outcome.waitsForUser ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// « Hier, 21:14 », « Jeudi · dimanche 17 août ».
String _meta(AppText text, StudySummary summary, {DateTime? now}) {
  final activity = _activityLabel(
    text,
    summary.lastActivity,
    now ?? DateTime.now(),
  );

  if (summary.serviceDate case final DateTime service) {
    return text.homeCardMetaWithService(activity, frenchDayMonth(service));
  }

  return text.homeCardMeta(activity);
}

const List<String> _weekdays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

String _activityLabel(AppText text, DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final difference = today.difference(day).inDays;

  final time = '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  return switch (difference) {
    0 => text.homeActivityToday(time),
    1 => text.homeActivityYesterday(time),
    // Au-delà d'une semaine, le jour de la semaine ne situe plus rien.
    < 7 => _weekdays[at.weekday - 1],
    _ => frenchDayMonth(at),
  };
}
