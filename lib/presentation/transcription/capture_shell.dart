import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/audio/capture_playback.dart';
import 'package:urim/core/audio/capture_store.dart';
import 'package:urim/core/audio/track_player.dart';
import 'package:urim/core/speech/transcriber.dart';
import 'package:urim/presentation/transcription/transcription_capture_view_model.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/presentation/home/capture_view_model.dart';
import 'package:urim/presentation/home/widgets/capture_bar.dart' show formatElapsed;
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/transcription/widgets/pieces_list.dart';

/// Un culte capté, ouvert — **et le cul-de-sac qu'il n'est plus**.
///
/// 🔴 **Jusqu'au 29/08, une capture ne s'ouvrait sur rien.** Sa carte d'accueil
/// était un `Container`, pas un bouton : elle disait la date, la durée, le jour
/// de la purge, et s'arrêtait là. Le choix se défendait — *annoncer un
/// transcript qui n'existe pas serait mentir* — mais il produisait pire qu'un
/// mensonge : **un objet du produit sur lequel aucun geste n'existe**.
///
/// Cette coque le remplace par la vérité complète. Trois onglets, comme pour une
/// préparation — le premier dit l'état du culte, le deuxième est **fermé en
/// disant pourquoi** (D13), et le troisième offre d'en tailler des pièces.
///
/// ## Ce que le premier onglet montre, faute de transcript
///
/// ⚠️ **Il n'est pas vide, et c'est le point.** Ce qu'on sait d'une capture est
/// réel : sa durée, ses fragments, le fait qu'elle ne quitte pas ce téléphone,
/// et le jour où l'audio disparaît.
///
/// ⛔ **Il disait aussi ce qui était monté et ce qui attendait le réseau. Plus
/// maintenant** (D71, 06/09) : la montée automatique a été coupée, faute de
/// lecteur — le port `FragmentStore` n'a que `put` et `purge`. Ces trois
/// phrases seraient devenues fausses, et une phrase fausse sur le sort d'un
/// culte est pire qu'une phrase absente.
class CaptureShell extends ConsumerWidget {
  const CaptureShell({super.key, required this.captureId});

  final String captureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final captures = ref.watch(localCapturesProvider);

    final capture = captures.value
        ?.where((c) => c.id == captureId)
        .cast<CapturedSermon?>()
        .firstOrNull;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            capture == null
                ? text.transcriptionFallbackTitle
                : capture.title ??
                    text.captureUnnamed(frenchShortDate(capture.startedAt)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            tooltip: text.back,
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: text.sermonTabSaid),
              Tab(text: text.sermonTabSynthesis),
              Tab(text: text.sermonTabOutput),
            ],
          ),
        ),
        body: SafeArea(
          child: switch (captures) {
            AsyncData() when capture == null =>
              _Attend(motif: text.transcriptionNotFound),
            AsyncData() => TabBarView(
                children: [
                  _EtatDeLaCapture(capture: capture!),
                  _Attend(motif: text.captureSynthesisPending),
                  // 🔴 **L'onglet n'attend plus rien** (D70). La sortie d'un
                  // culte n'est pas une synthèse validée : ce sont les pièces
                  // qu'on en taille, et elles ne demandent aucun modèle.
                  PiecesList(captureId: captureId),
                ],
              ),
            AsyncError() => _Attend(motif: text.transcriptionNotFound),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

/// Le premier onglet — **ce qu'on sait vraiment**, à défaut du texte.
class _EtatDeLaCapture extends ConsumerWidget {
  const _EtatDeLaCapture({required this.capture});

  final CapturedSermon capture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    final jours = capture.purgeAt.difference(ref.watch(clockProvider).now()).inDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          text.captureSectionState,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _Ligne(icone: Icons.schedule, texte: text.captureDuration(formatElapsed(capture.duration))),
        _Ligne(icone: Icons.graphic_eq, texte: text.captureFragments(capture.fragments)),

        // ⛔ **Il n'y a plus d'état d'envoi** (D71, 06/09). Cette ligne disait
        // « tout est arrivé au serveur », « 3 fragments attendent de partir »,
        // ou « rien ne partira faute d'assemblée ». Les trois sont devenues
        // fausses le jour où la montée automatique a été coupée — et une phrase
        // fausse sur le sort d'un culte est pire qu'une phrase absente.
        //
        // Rien ne la remplace ici : l'encadré plus bas dit déjà la seule chose
        // vraie — l'audio est sur ce téléphone, et nulle part ailleurs.
        if (capture.interrupted)
          _Ligne(
            icone: Icons.warning_amber_outlined,
            texte: text.captureInterrupted,
            couleur: colors.textSecondary,
          ),

        _Ligne(
          icone: Icons.auto_delete_outlined,
          texte: text.capturePurgeIn(jours < 0 ? 0 : jours),
          couleur: theme.colorScheme.error,
        ),

        const SizedBox(height: AppSpacing.md),
        _Reecoute(capture: capture),

        const SizedBox(height: AppSpacing.md),
        _Nommer(capture: capture),

        const SizedBox(height: AppSpacing.xl),
        _Encadre(texte: text.captureLocalOnly),
        const SizedBox(height: AppSpacing.lg),
        _Transcription(capture: capture),
      ],
    );
  }
}

