import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/domain/entities/bible/bible_translation.dart';
import 'package:urim/domain/entities/settings/app_settings.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/section_card.dart';
import 'package:urim/presentation/settings/settings_view_model.dart';
import 'package:urim/presentation/settings/widgets/reading_size_selector.dart';
import 'package:urim/presentation/settings/widgets/translation_sheet.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Réglages.
///
/// Deux catégories cohabitent, et l'écran ne les mélange pas : ce qui agit
/// réellement — taille du texte, version par défaut, affichage de la référence
/// — et ce que la maquette promet mais qui dépend d'une question ouverte. Ces
/// derniers sont montrés **inactifs**, avec ce qu'ils attendent (D13).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final text = AppText.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(text.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: text.back,
        ),
      ),
      body: SafeArea(
        child: switch (settings) {
          AsyncData(:final value) => _SettingsList(settings: value),
          AsyncError(:final error) => _SettingsError(error: error),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.settings});

  final AppSettings settings;

  Future<void> _apply(
    BuildContext context,
    Future<Failure?> Function() change,
  ) async {
    final failure = await change();
    if (failure == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.of(context).settingsSaveFailed)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(settingsViewModelProvider.notifier);
    final text = AppText.of(context);
    final translation =
        BibleTranslation.byId(settings.defaultTranslationId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        // --- Lecture ---------------------------------------------------------
        SectionLabel(text.settingsSectionReading),
        SectionCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ReadingSizeSelector(
                selected: settings.readingTextSize,
                onSelected: (size) => _apply(
                  context,
                  () => viewModel.setReadingTextSize(size),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Écriture --------------------------------------------------------
        SectionLabel(text.settingsSectionScripture),
        SectionCard(
          children: [
            SettingNavRow(
              title: text.settingsDefaultVersion,
              value: translation.name,
              onTap: () => showTranslationSheet(
                context: context,
                selectedId: settings.defaultTranslationId,
                onSelected: (id) => _apply(
                  context,
                  () => viewModel.setDefaultTranslation(id),
                ),
              ),
            ),
            SettingSwitchRow(
              title: text.settingsAlwaysShowReference,
              subtitle: text.settingsAlwaysShowReferenceHint,
              value: settings.alwaysShowReference,
              onChanged: (value) => _apply(
                context,
                () => viewModel.setAlwaysShowReference(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Hors connexion --------------------------------------------------
        //
        // Les trois attendent une décision : la source du texte biblique (Q1),
        // le moteur de transcription (Q2), et ce qu'on synchronise (Q10).
        SectionLabel(text.settingsSectionOffline),
        SectionCard(
          children: [
            SettingSwitchRow(
              title: text.settingsBibleDownloaded,
              subtitle: text.settingsBibleDownloadedPending,
              value: false,
            ),
            SettingSwitchRow(
              title: text.settingsTranscribeOnDevice,
              subtitle: text.settingsTranscribeOnDevicePending,
              value: false,
            ),
            SettingSwitchRow(
              title: text.settingsWifiOnly,
              subtitle: text.settingsWifiOnlyPending,
              value: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Rappels ---------------------------------------------------------
        SectionLabel(text.settingsSectionReminders),
        SectionCard(
          children: [
            SettingSwitchRow(
              title: text.settingsReminderInProgress,
              subtitle: text.settingsReminderInProgressPending,
              value: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Contenu ---------------------------------------------------------
        SectionLabel(text.settingsSectionContent),
        SectionCard(
          children: [
            SettingNavRow(
              title: text.settingsExport,
              subtitle: text.settingsExportPending,
            ),
            SettingRow(
              title: text.settingsStorageUsed,
              subtitle: text.settingsStorageUsedPending,
              muted: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        const _TrainingNotice(),
      ],
    );
  }
}

/// Rappel de la politique, à l'endroit où l'on s'interroge sur ce qui sort de
/// l'appareil.
class _TrainingNotice extends StatelessWidget {
  const _TrainingNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppText.of(context).settingsTrainingNotice,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.45,
          ),
    );
  }
}

class _SettingsError extends ConsumerWidget {
  const _SettingsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    // Le motif technique reste dans les logs : ici, ce qui compte est que
    // l'écran est relisable.
    final detail = error is Failure ? (error as Failure).message : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppText.of(context).settingsReadFailed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => ref.invalidate(settingsViewModelProvider),
              child: Text(AppText.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
