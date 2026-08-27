import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/presentation/archive/archive_view_model.dart';
import 'package:urim/data/datasources/draft_local_data_source.dart';
import 'package:urim/presentation/common/draft_keeper.dart';
import 'package:urim/presentation/common/stale_banner.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/presentation/bible/search_page.dart';
import 'package:urim/presentation/preparation/deck_page.dart';
import 'package:urim/presentation/preparation/deliverable_view_model.dart';
import 'package:urim/presentation/preparation/plan_page.dart';
import 'package:urim/presentation/preparation/preparation_view_model.dart';
import 'package:urim/presentation/preparation/supports_page.dart';
import 'package:urim/presentation/preparation/study_export.dart';
import 'package:urim/presentation/preparation/widgets/pending_banner.dart';
import 'package:urim/presentation/preparation/widgets/study_material.dart';
import 'package:urim/presentation/preparation/widgets/turn_views.dart';
import 'package:urim/presentation/preparation/widgets/urim_is_thinking.dart';
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
          // ⚠️ **Le geste qui manquait.** Un pasteur en séance a demandé le sens
          // d'un mot et le contexte d'un livre : le serveur y répondait, aucun
          // écran ne le servait, et la parole partait vers un aiguilleur qui
          // n'a pas d'issue « questionner » (Q21). Chercher n'est pas parler à
          // Urim — c'est regarder dans le corpus, sans rien engager.
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: AppText.of(context).searchTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchPage()),
            ),
          ),
          // Renommer et supprimer n'existent pas encore ; copier, si. Le menu
          // n'apparaît donc que quand il a quelque chose à offrir — un menu
          // ouvert sur une seule entrée grisée serait pire que pas de menu.
          if (thread.value?.study case final Study study)
            PopupMenuButton<void>(
              icon: const Icon(Icons.more_vert),
              tooltip: AppText.of(context).options,
              itemBuilder: (menuContext) => [
                PopupMenuItem<void>(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SupportsPage(study: study),
                    ),
                  ),
                  child: Text(
                    AppText.of(menuContext).preparationSupportsTitle,
                  ),
                ),
                // ⚠️ **La matière a quitté le fil le 22/08.** Elle s'y
                // recollait sous le dernier tour, donc elle se rappelait à la
                // fin de **chaque** échange — deux replis fermés qui closaient
                // la conversation au lieu de la servir. Elle reste à un geste,
                // elle ne s'impose plus.
                if (study.verses.isNotEmpty || study.context.isNotEmpty)
                  PopupMenuItem<void>(
                    onTap: () => _showMaterial(context, study),
                    child: Text(AppText.of(menuContext).preparationMaterialTitle),
                  ),
                // « J'ai prêché celle-ci » — un geste, jamais une déduction du
                // calendrier. Rien ne s'archive parce qu'une date est passée :
                // une préparation datée du dimanche prochain n'a pas été
                // prêchée pour autant.
                //
                // Il reste offert même sur une préparation déjà archivée : le
                // serveur ne déduplique pas, et c'est voulu — *prêcher deux
                // fois le même texte, dans deux annexes ou deux dimanches, ce
                // sont deux faits datés*.
                PopupMenuItem<void>(
                  onTap: () => _markPreached(context, ref, study),
                  child: Text(AppText.of(menuContext).preachedMark),
                ),
                PopupMenuItem<void>(
                  onTap: () => _copyStudy(context, study),
                  child: Text(AppText.of(menuContext).preparationExport),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: PreparationConversation(preparationId: preparationId),
      ),
    );
  }
}

/// La conversation elle-même : ce qui a été dit, et de quoi répondre.
///
/// **Sans barre de titre ni écran autour**, et c'est tout l'intérêt : l'accueil
/// la monte directement sous sa propre barre. Il y avait là une répétition que
/// personne n'aurait défendue — un champ à l'accueil qui, une fois soumis,
/// poussait un écran portant un second champ identique. Une conversation ne se
/// visite pas, elle se continue.
class PreparationConversation extends ConsumerWidget {
  const PreparationConversation({super.key, required this.preparationId});

  final String preparationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = ref.watch(preparationThreadProvider(preparationId));