/// 🔴 **Le seul geste que « prêcher » offre aujourd'hui.**
///
/// Le pasteur entend ce qu'il a dit, sans attendre le moteur de transcription,
/// sans serveur, sans réseau. C'est peu et c'est beaucoup : jusqu'ici, l'audio
/// d'un culte existait sur le téléphone **sans qu'aucun écran ne sache le
/// jouer** — il montait au serveur, il se purgeait au septième jour, et son
/// auteur ne l'entendait jamais.
class _Reecoute extends ConsumerStatefulWidget {
  const _Reecoute({required this.capture});

  final CapturedSermon capture;

  @override
  ConsumerState<_Reecoute> createState() => _ReecouteState();
}

class _ReecouteState extends ConsumerState<_Reecoute> {
  bool _prepare = false;
  bool _joue = false;
  bool _enPause = false;
  Duration _ou = Duration.zero;
  Duration? _totale;

  /// Où le doigt tient le curseur, ou nul si personne ne le tient.
  Duration? _glisse;

  StreamSubscription<void>? _fin;
  StreamSubscription<Duration>? _position;
  StreamSubscription<Duration>? _duree;

  @override
  void initState() {
    super.initState();
    final lecteur = ref.read(trackPlayerProvider);

    // Sans ça, le bouton resterait sur « arrêter » après la dernière seconde.
    _fin = lecteur.onComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _joue = false;
        _enPause = false;
        _ou = Duration.zero;
      });
    });

    _position = lecteur.onPosition.listen((ou) {
      if (mounted) setState(() => _ou = ou);
    });
    _duree = lecteur.onDuration.listen((totale) {
      if (mounted) setState(() => _totale = totale);
    });
  }

  @override
  void dispose() {
    _fin?.cancel();
    _position?.cancel();
    _duree?.cancel();
    super.dispose();
  }

  Future<void> _basculer() async {
    final messager = ScaffoldMessenger.of(context);
    final text = AppText.of(context);
    final lecteur = ref.read(trackPlayerProvider);

    // 🔴 **Pause, et non arrêt.** Un pasteur qui relit quarante minutes
    // s'interrompt — on lui parle, il note quelque chose. Le renvoyer au début
    // à chaque reprise rendrait la relecture d'un long sermon impraticable.
    if (_joue) {
      await lecteur.pause();
      if (mounted) setState(() { _joue = false; _enPause = true; });
      return;
    }

    if (_enPause) {
      await lecteur.resume();
      if (mounted) setState(() { _joue = true; _enPause = false; });
      return;
    }

    setState(() => _prepare = true);

    // ⚠️ **L'assemblage peut prendre une seconde ou deux** — quarante minutes
    // de culte pèsent 77 Mo. L'écran le dit plutôt que de paraître figé.
    final chemin =
        await ref.read(capturePlaybackProvider).preparer(widget.capture.path);

    if (!mounted) return;
    setState(() => _prepare = false);

    if (chemin == null) {
      messager.showSnackBar(SnackBar(content: Text(text.captureListenEmpty)));
      return;
    }

    final refus = await lecteur.play(chemin);
    if (!mounted) return;

    if (refus != null) {
      messager.showSnackBar(SnackBar(content: Text(text.captureListenFailed)));
      return;
    }
    setState(() { _joue = true; _enPause = false; });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    // La durée du fichier tant que le lecteur ne l'a pas lue : celle que la
    // capture connaît déjà. Un « 0:00 / 0:00 » avant la première lecture aurait
    // dit que l'enregistrement est vide.
    final totale = _totale ?? widget.capture.duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: _prepare ? null : _basculer,
            icon: Icon(_joue ? Icons.pause : Icons.play_arrow),
            label: Text(
              _prepare
                  ? text.captureListenPreparing
                  : _joue
                      ? text.captureListenPause
                      : _enPause
                          ? text.captureListenResume
                          : text.captureListen,
            ),
          ),
        ),

        // ⚠️ **La barre n'apparaît qu'une fois la lecture commencée.** Avant,
        // elle annoncerait une position qui n'existe pas.
        if (_joue || _enPause) ...[
          const SizedBox(height: AppSpacing.sm),

          // 🔴 **Déplaçable, et pas seulement indicatif.** Une prédication de
          // deux heures ne se réécoute pas depuis le début : le pasteur revient
          // sur un passage, vérifie une citation, reprend après une
          // interruption. Sans curseur, atteindre la centième minute demande
          // d'écouter les quatre-vingt-dix-neuf premières.
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: (_glisse ?? _ou).inMilliseconds.toDouble().clamp(
                    0,
                    totale.inMilliseconds.toDouble(),
                  ),
              max: totale.inMilliseconds.toDouble(),
              // ⚠️ **Pendant le glissement, l'écran suit le doigt, pas le
              // lecteur.** Sans ça, le flux de position ramènerait le curseur en
              // arrière à chaque image, et il serait impossible à poser.
              onChanged: (valeur) => setState(
                () => _glisse = Duration(milliseconds: valeur.round()),
              ),
              onChangeEnd: (valeur) async {
                final ou = Duration(milliseconds: valeur.round());
                await ref.read(trackPlayerProvider).seek(ou);
                if (!mounted) return;
                setState(() {
                  _ou = ou;
                  _glisse = null;
                });
              },
            ),
          ),
          Text(
            '${formatElapsed(_glisse ?? _ou)} / ${formatElapsed(totale)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// Donner un nom à son culte — **parce qu'une date n'est pas un nom**.
///
/// 🔴 Au bout de quatre dimanches, « dim. 6 septembre » ne dit plus rien de ce
/// qui a été prêché. Le nom est facultatif et le reste : on ne le demande pas à
/// l'arrêt du micro, où *rien ne doit s'interposer*, mais ici, quand le pasteur
/// revient sur son enregistrement.
class _Nommer extends ConsumerWidget {
  const _Nommer({required this.capture});

  final CapturedSermon capture;

  Future<void> _ouvrir(BuildContext context, WidgetRef ref) async {
    final text = AppText.of(context);
    final saisie = TextEditingController(text: capture.title ?? '');

    final choisi = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.captureNameIt),
        content: TextField(
          controller: saisie,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: text.captureNameHint),
          onSubmitted: (valeur) => Navigator.of(context).pop(valeur),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(text.captureNameCancel),
          ),
          // ⚠️ Vider le champ **retire** le nom : l'écran retombe sur la date,
          // qui est muette mais vraie. Garder une chaîne vide poserait un titre
          // invisible qu'on croirait écrit.
          if (capture.title != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: Text(text.captureNameRemove),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(saisie.text),
            child: Text(text.captureNameSave),
          ),
        ],
      ),
    );

    saisie.dispose();
    if (choisi == null) return;

    await ref.read(captureStoreProvider).nommer(capture.id, choisi);
    ref.invalidate(localCapturesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () => _ouvrir(context, ref),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(text.captureNameIt),
      ),
    );
  }
}

