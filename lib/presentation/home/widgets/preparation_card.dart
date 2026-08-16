import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/common/french_dates.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Une préparation sur l'accueil : ce qu'elle est, où elle en est, et quand.
class PreparationCard extends ConsumerWidget {
  const PreparationCard({super.key, required this.preparation});

  final Preparation preparation;

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
          Text(
            preparation.title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            preparation.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StateChip(state: preparation.state),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  _meta(text, preparation),
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
        preparation.origin == PreparationOrigin.transcribed
            ? AppRoutes.transcriptionName
            : AppRoutes.preparationName,
        pathParameters: {'id': preparation.id},
      ),
      // Ce qui attend une réponse porte un filet : la pastille dit l'état, le
      // filet le rend visible d'un coup d'œil sur la liste entière.
      child: preparation.state.waitsForUser
          ? RuledContent(
              color: colors.textPrimary,
              gap: AppSpacing.md,
              child: card,
            )
          : card,
    );
  }
}

/// Pastille d'état : « Rend la main », « Matière servie »…
class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final PreparationState state;

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
        preparationStateLabel(AppText.of(context), state),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: state.waitsForUser ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// « Hier, 21:14 », « Jeudi · dimanche 17 août ».
String _meta(AppText text, Preparation preparation, {DateTime? now}) {
  final activity = _activityLabel(
    text,
    preparation.updatedAt,
    now ?? DateTime.now(),
  );

  if (preparation.serviceDate case final DateTime service) {
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