    return Column(
      children: [
        // La provenance avant le contenu : on dit d'où ça vient avant que le
        // pasteur ne se mette à lire, pas après.
        if (thread.value?.receivedAt case final DateTime recu)
          StaleBanner(receivedAt: recu),
        if (thread.value?.study.corpusDrifted ?? false) const DriftNotice(),
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
        // La barre ne se ferme jamais, quel que soit `expects` : les pastilles
        // sont des raccourcis, pas des barreaux.
        _Composer(preparationId: preparationId),
      ],
    );
  }
}

/// Ce que la préparation porte — **à la demande**.
///
/// Le pasteur travaille sur un passage : il doit pouvoir le lire. Ce qui a
/// changé n'est pas l'accès, c'est le moment — il l'ouvre quand il le veut, au
/// lieu de le retrouver sous chaque réponse.
Future<void> _showMaterial(BuildContext context, Study study) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: StudyMaterial(study: study),
          ),
        ),
      ),
    );

/// Met la préparation dans le presse-papiers.
///
/// Le presse-papiers plutôt qu'un fichier partagé : il ne demande aucun
/// greffon, fonctionne sur les cinq plateformes, et le pasteur colle où il
/// veut — un carnet, un message, un document. Le partage de fichier reste à
/// décider.
/// Consigner la prédication, et le dire.
///
/// ⚠️ **Le geste ferme la préparation côté serveur** (D57), mais seulement
/// quand c'est son auteur qui archive : la route accepte aussi un lecteur, et
/// fermer sans cette garde clôturerait le travail de quelqu'un d'autre parce
/// qu'un confrère l'a prêché.
Future<void> _markPreached(
  BuildContext context,
  WidgetRef ref,
  Study study,
) async {
  final messager = ScaffoldMessenger.of(context);
  final text = AppText.of(context);

  final (sermon, failure) =
      await ref.read(preachedMarkerProvider.notifier).mark(study.id);

  if (sermon == null) {
    messager.showSnackBar(
      SnackBar(
        content: Text(
          failure is Failure ? failure.message : text.homeReadFailed,
        ),
      ),
    );
    return;
  }

  messager.showSnackBar(
    SnackBar(
      content: Text(
        text.preachedMarkDone(frenchShortDate(sermon.preachedOn)),
      ),
    ),
  );
}

Future<void> _copyStudy(BuildContext context, Study study) async {
  final text = AppText.of(context);

  await Clipboard.setData(ClipboardData(text: exportStudyAsText(study, text)));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text.preparationExportDone)),
  );
}

class _Thread extends ConsumerStatefulWidget {
  const _Thread({required this.state, required this.preparationId});

  final ThreadState state;
  final String preparationId;

  @override
  ConsumerState<_Thread> createState() => _ThreadListState();
}

class _ThreadListState extends ConsumerState<_Thread> {
  /// ⚠️ **Le fil ne suivait rien.** La liste n'avait aucun contrôleur : une
  /// réponse arrivait sous le pli, et le pasteur devait descendre à la main
  /// pour lire ce qu'il venait de demander. Sur un téléphone, un tour du
  /// moteur fait facilement deux écrans.
  final ScrollController _defilement = ScrollController();

  /// Ce qu'on suivait au dernier passage. On ne défile que si **quelque chose
  /// est apparu** : refaire le geste à chaque reconstruction arracherait
  /// l'écran des mains d'un pasteur en train de relire un tour ancien.
  int _suivi = 0;

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  /// La clé du dernier élément — c'est **son haut** qu'on amène, pas le bas de
  /// la liste.
  ///
  /// ⚠️ **La différence n'est pas cosmétique, et un test l'a prouvée.** Un tour
  /// réel fait deux à trois écrans : seize pastilles, un motif de 1 400
  /// caractères, dix pesées. Défiler jusqu'au bas de la liste dépose le pasteur
  /// à la fin de ce qu'il n'a pas encore lu, et laisse au-dessus de lui les
  /// options qu'il doit toucher. On aligne donc le **début** du tour sur le
  /// haut de l'écran : il lit dans le sens où c'est écrit.
  final GlobalKey _dernier = GlobalKey();

