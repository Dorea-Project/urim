import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/audio/file_sharer.dart';
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
          IconButton(
            onPressed: _envoyer,
            icon: const Icon(Icons.ios_share),
            tooltip: text.piecesShare,
          ),
          PopupMenuButton<_Geste>(
            onSelected: _choisir,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _Geste.renommer,
                child: Text(text.piecesRename),
              ),
              PopupMenuItem(
                value: _Geste.supprimer,
                child: Text(text.piecesDelete),
              ),
            ],
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

  /// Propose la pièce aux applications du téléphone.
  ///
  /// ⚠️ **Un refus se lit, il ne se devine pas.** Le pasteur appuie et attend ;
  /// si rien ne s'ouvre, il doit apprendre pourquoi plutôt que de conclure que
  /// l'application est cassée. Une feuille qu'il referme lui-même, en revanche,
  /// n'est pas un échec et ne dit rien.
  Future<void> _envoyer() async {
    final text = AppText.of(context);
    final refus = await ref.read(fileSharerProvider).partager(
          widget.piece.path,
          titre: widget.piece.title,
        );

    if (!mounted || refus == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          refus == ShareRefusal.fileMissing
              ? text.piecesShareMissing
              : text.piecesShareFailed,
        ),
      ),
    );
  }

  Future<void> _choisir(_Geste geste) async {
    switch (geste) {
      case _Geste.renommer:
        await _renommer();
      case _Geste.supprimer:
        await _supprimer();
    }
  }

  Future<void> _renommer() async {
    final nouveau = await showDialog<String>(
      context: context,
      builder: (_) => _Renommage(initial: widget.piece.title),
    );

    if (nouveau == null || !mounted) return;

    await ref.read(pieceStoreProvider).renommer(widget.piece.id, nouveau);
    if (mounted) {
      ref.invalidate(piecesDeLaCaptureProvider(widget.piece.captureId));
    }
  }

  /// 🔴 **Le seul geste irréversible de cet écran, et il se confirme.**
  ///
  /// Une pièce supprimée ne se retaille pas : si le culte a passé ses sept
  /// jours, la matière dont elle est tirée n'existe plus. La confirmation le
  /// dit — elle ne demande pas « êtes-vous sûr », elle explique ce qui se perd.
  Future<void> _supprimer() async {
    final text = AppText.of(context);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.piecesDeleteTitle),
        content: Text(text.piecesDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(text.piecesRenameCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(text.piecesDelete),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    await ref.read(trackPlayerProvider).stop();
    await ref.read(pieceStoreProvider).remove(widget.piece.id);
    if (mounted) {
      ref.invalidate(piecesDeLaCaptureProvider(widget.piece.captureId));
    }
  }
}

enum _Geste { renommer, supprimer }

/// La boîte qui renomme — **et qui possède son propre champ**.
///
/// ⚠️ **Un contrôleur libéré par l'appelant est un défaut, pas un détail.** Une
/// boîte de dialogue ne disparaît pas à l'instant où elle rend sa valeur : elle
/// se referme en s'animant, et le champ se reconstruit pendant ce temps. Libérer
/// le contrôleur juste après `showDialog` fait donc lever *« a
/// TextEditingController was used after being disposed »* — au mieux une trace
/// rouge, au pire un écran cassé. La boîte le tient, la boîte le libère.
class _Renommage extends StatefulWidget {
  const _Renommage({required this.initial});

  final String initial;

  @override
  State<_Renommage> createState() => _RenommageState();
}

class _RenommageState extends State<_Renommage> {
  late final _champ = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);

    return AlertDialog(
      title: Text(text.piecesRename),
      content: TextField(
        controller: _champ,
        autofocus: true,
        decoration: InputDecoration(hintText: text.editorNameHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.piecesRenameCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_champ.text),
          child: Text(text.piecesRenameSave),
        ),
      ],
    );
  }
}
