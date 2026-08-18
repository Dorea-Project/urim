import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/datasources/draft_local_data_source.dart';
import 'package:urim/presentation/common/draft_keeper.dart';
import 'package:urim/presentation/common/stale_banner.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/presentation/preparation/preparation_view_model.dart';
import 'package:urim/presentation/preparation/study_export.dart';
import 'package:urim/presentation/preparation/widgets/pending_banner.dart';
import 'package:urim/presentation/preparation/widgets/study_material.dart';
import 'package:urim/presentation/preparation/widgets/turn_views.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Une préparation et son tour courant.
///
/// **Il n'y a pas de fil de conversation à charger.** Le moteur rejoue son
/// pipeline à chaque lecture : ce qui existe, c'est le tour d'aujourd'hui. Ce
/// qu'on voit au-dessus est le compte rendu de la séance en cours, perdu en
/// quittant l'écran — et c'est cohérent avec ce que le serveur promet.
class PreparationPage extends ConsumerWidget {
  const PreparationPage({super.key, required this.preparationId});

  final String preparationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = ref.watch(preparationThreadProvider(preparationId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: AppText.of(context).back,
        ),
        title: Text(
          // Le titre reste ce que le pasteur a écrit tant que rien n'est
          // résolu ; l'unité bornée le remplace dès qu'elle existe.
          thread.value?.study.pericopeLabel ??
              thread.value?.study.rawInput ??
              '',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Renommer et supprimer n'existent pas encore ; copier, si. Le menu
          // n'apparaît donc que quand il a quelque chose à offrir — un menu
          // ouvert sur une seule entrée grisée serait pire que pas de menu.
          if (thread.value?.study case final Study study)
            PopupMenuButton<void>(
              icon: const Icon(Icons.more_vert),
              tooltip: AppText.of(context).options,
              itemBuilder: (menuContext) => [
                PopupMenuItem<void>(
                  onTap: () => _copyStudy(context, study),
                  child: Text(AppText.of(menuContext).preparationExport),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // La provenance avant le contenu : on dit d'où ça vient avant que
            // le pasteur ne se mette à lire, pas après.
            if (thread.value?.receivedAt case final DateTime recu)
              StaleBanner(receivedAt: recu),
            if (thread.value?.study.corpusDrifted ?? false)
              const DriftNotice(),
            Expanded(
              child: switch (thread) {
                AsyncData(:final value) => _Thread(
                    state: value,
                    preparationId: preparationId,
                  ),
                AsyncError(:final error) => _ThreadError(error: error),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            // La barre ne se ferme jamais, quel que soit `expects` : les
            // pastilles sont des raccourcis, pas des barreaux.
            _Composer(preparationId: preparationId),
          ],
        ),
      ),
    );
  }
}

/// Met la préparation dans le presse-papiers.
///
/// Le presse-papiers plutôt qu'un fichier partagé : il ne demande aucun
/// greffon, fonctionne sur les cinq plateformes, et le pasteur colle où il
/// veut — un carnet, un message, un document. Le partage de fichier reste à
/// décider.
Future<void> _copyStudy(BuildContext context, Study study) async {
  final text = AppText.of(context);

  await Clipboard.setData(ClipboardData(text: exportStudyAsText(study, text)));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text.preparationExportDone)),
  );
}

class _Thread extends ConsumerWidget {
  const _Thread({required this.state, required this.preparationId});