  /// Après la trame, jamais pendant : la hauteur de ce qui vient d'arriver
  /// n'est connue qu'une fois la mise en page faite.
  void _suivreLeDernier() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_defilement.hasClients) return;

      final arrivee = _dernier.currentContext;
      if (arrivee == null) {
        // L'élément n'est pas construit : la liste est paresseuse, et il est
        // loin sous le pli. Le bas de la liste est alors la seule cible
        // atteignable, et c'est aussi la bonne — on venait de très haut.
        _defilement.animateTo(
          _defilement.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
        return;
      }

      Scrollable.ensureVisible(
        arrivee,
        alignment: 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final preparationId = widget.preparationId;

    // La bulle d'attente compte comme une arrivée : c'est elle qu'il faut
    // montrer, sinon le pasteur ne voit pas que sa parole est partie.
    final compte = state.entries.length + (state.thinking ? 1 : 0);
    if (compte != _suivi) {
      _suivi = compte;
      _suivreLeDernier();
    }

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

    // En queue de fil : **rien que l'attente**. La matière est passée au menu
    // le 22/08 — elle se rappelait à la fin de chaque échange, et fermait la
    // conversation au lieu de la nourrir.
    //
    // La bulle vient avant le bandeau : l'une dit « c'est parti, j'attends »,
    // l'autre « ce n'est pas parti ». Les deux ne sont jamais vraies ensemble.
    final apres = <Widget>[
      if (state.thinking) const UrimIsThinking(),
      if (state.isWaitingToSend) PendingBanner(pending: state.pending),
    ];

    return ListView.builder(
      controller: _defilement,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      itemCount: state.entries.length + apres.length,
      itemBuilder: (context, index) => KeyedSubtree(
        // La clé voyage sur le dernier élément affiché — le tour qui vient
        // d'arriver, ou la bulle qui dit qu'il arrive.
        key: index == state.entries.length + apres.length - 1 ? _dernier : null,
        child: index >= state.entries.length
          ? apres[index - state.entries.length]
          : switch (state.entries[index]) {
        SpokenByPastor(:final text) => _PastorSaid(text: text),
        // Une parole d'un tour passé : lisible, inerte. Ses pastilles ne mènent
        // plus nulle part — le moteur a avancé — et les rendre touchables
        // enverrait une décision à un étage qui n'attend plus.
        SaidByUrim(:final text) => _UrimSaid(text: text),
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
            onAction: (code) => _geste(context, ref, state.study, code),
          ),
        },
      ),
    );
  }
}

/// Ce qu'Urim a dit à un tour passé.
///
/// La même voix que le tour vivant, sans ses gestes : le fil se relit, il ne se
/// rejoue pas.
class _UrimSaid extends StatelessWidget {
  const _UrimSaid({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colors.border, width: 2),
            ),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
          ),
        ),
      ),
    );
  }
}

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

/// Ce que l'écran fait d'un geste de fin de fil.
///
/// Écrire ses points ouvre un écran ; demander un document en produit un. Les
/// gestes que l'application ne sait pas encore ouvrir n'arrivent jamais ici :
/// le bloc ne les rend pas touchables.
Future<void> _geste(
  BuildContext context,
  WidgetRef ref,
  Study study,
  String code,
) async {
  if (code == 'elements') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlanPage(study: study)),
    );
    return;
  }

  // Le deck se compose avant de se produire : le contrôle porte sur ce qui
  // sera projeté, donc il faut d'abord que le pasteur l'ait écrit.
  if (code == 'deck') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DeckPage(study: study)),
    );
    return;
  }

  final text = AppText.of(context);
  final messager = ScaffoldMessenger.of(context);

  messager.showSnackBar(
    SnackBar(content: Text(text.preparationDocumentWorking)),
  );

  final issue = await ref.read(deliverableProducerProvider.notifier).produce(
        studyId: study.id,
        // « Fiche de chaire » côté écran, `note` côté contrat.
        kind: code == 'sheet' ? 'note' : 'deck',
      );

  if (!context.mounted) return;

  messager.hideCurrentSnackBar();

  switch (issue) {
    case DocumentReady(:final path):
      messager.showSnackBar(
        SnackBar(content: Text(text.preparationDocumentReady(path))),
      );
    case CitationRefused(:final dossier):
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(text.preparationDocumentRefusedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.preparationDocumentRefusedBody),
              for (final controle in dossier.altered) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  controle.reference,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(controle.rationale),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(text.back),
            ),
          ],
        ),
      );
    case DeliverableFailed(:final failure):
      messager.showSnackBar(SnackBar(content: Text(failure.message)));
  }
}