/// Transcrire le culte — **le modèle se demande, il ne descend pas tout seul**.
///
/// 🔴 L'application promet que l'audio ne quitte jamais le téléphone. Faire
/// descendre trente mégaoctets ne rompt pas cette promesse — c'est un modèle
/// qui monte, pas une prédication qui part — mais **c'est du réseau que le
/// pasteur doit voir venir**. Sur un forfait à Abidjan, une surprise se
/// remarque.
class _Transcription extends ConsumerWidget {
  const _Transcription({required this.capture});

  final CapturedSermon capture;

  String _motif(AppText text, TranscriptionRefusal refus) => switch (refus) {
        TranscriptionRefusal.modelMissing ||
        TranscriptionRefusal.modelDownloadFailed =>
          text.transcribeFailedModel,
        TranscriptionRefusal.audioUnreadable => text.transcribeFailedAudio,
        TranscriptionRefusal.engineFailed => text.transcribeFailedEngine,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    final cle = (path: capture.path, fragments: capture.fragments);
    final etat = ref.watch(captureTranscriptionProvider(cle)).value;
    if (etat == null) return const SizedBox.shrink();

    final commandes = ref.read(captureTranscriptionProvider(cle).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!etat.modelReady) ...[
          _Encadre(
            texte: text.transcribeOfferBody(CaptureTranscription.gabarit.megaoctets),
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: etat.downloading ? null : commandes.telecharger,
              child: Text(
                etat.downloading
                    ? text.transcribeDownloading(etat.recusMo, etat.totalMo)
                    : text.transcribeDownload,
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: etat.running ? null : commandes.transcrire,
              child: Text(
                etat.running
                    ? text.transcribeRunning(etat.done, etat.total)
                    : etat.hasText
                        ? text.transcribeResume
                        : text.transcribeStart,
              ),
            ),
          ),
          if (etat.running) ...[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: etat.total == 0 ? null : etat.done / etat.total,
              minHeight: 3,
              backgroundColor: colors.border,
            ),
          ],
        ],

        if (etat.refusal case final TranscriptionRefusal refus) ...[
          const SizedBox(height: AppSpacing.md),
          _Encadre(texte: _motif(text, refus)),
        ],

        // ⚠️ **Le texte se montre dès le premier bloc**, pas à la fin. Un culte
        // de quarante minutes met du temps ; attendre la dernière phrase pour
        // montrer la première ferait croire que rien ne se passe.
        if (etat.hasText) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            text.transcribeSectionText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            etat.text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            text.transcribeAdditive,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}



class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.texte, this.couleur});

  final IconData icone;
  final String texte;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: couleur ?? colors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              texte,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: couleur ?? colors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Encadre extends StatelessWidget {
  const _Encadre({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        texte,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Un onglet fermé — **et qui dit ce qu'il attend**.
class _Attend extends StatelessWidget {
  const _Attend({required this.motif});

  final String motif;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          motif,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
        ),
      ),
    );
  }
}
