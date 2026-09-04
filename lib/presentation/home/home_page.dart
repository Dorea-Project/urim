import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/stale_banner.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/presentation/home/capture_view_model.dart';
import 'package:urim/presentation/home/home_view_model.dart';
import 'package:urim/presentation/home/opening_rule.dart';
import 'package:urim/presentation/home/widgets/home_drawer.dart';
import 'package:urim/presentation/home/widgets/capture_bar.dart';
import 'package:urim/presentation/home/widgets/preparation_card.dart';
import 'package:urim/presentation/home/widgets/preparation_composer.dart';
import 'package:urim/presentation/home/widgets/work_sheet.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Accueil : **la conversation en cours**, et rien entre elle et le pasteur.
///
/// 🔴 **Il y avait ici une liste, et un champ qui menait ailleurs.** On écrivait
/// sa phrase à l'accueil, on était poussé sur un écran qui portait un second
/// champ identique, et la conversation commençait là. Deux écrans, deux
/// composeurs, une seule conversation : la répétition sautait aux yeux dès
/// qu'on l'installait sur un téléphone. Ce qu'on écrit ici continue ici.
///
/// La liste n'a pas disparu, elle a changé de place : elle est dans le tiroir,
/// avec le profil et les réglages. **Ce qu'on consulte de temps en temps se
/// range ; ce qu'on fait tous les jours reste sous les doigts.**
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// Nul tant que le pasteur n'a pas basculé lui-même : c'est alors la règle
  /// d'ouverture qui répond, et elle se recalcule tant qu'on ne l'a pas
  /// contredite.
  HomeTab? _chosen;

  /// La conversation choisie dans le tiroir. Nulle tant qu'on n'a rien choisi :
  /// c'est [resumeId] qui décide, et il décide bien.
  String? _opened;

  /// « Nouvelle préparation » : le champ vide, alors même qu'il y aurait quelque
  /// chose à reprendre. Sans ce drapeau, la règle de reprise rouvrirait aussitôt
  /// la conversation qu'on vient de quitter.
  bool _blank = false;

  void _open(String id) => setState(() {
        _opened = id;
        _blank = false;
      });

  void _startBlank() => setState(() {
        _opened = null;
        _blank = true;
      });

  /// Ouvrir ou fermer le micro depuis le tiroir — le même geste que le bouton.
  Future<void> _toggleCapture() async {
    final notifier = ref.read(sermonCaptureNotifierProvider.notifier);

    if (ref.read(sermonCaptureNotifierProvider).isRunning) {
      await notifier.stop();
      return;
    }

    await notifier.start();
  }

  /// Une prédication déjà transcrite s'ouvre sur sa relecture, pas sur le fil :
  /// ce qu'on vient y chercher, c'est ce qui a été dit.
  void _openPreached(String id) => context.pushNamed(
        AppRoutes.transcriptionName,
        pathParameters: {'id': id},
      );

  Future<void> _switchWork(HomeTab current) async {
    final chosen = await showWorkSheet(context, current: current);
    if (chosen == null || !mounted) return;

    setState(() => _chosen = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(studyFeedProvider);
    final capture = ref.watch(sermonCaptureNotifierProvider);
    final text = AppText.of(context);

    // ⚠️ **L'heure vient de l'application, pas du système.** Un écran qui lit
    // `DateTime.now()` pendant que son jeu d'exemple se construit sur une
    // horloge figée passe pour la mauvaise raison, puis tombe tout seul.
    final now = ref.watch(clockProvider).now();
    final summaries = feed.value?.value ?? const <StudySummary>[];

    final tab = _chosen ?? openingTab(now: now, summaries: summaries);

    final preparations = summaries
        .where((s) => s.origin != PreparationOrigin.transcribed)
        .toList();
    final preached = summaries
        .where((s) => s.origin == PreparationOrigin.transcribed)
        .toList();

    final currentId =
        _blank ? null : (_opened ?? resumeId(preparations, now: now));

    // Le bandeau ne s'affiche que dans la fenêtre où il apprend quelque chose :
    // le jour du culte, tant que rien n'est capté. Après, il ment.
    final awaitingCapture = tab == HomeTab.preach &&
        isServiceDay(now: now, summaries: summaries) &&
        !capturedOn(now, summaries: summaries);

    return Scaffold(
      drawer: HomeDrawer(
        tab: tab,
        preparations: preparations,
        preached: preached,
        captures: ref.watch(localCapturesProvider).value ?? const [],
        currentId: currentId,
        recording: capture.isRunning,
        onNewPreparation: _startBlank,
        onOpenPreparation: _open,
        onRecord: _toggleCapture,
        onOpenPreached: _openPreached,
      ),
      appBar: AppBar(
        // Le titre nomme la conversation ouverte : deux écrans identiques
        // intitulés « Urim » ne diraient pas dans laquelle on se trouve.
        title: Text(
          _titleFor(tab: tab, id: currentId, summaries: preparations),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // ⚠️ **Elle demande avant d'agir.** Une icône seule n'explique pas où
          // elle emmène : elle changeait de travail avant d'avoir dit ce qu'elle
          // changeait. La feuille dit les deux côtés, et lequel est le nôtre.
          IconButton(
            icon: Icon(
              tab == HomeTab.prepare
                  ? Icons.record_voice_over_outlined
                  : Icons.edit_outlined,
            ),
            tooltip: text.homeSwitchTitle,
            onPressed: () => _switchWork(tab),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ⚠️ **Au-dessus de la bascule, pas dedans.** Un enregistrement en
            // cours se voit des deux côtés : c'est la seule chose qui traverse.
            if (capture.running case final CaptureInProgress encours)
              CaptureBar(capture: encours, signal: capture),
            Expanded(
              child: switch (feed) {
                AsyncError() => const _FeedError(),
                AsyncLoading() when feed.value == null =>
                  const Center(child: CircularProgressIndicator()),
                _ => switch (tab) {
                    HomeTab.prepare => currentId == null
                        ? _BlankPreparation(onOpened: _open)
                        : PreparationConversation(preparationId: currentId),
                    HomeTab.preach => _PreachedSide(
                        summaries: preached,
                        receivedAt: feed.value?.receivedAt,
                        awaitingCapture: awaitingCapture,
                      ),
                  },
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Le titre de la barre : la conversation ouverte, ou le nom de l'application.
String _titleFor({
  required HomeTab tab,
  required String? id,
  required List<StudySummary> summaries,
}) {
  if (tab == HomeTab.preach || id == null) return 'Urim';

  for (final summary in summaries) {
    if (summary.id == id) return summary.pericopeLabel ?? summary.rawInput;
  }

  return 'Urim';
}

/// Rien d'ouvert : le champ, et ce qu'il attend.
///
/// C'est le seul endroit de l'application où il n'y a rien à lire — et c'est
/// voulu : la seule chose qui fasse avancer ce jour-là est la phrase qu'on n'a
/// pas encore écrite.
class _BlankPreparation extends StatelessWidget {
  const _BlankPreparation({required this.onOpened});

  final void Function(String id) onOpened;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text.homeEmptyTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    text.homeEmptyBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: PreparationComposer(onOpened: onOpened),
        ),
      ],
    );
  }
}

/// Les prédications captées, et le geste qui en ajoute une.
class _PreachedSide extends StatelessWidget {
  const _PreachedSide({
    required this.summaries,
    required this.receivedAt,
    required this.awaitingCapture,
  });

  final List<StudySummary> summaries;
  final DateTime? receivedAt;
  final bool awaitingCapture;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (receivedAt case final DateTime recu) StaleBanner(receivedAt: recu),
        if (awaitingCapture) const _ServiceTodayBanner(),
        Expanded(child: _PreachedFeed(summaries: summaries)),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: _RecordButton(),
        ),
      ],
    );
  }
}

