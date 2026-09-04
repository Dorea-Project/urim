import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/audio/piece_store.dart';
import 'package:urim/core/audio/track_player.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/transcription/sermon_piece.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/home/widgets/capture_bar.dart'
    show formatElapsed;
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Ce qu'un culte a produit — **et ce qui lui survivra**.
///
/// 🔴 **La phrase qui compte dans cet écran n'est pas la liste, c'est la
/// promesse.** L'audio brut disparaît au septième jour ; une pièce, non. Un
/// pasteur qui ne le sait pas ne découpera pas à temps, et découvrira la règle
/// le jour où elle s'applique — trop tard pour agir.
class PiecesList extends ConsumerWidget {
  const PiecesList({super.key, required this.captureId});

  final String captureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final couleurs = context.colors;
    final styles = Theme.of(context).textTheme;
    final pieces = ref.watch(piecesDeLaCaptureProvider(captureId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          text.piecesTitle.toUpperCase(),
          style: styles.labelSmall
              ?.copyWith(color: couleurs.textSecondary, letterSpacing: 1.1),
        ),
        const SizedBox(height: AppSpacing.md),

        switch (pieces) {
          AsyncData(:final value) when value.isEmpty => Text(
              text.piecesEmpty,
              style: styles.bodyMedium?.copyWith(color: couleurs.textSecondary),
            ),
          AsyncData(:final value) => Column(
              children: [
                for (final piece in value) _Piece(piece: piece),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  text.piecesSurvives,
                  style: styles.bodySmall?.copyWith(color: couleurs.success),
                ),
              ],
            ),
          _ => const SizedBox.shrink(),
        },

        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => context.pushNamed(
            AppRoutes.pieceEditorName,
            pathParameters: {'id': captureId},
          ),
          icon: const Icon(Icons.content_cut, size: 18),
          label: Text(text.piecesCut),
        ),
      ],
    );
  }
}

class _Piece extends ConsumerStatefulWidget {
  const _Piece({required this.piece});

  final SermonPiece piece;

  @override
  ConsumerState<_Piece> createState() => _PieceState();
}

class _PieceState extends ConsumerState<_Piece> {
  bool _joue = false;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final couleurs = context.colors;
    final styles = Theme.of(context).textTheme;
    final piece = widget.piece;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: couleurs.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(piece.title, style: styles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatElapsed(piece.duration)} · '
                  '${text.piecesFrom(formatElapsed(piece.start), formatElapsed(piece.end))}',
                  style: styles.bodySmall?.copyWith(
                    color: couleurs.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _basculer,
            icon: Icon(_joue ? Icons.stop : Icons.play_arrow),
            tooltip: _joue ? text.piecesStop : text.piecesPlay,
          ),
        ],
      ),
    );
  }

  Future<void> _basculer() async {
    final lecteur = ref.read(trackPlayerProvider);

    if (_joue) {
      await lecteur.stop();
      if (mounted) setState(() => _joue = false);
      return;
    }

    final refus = await lecteur.play(widget.piece.path);
    if (mounted) setState(() => _joue = refus == null);
  }
}
