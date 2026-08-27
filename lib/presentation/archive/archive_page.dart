import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/domain/entities/preparation/preached.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/archive/archive_view_model.dart';
import 'package:urim/presentation/archive/record_sheet.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Ce que le pasteur a prêché, et où il est allé dans l'Écriture.
///
/// ⚠️ **Cet écran ne propose jamais de sermon.** Le serveur l'écrit dans son
/// propre contrat, et c'est la règle qui gouverne chaque ligne d'ici : *un rayon
/// vide se montre, il ne se comble pas ; le signal informe l'homme, l'homme
/// commande la machine.* Aucun score, aucune série, aucun pourcentage de
/// complétude doctrinale — ce serait mesurer la fidélité d'un pasteur, et
/// transformer une aide en performance à tenir.
class ArchivePage extends ConsumerWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final archive = ref.watch(archiveProvider);
    final couverture = ref.watch(coverageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(text.archiveTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          tooltip: text.back,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          // Un pasteur a prêché avant Dorea, et il prêche ailleurs. Sans cette
          // porte, l'archive ne mesurerait que ce qui est passé par l'outil.
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: text.archiveRecordManual,
            onPressed: () => showRecordSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (archive) {
          AsyncError() => const _ArchiveError(),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncData(:final value) => value.isEmpty
              ? _Vide(text.archiveEmpty)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    if (couverture.value case final PreachingCoverage c)
                      _Couverture(couverture: c),
                    for (final sermon in value) ...[
                      _Ligne(sermon: sermon),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
        },
      ),
    );
  }
}

/// Le parcours : les livres, les axes, et ce qui n'a rien reçu.
class _Couverture extends StatelessWidget {
  const _Couverture({required this.couverture});

  final PreachingCoverage couverture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.coverageTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        for (final livre in couverture.books) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(livre.book, style: theme.textTheme.titleMedium),
                ),
                // ⚠️ **Deux nombres, jamais additionnés.** Des lieux distincts
                // d'un côté — prêcher deux fois le même texte n'élargit pas un
                // canon — des événements de l'autre, parce que deux assemblées
                // ont entendu.
                Text(
                  '${text.coveragePassages(livre.passages)} · '
                  '${text.coveragePreachings(livre.preachings)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          text.coverageUntouched(couverture.booksUntouched),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // La phrase qui empêche l'écran de reprocher : « aucun sermon rangé
        // ici » n'est pas « vous ne l'avez jamais prêché ».
        Text(
          text.coverageNotice,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Une prédication consignée.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.sermon});

  final PreachedSermon sermon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    return Container(
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
          Text(sermon.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            frenchShortDate(sermon.preachedOn),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          // Nul = **non rangé**, et on le nomme. Masquer la ligne ferait croire
          // à un trou dans l'archive ; hors unité curée, il n'y a simplement
          // aucun axe à retenir.
          if (sermon.axisCode == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              text.archiveUnfiled,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide(this.body);

  final String body;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.5,
                ),
          ),
        ),
      );
}

class _ArchiveError extends ConsumerWidget {
  const _ArchiveError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);

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
            Text(text.homeReadFailed, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => ref.invalidate(archiveProvider),
              child: Text(text.retry),
            ),
          ],
        ),
      ),
    );
  }
}