/// « Enregistrer la prédication » — le geste qu'on ne peut pas rater.
///
/// 🔴 **Rien ne s'interpose.** Pas de confirmation, pas de choix de préparation
/// à rattacher, pas d'attente de réseau : *« la capture n'est jamais refusée —
/// ce qui n'est pas capté dimanche est perdu pour toujours »*. On rattachera
/// après ; le dimanche matin, il n'y a qu'un doigt et trois secondes.
///
/// Le bouton **ne disparaît pas** pendant l'enregistrement : il devient
/// l'arrêt. Deux boutons qui se remplacent au même endroit, c'est un seul
/// endroit à retenir.
class _RecordButton extends ConsumerWidget {
  const _RecordButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final capture = ref.watch(sermonCaptureNotifierProvider);
    final notifier = ref.read(sermonCaptureNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: () async {
            if (capture.isRunning) {
              final captee = await notifier.stop();
              if (captee == null || !context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppText.of(context)
                        .homeCaptureSaved(formatElapsed(captee.duration)),
                  ),
                ),
              );
              return;
            }

            await notifier.start();
          },
          icon: Icon(
            capture.isRunning ? Icons.stop : Icons.fiber_manual_record,
          ),
          label: Text(
            capture.isRunning ? text.homeRecordStop : text.homeRecordSermon,
          ),
        ),
        if (capture.refusal case final CaptureRefusal refus) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _refusalMessage(text, refus),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  height: 1.45,
                ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          text.homeRecordPending,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

