import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/home/capture_view_model.dart'
    show localCapturesProvider;
import 'package:urim/presentation/home/widgets/capture_bar.dart'
    show formatElapsed;
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/transcription/piece_editor_view_model.dart';
import 'package:urim/presentation/transcription/widgets/waveform_view.dart';

/// L'éditeur — **où un culte de quatre-vingt-dix minutes devient deux pièces**.
///
/// Le pasteur enregistre d'un seul tenant : une heure de prédication enchaînée
/// par trente minutes de prière, avec du bruit et des chants au démarrage. Il
/// publie la prière le mardi, la prédication le vendredi. Entre les deux, il
/// lui faut cet écran, et rien d'autre.
///
/// ## Trois choix d'interface, et chacun vient d'une contrainte réelle
///
/// 🔴 **On pose les bornes à la tête de lecture, on ne les tire pas.** Une heure
/// et demie sur un téléphone fait huit secondes par pixel : une poignée qu'on
/// traîne au doigt couvre une minute de prédication. Le geste juste est
/// d'écouter, de s'arrêter à la frontière, puis d'appuyer sur « début ici ».
/// L'onde sert à viser grossièrement ; **l'oreille tranche**.
///
/// ⚠️ **Deux ondes, pas une.** Celle du haut montre le culte entier — *où l'on
/// est* — avec le cadre de ce qu'on regarde ; celle du bas est zoomée et permet
/// de viser. Avec une seule, il faudrait choisir entre se repérer et être
/// précis, et on perdrait les deux.
///
/// ✅ **L'écran dit que rien n'est détruit.** Tailler écrit une pièce à côté ; la
/// matière reste entière jusqu'à sa purge. Un pasteur qui craint d'effacer son
/// dimanche n'osera pas couper — et un éditeur qu'on n'ose pas utiliser ne sert
/// à rien.
class PieceEditorPage extends ConsumerWidget {
  const PieceEditorPage({super.key, required this.captureId});

  final String captureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    // Le dossier se résout ici, pas dans la route : un chemin de fichier n'a
    // rien à faire dans une URL, et `CaptureShell` résout déjà par identifiant.
    final captures = ref.watch(localCapturesProvider);
    final capture = captures.value
        ?.where((c) => c.id == captureId)
        .cast<CapturedSermon?>()
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(text.editorTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: text.back,
        ),
      ),
      body: SafeArea(
        child: switch (captures) {
          AsyncLoading() => _Attente(motif: text.editorPreparing),
          _ when capture == null => _Attente(motif: text.editorEmpty),
          _ => _Editeur(cheminCapture: capture.path),
        },
      ),
    );
  }
}

class _Editeur extends ConsumerWidget {
  const _Editeur({required this.cheminCapture});

  final String cheminCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final etat = ref.watch(pieceEditorProvider(cheminCapture));

    return switch (etat) {
      AsyncLoading() => _Attente(motif: text.editorPreparing),
      AsyncError() => _Attente(motif: text.editorEmpty),
      AsyncData(:final value) when value.onde.estVide =>
        _Attente(motif: text.editorEmpty),
      AsyncData(:final value) => _Etabli(
          etat: value,
          modele: ref.read(pieceEditorProvider(cheminCapture).notifier),
        ),
    };
  }
}

class _Attente extends StatelessWidget {
  const _Attente({required this.motif});

  final String motif;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            motif,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.colors.textSecondary),
          ),
        ),
      );
}

class _Etabli extends StatelessWidget {
  const _Etabli({required this.etat, required this.modele});

