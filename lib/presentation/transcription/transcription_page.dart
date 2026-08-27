import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/preparation/recording.dart';
import 'package:urim/domain/entities/transcription/transcription_review.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/common/passage_view.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/transcription/transcription_view_model.dart';
import 'package:urim/presentation/transcription/widgets/waveform.dart';

/// Relecture d'une prédication transcrite.
///
/// L'écran ne note pas la prédication : il rend ce qui a été mesuré — les
/// textes convoqués, l'écart avec le squelette — et dit où s'arrête ce qu'Urim
/// peut savoir.
class TranscriptionPage extends ConsumerWidget {
  const TranscriptionPage({super.key, required this.preparationId});

  final String preparationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(transcriptionReviewProvider(preparationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          review.value?.title ?? AppText.of(context).transcriptionFallbackTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: AppText.of(context).back,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            // Renommer, exporter, supprimer l'enregistrement : rien de tout
            // cela n'existe encore.
            onPressed: null,
            tooltip: AppText.of(context).options,
          ),
        ],
      ),
      body: SafeArea(
        child: switch (review) {
          AsyncData(:final value) =>
            _ReviewBody(review: value, preparationId: preparationId),
          AsyncError() => const _ReviewError(),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.review, required this.preparationId});

  final TranscriptionReview review;
  final String preparationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);
    final recording = review.recording;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _RecordingCard(recording: recording),
        const SizedBox(height: AppSpacing.xl),

        // --- Fragments -------------------------------------------------------
        _SectionLabel(text.transcriptionSectionFragments),
        FragmentStrip(
          total: recording.fragmentCount,
          acknowledged: recording.fragmentsAcknowledged,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _pendingSentence(text, recording.fragmentsPending),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Textes convoqués ------------------------------------------------
        _SectionLabel(text.transcriptionSectionConvoked),
        for (final scripture in review.convoked) ...[
          _ConvokedView(scripture: scripture),
          const SizedBox(height: AppSpacing.lg),
        ],
        const SizedBox(height: AppSpacing.sm),

        // --- Constats --------------------------------------------------------
        for (final remark in review.remarks) ...[
          _RemarkView(remark: remark),
          const SizedBox(height: AppSpacing.lg),
        ],
        const SizedBox(height: AppSpacing.sm),

        const _SpeakerNotice(),
        const SizedBox(height: AppSpacing.xl),

        _ReviewActions(preparationId: preparationId),
      ],
    );
  }
}

/// Carte de l'enregistrement : ce qu'il pèse, ce qu'il en reste.
class _RecordingCard extends StatelessWidget {
  const _RecordingCard({required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    final meta = [
      text.transcriptionRecorded,
      text.transcriptionFragmentsAcknowledged(
        recording.fragmentsAcknowledged,
      ),
      if (recording.audioDeletedOn case final DateTime deleted)
        text.transcriptionAudioDeletedOn(frenchDayMonth(deleted)),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Waveform(amplitudes: recording.waveform),
          const SizedBox(height: AppSpacing.lg),
          Text(
            formatDuration(recording.duration),
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            meta,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // Reprendre suppose la capture audio, qui attend le moteur (Q2).
              onPressed: null,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
              child: Text(text.transcriptionResume),
            ),
          ),
          if (!recording.hasAudio) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              text.transcriptionAudioDeleted,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un texte convoqué pendant la prédication.
class _ConvokedView extends StatelessWidget {
  const _ConvokedView({required this.scripture});

  final ConvokedScripture scripture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    return RuledContent(
      color: colors.success,
      gap: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${convocationKindLabel(text, scripture.kind)}'
            ' · ${formatDuration(scripture.at)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.success,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PassageView(passage: scripture.passage, rule: false),
          const SizedBox(height: AppSpacing.xs),
          Text(
            scripture.wasPlanned
                ? text.transcriptionPlanned(scripture.passage.referenceLabel)
                : text.transcriptionUnplanned(scripture.passage.referenceLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un constat d'Urim, au filet pointillé.
class _RemarkView extends StatelessWidget {
  const _RemarkView({required this.remark});

  final TranscriptionRemark remark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return DottedRuledContent(
      color: colors.textSecondary,
      gap: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            remark.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            remark.body,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

/// Ce qu'Urim ne fait pas : séparer les locuteurs.
class _SpeakerNotice extends StatelessWidget {
  const _SpeakerNotice();

  @override
  Widget build(BuildContext context) => NoticeBox(
        text: AppText.of(context).transcriptionSpeakerNotice,
      );
}

/// Encadré d'information — une réserve, jamais une alerte.
class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({required this.preparationId});

  final String preparationId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton(
          // Corriger suppose un éditeur de transcription, donc une
          // transcription (Q2).
          onPressed: null,
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          child: Text(AppText.of(context).transcriptionFixText),
        ),
        OutlinedButton(
          onPressed: () => context.pushNamed(
            AppRoutes.synthesisName,
            pathParameters: {'id': preparationId},
          ),
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          child: Text(AppText.of(context).transcriptionSeeSynthesis),
        ),
        OutlinedButton(
          onPressed: () => context.pushNamed(
            AppRoutes.preparationName,
            pathParameters: {'id': preparationId},
          ),
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          child: Text(AppText.of(context).transcriptionOpenPreparation),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          AppText.of(context).transcriptionNotFound,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
        ),
      ),
    );
  }
}

/// « Deux fragments attendent le réseau », et l'accord qui va avec.
///
/// L'accord est porté par le format ARB, plus par une fonction écrite à la
/// main : une langue qui compte autrement n'aura pas à réécrire de code.
String _pendingSentence(AppText text, int pending) => pending == 0
    ? text.transcriptionAllAcknowledged
    : text.transcriptionFragmentsPending(pending);
