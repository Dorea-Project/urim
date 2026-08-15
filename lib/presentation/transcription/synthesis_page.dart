import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/domain/entities/transcription/synthesis_draft.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/preparation/widgets/block_views.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/transcription/transcription_page.dart';
import 'package:urim/presentation/transcription/transcription_view_model.dart';

/// Synthèse d'une prédication, avant validation.
///
/// Tout l'écran tient sur une seule règle : **rien ne sort tant que ce n'est
/// pas validé**. La lecture à voix haute est donc affichée mais fermée, et le
/// bandeau du haut le dit avant tout le reste.
class SynthesisPage extends ConsumerWidget {
  const SynthesisPage({super.key, required this.preparationId});

  final String preparationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synthesis = ref.watch(synthesisProvider(preparationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          synthesis.value?.isValidated ?? false
              ? 'Synthèse — validée'
              : 'Synthèse — à valider',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: switch (synthesis) {
          AsyncData(:final value) =>
            _SynthesisBody(synthesis: value, preparationId: preparationId),
          AsyncError() => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text('Cette prédication n\'a pas de synthèse.'),
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _SynthesisBody extends ConsumerWidget {
  const _SynthesisBody({required this.synthesis, required this.preparationId});

  final SynthesisDraft synthesis;
  final String preparationId;

  Future<void> _validate(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(synthesisValidatorProvider.notifier)
        .validate(preparationId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? 'Synthèse validée. Elle peut maintenant être lue.'
              : failure.message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _SealBanner(isValidated: synthesis.isValidated),
        const SizedBox(height: AppSpacing.xl),

        _Label('Ce qu\'Urim a retenu'),
        for (var i = 0; i < synthesis.capsules.length; i++) ...[
          _CapsuleView(index: i + 1, capsule: synthesis.capsules[i]),
          const SizedBox(height: AppSpacing.lg),
        ],

        const SizedBox(height: AppSpacing.sm),
        _Label('Le verset, non réécrit'),
        PassageView(passage: synthesis.verse),
        const SizedBox(height: AppSpacing.xl),

        const NoticeBox(
          text: 'Les capsules sont écrites par un modèle à partir de ta '
              'transcription. Les versets, eux, viennent de la Bible — jamais '
              'du modèle. Relis avant de valider.',
        ),
        const SizedBox(height: AppSpacing.xl),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: synthesis.isValidated
                ? null
                : () => _validate(context, ref),
            child: Text(
              synthesis.isValidated
                  ? 'Synthèse validée'
                  : 'Valider cette synthèse',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        _Label('Lire à voix haute'),
        Text(
          'Pour ceux de l\'assemblée qui écouteront plutôt que de lire.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _VoiceList(synthesis: synthesis),
        const SizedBox(height: AppSpacing.md),
        Text(
          synthesis.canBeReadAloud
              ? 'La lecture reprend la synthèse telle que tu l\'as validée.'
              : 'Disponible une fois la synthèse validée.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// « Rien n'est encore parti. »
class _SealBanner extends StatelessWidget {
  const _SealBanner({required this.isValidated});

  final bool isValidated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return RuledContent(
      color: isValidated ? colors.success : theme.colorScheme.primary,
      gap: AppSpacing.md,
      child: Container(
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
              isValidated ? 'Validée par toi.' : 'Rien n\'est encore parti.',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isValidated
                  ? 'Elle peut être lue à voix haute. Tu restes le seul à '
                      'pouvoir la modifier.'
                  : 'Tant que tu n\'as pas validé, cette synthèse n\'existe '
                      'que pour toi. Aucun membre ne la voit, aucune voix ne '
                      'la lit.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une capsule, avec le moment où elle a été dite.
class _CapsuleView extends StatelessWidget {
  const _CapsuleView({required this.index, required this.capsule});

  final int index;
  final SynthesisCapsule capsule;

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
            'CAPSULE $index · DIT À ${formatDuration(capsule.saidAt)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            capsule.text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              foregroundColor: colors.success,
            ),
            // Retourner au moment exact suppose l'audio, effacé après
            // transcription, et un lecteur qui n'existe pas encore.
            onPressed: null,
            child: const Text('Voir où c\'est dit dans ta prédication'),
          ),
        ],
      ),
    );
  }
}

/// Les lectures proposées, fermées tant que rien n'est validé.
class _VoiceList extends StatelessWidget {
  const _VoiceList({required this.synthesis});

  final SynthesisDraft synthesis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < synthesis.voices.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Divider(color: colors.border, height: 1),
              ),
            _VoiceRow(
              voice: synthesis.voices[i],
              enabled: synthesis.canBeReadAloud,
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceRow extends StatelessWidget {
  const _VoiceRow({required this.voice, required this.enabled});

  final ReadAloudVoice voice;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final note = [
      voice.note,
      if (voice.duration case final Duration duration)
        formatSpokenDuration(duration),
    ].join(' · ');

    final isOwnVoice = voice.kind == ReadAloudKind.ownVoice;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voice.language,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: enabled ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _VoiceButton(
            icon: isOwnVoice ? Icons.mic_none : Icons.play_arrow,
            // Rien ne se lit avant validation ; et même après, ni la synthèse
            // vocale ni les traductions n'existent encore (Q3).
            enabled: false,
            tooltip: enabled
                ? 'Lecture à venir'
                : 'Disponible une fois la synthèse validée',
          ),
        ],
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.icon,
    required this.enabled,
    required this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? scheme.primary
              : scheme.primary.withValues(alpha: 0.35),
        ),
        child: Icon(icon, size: 22, color: scheme.onPrimary),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

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

/// « 2 min 40 » — une durée de lecture ne se lit pas comme un chronomètre.
String formatSpokenDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;

  return seconds == 0 ? '$minutes min' : '$minutes min $seconds';
}