  final EditeurState etat;
  final PieceEditorViewModel modele;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final couleurs = context.colors;
    final styles = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        // ── Le culte entier : où l'on est ────────────────────────────────
        WaveformOverview(
          frame: WaveformFrame(
            onde: etat.onde,
            debut: Duration.zero,
            fin: etat.duree,
            tete: etat.tete,
            selDebut: etat.selDebut,
            selFin: etat.selFin,
          ),
          fenetreDebut: etat.fenetreDebut,
          fenetreFin: etat.fenetreFin,
          onPointe: modele.cadrerSur,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          text.editorPosition(
            formatElapsed(etat.tete),
            formatElapsed(etat.duree),
          ),
          style: styles.labelMedium?.copyWith(
            color: couleurs.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Le détail : où l'on vise ─────────────────────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            color: couleurs.surfaceWarm,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: couleurs.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: WaveformView(
              frame: WaveformFrame(
                onde: etat.onde,
                debut: etat.fenetreDebut,
                fin: etat.fenetreFin,
                tete: etat.tete,
                selDebut: etat.selDebut,
                selFin: etat.selFin,
              ),
              onPointe: modele.allerA,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => modele.zoomer(2),
              icon: const Icon(Icons.zoom_out),
              tooltip: text.editorZoomOut,
            ),
            IconButton(
              onPressed: () => modele.zoomer(.5),
              icon: const Icon(Icons.zoom_in),
              tooltip: text.editorZoomIn,
            ),
          ],
        ),

        // ── Le transport ─────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () =>
                  modele.deplacer(const Duration(seconds: -10)),
              icon: const Icon(Icons.replay_10),
              iconSize: 30,
              tooltip: text.editorBack,
            ),
            const SizedBox(width: AppSpacing.lg),
            FilledButton(
              onPressed: modele.lireOuPause,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
              child: Icon(
                etat.joue ? Icons.pause : Icons.play_arrow,
                size: 30,
                semanticLabel: etat.joue ? text.editorPause : text.editorPlay,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            IconButton(
              onPressed: () => modele.deplacer(const Duration(seconds: 10)),
              icon: const Icon(Icons.forward_10),
              iconSize: 30,
              tooltip: text.editorForward,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),
        Text(
          text.editorGesture,
          textAlign: TextAlign.center,
          style: styles.bodySmall?.copyWith(color: couleurs.textSecondary),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Poser les bornes ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: modele.poserDebut,
                icon: const Icon(Icons.first_page, size: 18),
                label: Text(text.editorSetStart),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: modele.poserFin,
                icon: const Icon(Icons.last_page, size: 18),
                label: Text(text.editorSetEnd),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),
        _Recapitulatif(etat: etat, modele: modele),

        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: etat.selectionUtile && !etat.taille
              ? () => modele.tailler()
              : null,
          child: Text(etat.taille ? text.editorCutting : text.editorCut),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          etat.selectionUtile ? text.editorSafety : text.editorTooShort,
          textAlign: TextAlign.center,
          style: styles.bodySmall?.copyWith(color: couleurs.textSecondary),
        ),
      ],
    );
  }
}

/// Ce qui sera taillé, et de quoi le vérifier avant de le faire.
class _Recapitulatif extends StatelessWidget {
  const _Recapitulatif({required this.etat, required this.modele});

  final EditeurState etat;
  final PieceEditorViewModel modele;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final couleurs = context.colors;
    final styles = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;

    final taillee = etat.derniere != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: taillee
            ? couleurs.success.withValues(alpha: .08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: taillee ? couleurs.success : couleurs.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.editorPiece.toUpperCase(),
              style: styles.labelSmall?.copyWith(
                color: couleurs.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    text.editorRange(
                      formatElapsed(etat.selDebut),
                      formatElapsed(etat.selFin),
                    ),
                    style: styles.titleMedium?.copyWith(
                      color: couleurs.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  text.editorLength(formatElapsed(etat.selectionDuree)),
                  style: styles.bodySmall?.copyWith(
                    color: schema.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Vérifier une borne à l'oreille : posée à l'œil, elle tombe
            // souvent au milieu d'un mot, et rien ne le dit à l'écran.
            Row(
              children: [
                TextButton(
                  onPressed: () => modele.ecouterLaCoupe(etat.selDebut),
                  child: Text(text.editorHearStart),
                ),
                TextButton(
                  onPressed: () => modele.ecouterLaCoupe(etat.selFin),
                  child: Text(text.editorHearEnd),
                ),
              ],
            ),

            if (taillee) ...[
              const Divider(height: AppSpacing.xl),
              Text(
                text.editorCutDone,
                style: styles.bodySmall
                    ?.copyWith(color: couleurs.textPrimary),
              ),
              if (etat.resteApres) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: modele.enchainer,
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: Text(text.editorNext),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