  final ThreadState state;
  final String preparationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            AppText.of(context).preparationEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
        ),
      );
    }

    final notifier =
        ref.read(preparationThreadProvider(preparationId).notifier);

    Future<void> rapporter(Future<Failure?> geste) async {
      final failure = await geste;
      if (failure == null || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }

    // Sous le dernier tour : ce que la preparation porte et que personne ne
    // montrait — le texte, le contexte. Puis le bandeau d'attente, qui reste
    // **dernier** : c'est la ou le pasteur regarde apres avoir touche.
    final apres = <Widget>[
      if (_porteDeLaMatiere(state)) StudyMaterial(study: state.study),
      if (state.isWaitingToSend) PendingBanner(pending: state.pending),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      itemCount: state.entries.length + apres.length,
      itemBuilder: (context, index) => index >= state.entries.length
          ? apres[index - state.entries.length]
          : switch (state.entries[index]) {
        SpokenByPastor(:final text) => _PastorSaid(text: text),
        ServedTurn(:final turn, :final live) => TurnView(
            turn: turn,
            live: live,
            onDecision: ({
              required stageCode,
              required optionCode,
              required label,
            }) =>
                rapporter(notifier.decide(
              stageCode: stageCode,
              optionCode: optionCode,
              label: label,
            )),
            onDismiss: ({required stageCode, required optionCode}) =>
                rapporter(notifier.dismiss(
              stageCode: stageCode,
              optionCode: optionCode,
            )),
          ),
        },
    );
  }
}

/// La preparation porte-t-elle de quoi offrir quelque chose ?
bool _porteDeLaMatiere(ThreadState state) =>
    state.study.verses.isNotEmpty || state.study.context.isNotEmpty;

/// Ce que le pasteur a dit : une bulle pleine, calée à droite.
class _PastorSaid extends StatelessWidget {
  const _PastorSaid({required this.text});

  final String text;

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
              text,
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

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message =
        // Le message d'une Failure est déjà rédigé par le cas d'usage ; le
        // repli, lui, est un texte d'écran.
        error is Failure
            ? (error as Failure).message
            : AppText.of(context).preparationLoadFailed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }
}

/// Barre de saisie : écrire, dicter, envoyer.
///
/// Elle reste ouverte à tous les tours. Le pasteur peut désigner ce qui est à
/// l'écran — « L'Église », « la péricope entière » —, poser une question, ou
/// changer de sujet ; le serveur résout d'abord par comparaison de chaînes ce
/// qui désigne l'écran, et ne classe que le reste.
class _Composer extends ConsumerStatefulWidget {
  const _Composer({required this.preparationId});

  final String preparationId;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final TextEditingController _controller = TextEditingController();
  late final DraftKeeper _brouillon;
  bool _hasText = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _brouillon = DraftKeeper(
      source: ref.read(draftLocalDataSourceProvider),
      key: DraftLocalDataSource.composerKey(widget.preparationId),
    );
    _reprendre();
  }

  /// Ce qui avait été écrit et jamais envoyé revient dans le champ.
  Future<void> _reprendre() async {
    final garde = await _brouillon.restore();
    if (garde == null || !mounted || _controller.text.isNotEmpty) return;

    _controller.text = garde.text;
    setState(() => _hasText = garde.text.trim().isNotEmpty);
  }

  @override
  void dispose() {
    // L'ordre compte : on écrit d'abord, on détruit ensuite. C'est ici que le
    // texte se perdait.
    _brouillon.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final dit = _controller.text;
    setState(() => _isBusy = true);

    final failure = await ref
        .read(preparationThreadProvider(widget.preparationId).notifier)
        .say(dit);

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (failure == null) {
      // Le serveur a pris la phrase : la copie locale n'a plus de raison
      // d'être. En cas d'échec elle reste, et c'est tout l'intérêt.
      // Sans attendre : vider le champ ne dépend pas du ménage.
      _brouillon.forget();
      _controller.clear();
      setState(() => _hasText = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              onChanged: (value) {
                _brouillon.remember(value);
                setState(() => _hasText = value.trim().isNotEmpty);
              },
              decoration: InputDecoration(
                hintText: AppText.of(context).preparationComposerHint,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.mic_none),
            // La dictée suppose un moteur de reconnaissance vocale — question
            // Q2, non tranchée. Le bouton reste visible pour ne pas laisser
            // croire que la saisie vocale a été oubliée.
            onPressed: null,
            tooltip: AppText.of(context).preparationDictationSoon,
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            onPressed: _hasText && !_isBusy ? _send : null,
            icon: _isBusy
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.arrow_upward),
            tooltip: AppText.of(context).preparationSend,
          ),
        ],
      ),
    );
  }
}