/// Quatre refus, quatre phrases : « refusé » tout court laisse le pasteur
/// devant un bouton mort sans savoir quoi faire.
String _refusalMessage(AppText text, CaptureRefusal refusal) =>
    switch (refusal) {
      CaptureRefusal.micRefused => text.homeCaptureMicRefused,
      CaptureRefusal.noMicrophone => text.homeCaptureNoMicrophone,
      CaptureRefusal.storageFull => text.homeCaptureStorageFull,
      CaptureRefusal.engineFailed => text.homeCaptureFailed,
    };

/// « Culte aujourd'hui · rien n'est encore capté ».
///
/// Sans lui, la règle d'ouverture est muette : le pasteur ouvre son application
/// et tombe ailleurs que d'habitude, sans raison visible. **Un automatisme qui
/// ne se justifie pas passe pour une panne.**
class _ServiceTodayBanner extends StatelessWidget {
  const _ServiceTodayBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: text.homeServiceToday,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · ${text.homeServiceTodayPending}'),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les prédications captées, de la plus récente à la plus ancienne.
///
/// Pas de regroupement par récence ici : un corpus se parcourt, il ne se trie
/// pas en « cette semaine » et « plus tôt ». Le compte, lui, est l'argument —
/// c'est le nombre qui monte, semaine après semaine, dans la voix du pasteur.
class _PreachedFeed extends ConsumerWidget {
  const _PreachedFeed({required this.summaries});

  final List<StudySummary> summaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final now = ref.watch(clockProvider).now();

    // Ce qui est sur l'appareil vient d'abord : c'est le culte de ce matin, et
    // il n'a pas encore atteint le serveur — il n'y a pas de serveur pour lui.
    final captees = ref.watch(localCapturesProvider).value ?? const [];

    if (summaries.isEmpty && captees.isEmpty) {
      return _EmptyState(
        title: text.homePreachedEmptyTitle,
        body: text.homePreachedEmptyBody,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.md,
          ),
          child: Text(
            text.homeGroupPreached(summaries.length + captees.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        // ⛔ **Le compteur « ce qui attend le réseau » est parti** (D71, 06/09).
        // Il disait vrai tant que la file se vidait ; depuis qu'elle ne part
        // plus, il aurait montré un nombre qui ne descend jamais — exactement
        // la lecture qui inquiète, et que ce bandeau existait pour écarter.
        for (final captee in captees) ...[
          _CaptureCard(capture: captee, now: now),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final summary in summaries) ...[
          PreparationCard(summary: summary),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// Une prédication captée, posée sur l'appareil et pas ailleurs.
///
/// Elle dit trois choses et pas une de plus : quand, combien de temps, et
/// **dans combien de jours l'audio disparaît**. Pas de transcript annoncé — il
/// n'y en a pas, et le promettre serait mentir jusqu'à ce que Q2 soit tranchée.
class _CaptureCard extends StatelessWidget {
  const _CaptureCard({required this.capture, required this.now});

  final CapturedSermon capture;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    final jours = capture.purgeAt.difference(now).inDays;

    // 🔴 **Elle s'ouvre depuis le 29/08.** C'était un `Container` : trois faits
    // et aucun geste — le seul objet du produit sur lequel on ne pouvait rien
    // faire. La retenue se défendait — *annoncer un transcript qui n'existe pas
    // serait mentir* — mais l'écran qui s'ouvre ne promet rien : il montre
    // l'état réel de l'enregistrement, et dit ce que le reste attend (D13).
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoutes.captureName,
          pathParameters: {'id': capture.id},
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            frenchShortDate(capture.startedAt),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatElapsed(capture.duration)} · ${text.homeCaptureNotSent}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 🔴 **A2.4 — la promesse manquante.** La capture est le PREMIER
          // objet d'Urim qui ne se synchronise pas, et rien ne le disait. Tout
          // le reste vit sur le serveur : le pasteur ouvre Urim sur sa tablette
          // et retrouve son travail. Une capture, non.
          //
          // Ce n'est pas un défaut à corriger — c'est la conséquence de *« la
          // capture n'est jamais refusée »*, qui interdit d'attendre le réseau.
          // C'est donc une promesse à **formuler**, et avant le premier pilote :
          // le jour où il cherche la relecture sur sa tablette, il ne doit pas
          // découvrir le vide.
          Text(
            text.homeCaptureStaysHere,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Une capture que l'arrêt n'a jamais atteinte le dit. La faire
              // passer pour entière serait le pire des silences.
              if (capture.interrupted) ...[
                _Pastille(
                  label: text.homeCaptureInterrupted,
                  color: colors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  jours <= 0
                      ? text.homeCaptureAudioToday
                      : text.homeCaptureAudioLeft(jours),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
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
              AppText.of(context).homeReadFailed,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => ref.invalidate(studyFeedProvider),
              child: Text(AppText.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
