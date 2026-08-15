import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/presentation/home/home_view_model.dart';
import 'package:urim/presentation/home/widgets/preparation_card.dart';
import 'package:urim/presentation/home/widgets/task_sheet.dart';
import 'package:urim/presentation/profile/profile_view_model.dart';
import 'package:urim/presentation/profile/widgets/profile_avatar.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Accueil : les travaux en cours, du plus récent au plus ancien.
///
/// Ce qui rend la main se voit en premier, et se signale d'un filet : sur cet
/// écran, la seule question est « qu'est-ce qui m'attend ? ».
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preparations = ref.watch(preparationListProvider);
    final initials = ref.watch(profileViewModelProvider).value?.profile.initials;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urim'),
        actions: [
          ProfileAvatarButton(
            initials: initials ?? '',
            onPressed: () => context.pushNamed(AppRoutes.profileName),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (preparations) {
                AsyncData(:final value) => _Feed(preparations: value),
                AsyncError() => const _FeedError(),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                  onPressed: () => showTaskSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ouvrir une tâche'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.preparations});

  final List<Preparation> preparations;

  @override
  Widget build(BuildContext context) {
    if (preparations.isEmpty) return const _FeedEmpty();

    final groups = groupByRecency(preparations, now: DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
            child: Text(
              group.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          for (final preparation in group.preparations) ...[
            PreparationCard(preparation: preparation),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rien en cours.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ouvre une tâche : écris ce que tu veux dire, ou verse un '
              'enregistrement.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedError extends ConsumerWidget {
  const _FeedError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'La liste n\'a pas pu être lue.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => ref.invalidate(preparationListProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
