import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/presentation/common/french_dates.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/settings/settings_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/theme/app_typography.dart';

/// Affiche un bloc du fil, quelle que soit sa nature.
///
/// Le `switch` est exhaustif sur un type scellé : ajouter une nature de bloc
/// fera échouer la compilation ici, ce qui est exactement le rappel voulu.
///
/// [isLive] distingue le dernier tour du reste : seules les réponses encore
/// attendues sont cliquables. Plus haut dans le fil, la question a déjà reçu
/// sa réponse — la reposer réécrirait l'histoire.
class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.block, this.isLive = false});

  final PreparationBlock block;
  final bool isLive;

  @override
  Widget build(BuildContext context) => switch (block) {
        UserBlock() => _UserSaid(block: block as UserBlock),
        UrimTurn() => _UrimSaid(turn: block as UrimTurn, isLive: isLive),
        ScriptureBlock() => _ScriptureQuote(block: block as ScriptureBlock),
        SynthesisBlock() => _SynthesisView(block: block as SynthesisBlock),
      };
}

/// Ce que l'utilisateur a écrit : une bulle pleine, calée à droite.
class _UserSaid extends StatelessWidget {
  const _UserSaid({required this.block});

  final UserBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              block.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onInverseSurface,
                    height: 1.5,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un tour d'Urim : le filet pointillé, la carte, et la trace repliée.
class _UrimSaid extends StatefulWidget {
  const _UrimSaid({required this.turn, required this.isLive});

  final UrimTurn turn;
  final bool isLive;

  @override
  State<_UrimSaid> createState() => _UrimSaidState();
}

class _UrimSaidState extends State<_UrimSaid> {
  bool _traceShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final turn = widget.turn;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'URIM',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DottedRuledContent(
            color: colors.textSecondary,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Le raisonnement d'abord, en gris : c'est le chemin, pas la
                  // réponse.
                  if (turn.reasoning case final String reasoning)
                    Text(
                      reasoning,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  if (turn.statement case final String statement) ...[
                    if (turn.reasoning != null)
                      const SizedBox(height: AppSpacing.lg),
                    Text(
                      statement,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                  ],
                  for (final text in turn.texts) ...[
                    const SizedBox(height: AppSpacing.md),
                    _WeighedTextCard(text: text),
                  ],
                  if (turn.passage case final QuotedPassage passage) ...[
                    const SizedBox(height: AppSpacing.lg),
                    PassageView(passage: passage),
                  ],
                  if (turn.question case final String question) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      question,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                  ],
                  for (final choice in turn.choices) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ChoiceCard(choice: choice, isLive: widget.isLive),
                  ],
                  if (turn.moreLabel case final String more) ...[
                    const SizedBox(height: AppSpacing.md),
                    _MoreLink(label: more),
                  ],
                ],
              ),
            ),
          ),
          // « Comment j'en suis arrivé là » : replié, mais toujours là. C'est
          // ce qui distingue une proposition d'un oracle.
          if (turn.trace case final String trace) ...[
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () => setState(() => _traceShown = !_traceShown),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _traceShown ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Comment j\'en suis arrivé là',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_traceShown)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xl,
                  top: AppSpacing.xs,
                  right: AppSpacing.sm,
                ),
                child: Text(
                  trace,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Un texte pesé : ce qu'il fait à la lecture, puis sa référence.
class _WeighedTextCard extends StatelessWidget {
  const _WeighedTextCard({required this.text});

  final WeighedText text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    // Ce qui résiste porte la teinte d'alerte **et** un signe : la couleur
    // seule ne se voit pas pour tout le monde.
    final stanceColor =
        text.stance.resists ? theme.colorScheme.error : colors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (text.stance.resists) ...[
                Icon(Icons.warning_amber_rounded, size: 15, color: stanceColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  text.stance.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: stanceColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(text.referenceLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            text.note,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une réponse proposée. Cliquable tant que la question est la dernière posée.
class _ChoiceCard extends ConsumerWidget {
  const _ChoiceCard({required this.choice, required this.isLive});

  final TurnChoice choice;
  final bool isLive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            choice.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isLive ? colors.textPrimary : colors.textSecondary,
            ),
          ),
          if (choice.detail case final String detail) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );

    if (!isLive) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => ChoiceAnswer.of(context)?.call(choice.label),
      child: card,
    );
  }
}

/// Transporte la réponse choisie jusqu'au fil, sans faire descendre
/// l'identifiant de la préparation dans chaque widget.
class ChoiceAnswer extends InheritedWidget {
  const ChoiceAnswer({super.key, required this.onAnswer, required super.child});

  final ValueChanged<String> onAnswer;

  static ValueChanged<String>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ChoiceAnswer>()
      ?.onAnswer;

  @override
  bool updateShouldNotify(ChoiceAnswer oldWidget) =>
      oldWidget.onAnswer != onAnswer;
}

/// « Voir les dix loci → ».
class _MoreLink extends StatelessWidget {
  const _MoreLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        minimumSize: const Size(0, 36),
      ),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                'La liste des loci n\'est pas encore écrite. Les trois axes '
                'proposés viennent de ta phrase ; les sept autres attendent '
                'que le moteur existe.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: sheetContext.colors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
      child: Text('$label →'),
    );
  }
}

/// Un passage cité : le texte en police de lecture, puis sa provenance.
///
/// Public : le fil, la transcription et la synthèse l'affichent de la même
/// façon, et c'est voulu — un verset ne change pas d'allure selon l'écran qui
/// le montre.
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

/// Un passage posé seul dans le fil.
class _ScriptureQuote extends StatelessWidget {
  const _ScriptureQuote({required this.block});

  final ScriptureBlock block;

  @override
  Widget build(BuildContext context) {
    final label = switch (block.provenance) {
      ScriptureProvenance.cited => 'ÉCRITURE',
      ScriptureProvenance.recognizedInRecording =>
        'RECONNU DANS LA CITATION · ${formatAnchor(block.anchor)}',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.success,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PassageView(passage: block.passage),
        ],
      ),
    );
  }
}

/// La synthèse proposée par Urim.
class _SynthesisView extends StatelessWidget {
  const _SynthesisView({required this.block});

  final SynthesisBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYNTHÈSE D\'URIM',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DottedRuledContent(
            color: colors.textSecondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.lead,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < block.points.length; i++) ...[
                  _SynthesisPointView(index: i + 1, point: block.points[i]),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Jamais optionnel : le modèle impose la réserve, l'écran
                // l'affiche.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        block.caution,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SynthesisPointView extends StatelessWidget {
  const _SynthesisPointView({required this.index, required this.point});

  final int index;
  final SynthesisPoint point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$index.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: point.heading,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.55,
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: point.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                    height: 1.55,
                  ),
                ),
                if (point.isAnchoredInMedia)
                  TextSpan(
                    text: '  — ${formatDuration(point.from!)}'
                        ' à ${formatDuration(point.to!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
String formatAnchor(BlockAnchor anchor, {DateTime? now}) => switch (anchor) {
      MediaAnchor(:final offset) => formatDuration(offset),
      ClockAnchor(:final at) => _formatClock(at, now ?? DateTime.now()),
    };

String _formatClock(DateTime at, DateTime now) {
  final time = '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final difference = today.difference(day).inDays;

  return switch (difference) {
    0 => 'AUJOURD\'HUI $time',
    1 => 'HIER $time',
    _ => '${frenchDayMonth(at).toUpperCase()} $time',
  };
}
