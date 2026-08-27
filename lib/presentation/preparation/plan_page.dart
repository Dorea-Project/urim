import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/data/datasources/draft_local_data_source.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/articulation.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/thread_line.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/common/draft_keeper.dart';
import 'package:urim/presentation/preparation/plan_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Écrire son plan.
///
/// **Le seul écran d'Urim où le pasteur écrit son sermon.** Le squelette donne
/// un ordre, pas un texte. Une section vide reste vide — le document le dit
/// lui-même, « il ne l'écrit pas à votre place ».
///
/// Urim y propose une seule chose, et **seulement si on la lui demande** :
/// articuler un point **déjà écrit**. La proposition s'affiche à côté du champ
/// et n'y entre que par un geste explicite. C'est toute la distance entre un
/// atelier et une machine à sermons.
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({required this.study, super.key});

  final Study study;

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  /// Ce qui est écrit et pas encore envoyé.
  ///
  /// ⚠️ **L'envoi seul ne suffit pas.** Le plan ne part qu'au bouton ; entre la
  /// première frappe et lui, il n'existe que dans des contrôleurs que le
  /// `dispose` détruit. Un appel reçu, un retour touché par erreur, et le
  /// travail disparaît — la même perte que la barre de saisie avant qu'elle
  /// soit gardée.
  late final DraftKeeper _brouillon;
  /// Un contrôleur par section, créé à la demande et libéré avec l'écran.
  ///
  /// Reconstruire le champ à chaque frappe déplacerait le curseur ; le
  /// contrôleur garde la position, l'état garde le texte.
  final Map<String, TextEditingController> _champs = {};

  /// Le point dont on attend une articulation, s'il y en a un.
  ///
  /// Un seul à la fois : deux demandes en vol coûteraient deux appels de
  /// modèle pour un écran où le pasteur n'en lit qu'un.
  String? _demande;

  /// La note dont on attend la reprise, s'il y en a une.
  String? _promotion;

  @override
  void initState() {
    super.initState();
    _brouillon = DraftKeeper(
      source: ref.read(draftLocalDataSourceProvider),
      key: DraftLocalDataSource.planKey(widget.study.id),
    );
    _reprendre();
  }

  /// Ce qui avait été écrit et jamais envoyé revient dans les champs.
  ///
  /// Le brouillon ne gagne **que sur le vide** : un plan déjà enregistré côté
  /// serveur est la vérité, et l'écraser par une frappe ancienne serait rendre
  /// au pasteur un travail qu'il a lui-même remplacé.
  Future<void> _reprendre() async {
    final garde = await _brouillon.restore();
    if (garde == null || !mounted) return;

    final notifier = ref.read(planViewModelProvider(widget.study).notifier);
    for (final ligne in garde.text.split(DraftLocalDataSource.ligne)) {
      final coupe = ligne.indexOf(DraftLocalDataSource.champ);
      if (coupe <= 0) continue;

      final code = ligne.substring(0, coupe);
      final corps = ligne.substring(coupe + 1);
      if (corps.isEmpty) continue;
      if ((ref.read(planViewModelProvider(widget.study)).bodies[code] ?? '')
          .isNotEmpty) {
        continue;
      }

      notifier.addSection(code);
      notifier.write(code, corps);
      _champs[code] = TextEditingController(text: corps);
    }
    setState(() {});
  }

  /// Ce que le brouillon garde : une section par ligne, code et corps séparés
  /// par un caractère nul — le seul qu'un pasteur ne tapera jamais.
  void _noter() {
    final state = ref.read(planViewModelProvider(widget.study));
    _brouillon.remember([
      for (final code in state.sections)
        if ((state.bodies[code] ?? '').trim().isNotEmpty)
          '$code${DraftLocalDataSource.champ}${state.bodies[code]}',
    ].join(DraftLocalDataSource.ligne));
  }

  @override
  void dispose() {
    // L'ordre compte : on écrit d'abord, on détruit ensuite. C'est ici que le
    // texte se perdait.
    _brouillon.dispose();
    for (final champ in _champs.values) {
      champ.dispose();
    }
    super.dispose();
  }

  TextEditingController _champ(String code, String valeur) =>
      _champs.putIfAbsent(code, () => TextEditingController(text: valeur));

  void _dire(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final text = AppText.of(context);
    final failure =
        await ref.read(planViewModelProvider(widget.study).notifier).save();

    if (!mounted) return;

    _dire(failure?.message ?? text.preparationPlanSaved);

    // Poussé par le Navigator, refermé par lui : l'écran ne dépend pas du
    // routeur, ce qui le rend ouvrable depuis n'importe où dans le fil.
    // Le serveur a accusé réception : la copie locale n'a plus de raison d'être.
    if (failure == null) {
      _brouillon.forget();
      await Navigator.maybePop(context);
    }
  }

  /// Les notes du fil posées sous ce point, et **pas encore reprises**.
  ///
  /// ⚠️ Une note promue disparaît d'ici : elle est **dans** le point désormais,
  /// et la montrer deux fois ferait croire qu'elle attend encore.
  List<ThreadLine> _notesDe(String code, int rang) => [
        for (final ligne in widget.study.fil)
          if (ligne.attendSaPromotion &&
              ligne.elementCode == code &&
              (ligne.elementOrdinal == null || ligne.elementOrdinal == rang))
            ligne,
      ];

  /// Faire d'une note **un point du plan** — le seul chemin du fil vers le
  /// document.
  ///
  /// 🔴 **C'est ici que le verrou se tient.** Tout ce que le pasteur écrit dans
  /// le fil est gardé, rangé sous le point qu'il a désigné, relisible trois
  /// jours plus tard — et n'atteint aucun fichier. Le `.docx` n'imprime que son
  /// plan. Ce geste est le seul pont, et c'est lui qui le franchit.
  ///
  /// ⚠️ **Le serveur ajoute, il ne remplace pas** : une note est le plus souvent
  /// une remarque *sur* le point, pas le texte du point.
  Future<void> _promouvoir(String entryId) async {
    final text = AppText.of(context);

    setState(() => _promotion = entryId);
    try {
      final result = await ref.read(studyRepositoryProvider).promote(
            studyId: widget.study.id,
            entryId: entryId,
          );
      if (!mounted) return;

      result.fold(
        onSuccess: (etude) {
          // Le point a changé côté serveur : on rouvre l'écran sur ce qu'il
          // porte maintenant, plutôt que de recoller le texte à la main et
          // risquer deux vérités.
          _dire(text.preparationPlanPromoted);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => PlanPage(study: etude)),
          );
        },
        onFailure: (failure) => _dire(failure.message),
      );
    } finally {
      if (mounted) setState(() => _promotion = null);
    }
  }

  /// Faire articuler un point — **le sien, et déjà écrit**.
  ///
  /// ⚠️ **On enregistre avant de demander, et ce n'est pas une précaution.**
  /// Le serveur articule le point *tel qu'il l'a en base*. Demander sans avoir
  /// envoyé rendrait une proposition sur une phrase que le pasteur vient de
  /// remplacer — un défaut que rien à l'écran ne trahirait. L'enregistrement
  /// est donc le premier temps du geste, pas une précaution qu'on pourrait
  /// sauter un jour de hâte.
  Future<void> _articuler(String code) async {
    final text = AppText.of(context);
    final notifier = ref.read(planViewModelProvider(widget.study).notifier);

    if ((ref.read(planViewModelProvider(widget.study)).bodies[code] ?? '')
        .trim()
        .isEmpty) {
      // On n'articule pas un point qui n'existe pas : ce serait l'écrire. Le
      // serveur le refuse aussi, mais l'apprendre coûterait un aller-retour
      // pour une réponse que l'écran a déjà sous les yeux.
      _dire(text.preparationPlanArticulateEmpty);
      return;
    }

    setState(() => _demande = code);

    // ⚠️ **L'attente s'arrête quand la réponse arrive, pas quand le pasteur a
    // fini de la lire.** Garder le compteur allumé pendant la feuille ferait
    // tourner une roue sous un texte déjà rendu — et l'écran n'aurait plus
    // aucun moment de repos, ce que le premier passage des tests a montré.
    Articulation? proposition;

    try {
      final failure = await notifier.save();
      if (!mounted) return;

      if (failure != null) {
        _dire(failure.message);
        return;
      }
      _brouillon.forget();

      // Le rang est celui que l'envoi vient d'écrire : les deux se lisent dans
      // la même liste de sections, donc ils ne peuvent pas diverger.
      final rang =
          ref.read(planViewModelProvider(widget.study)).sections.indexOf(code);

      final result = await ref.read(studyRepositoryProvider).articulate(
            studyId: widget.study.id,
            elementCode: code,
            ordinal: rang,
          );
      if (!mounted) return;

      proposition = result.valueOrNull;
      if (proposition == null) {
        _dire(
          result.failureOrNull?.message ??
              text.preparationPlanArticulateUnavailable,
        );
      }
    } finally {
      if (mounted) setState(() => _demande = null);
    }

    if (proposition != null) await _lire(code, proposition);
  }

  /// Montrer la proposition **à côté** du point, et n'y toucher que si le
  /// pasteur le demande.
  Future<void> _lire(String code, Articulation proposition) async {
    final text = AppText.of(context);

    // `available: false` n'est pas une panne : aucun modèle branché, plafond
    // atteint, ou point que le serveur a jugé vide. L'atelier fonctionne sans,
    // et un écran d'erreur ici ferait passer un état de production pour un
    // défaut.
    if (!proposition.available || proposition.isEmpty) {
      _dire(text.preparationPlanArticulateUnavailable);
      return;
    }

    final reprendre = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ArticulationSheet(proposition),
    );

    if (reprendre != true || !mounted) return;

    // **La proposition s'ajoute, elle ne remplace pas.** Ce que le pasteur a
    // écrit reste devant ; ce qu'Urim propose passe derrière, et il retaille.
    final champ = _champ(code, '');
    final ecrit = champ.text.trimRight();
    final fusion = [
      if (ecrit.isNotEmpty) ecrit,
      proposition.reprise,
    ].join('\n\n');

    champ.text = fusion;
    ref.read(planViewModelProvider(widget.study).notifier).write(code, fusion);
    _noter();
    _dire(text.preparationPlanArticulateTaken);
  }

  Future<void> _addSection(List<String> ajoutables) async {
    final text = AppText.of(context);

    final choisie = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final code in ajoutables)
              ListTile(
                title: Text(planSectionLabel(text, code)),
                onTap: () => Navigator.of(sheetContext).pop(code),
              ),
          ],
        ),
      ),
    );

    if (choisie == null) return;

    ref
        .read(planViewModelProvider(widget.study).notifier)
        .addSection(choisie);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final colors = context.colors;
    final state = ref.watch(planViewModelProvider(widget.study));
    final notifier = ref.read(planViewModelProvider(widget.study).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(text.preparationPlanTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
          tooltip: text.back,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              text.preparationPlanIntro,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final code in state.sections) ...[
              _Section(
                label: planSectionLabel(text, code),
                hint: code == PlanSkeleton.pointCentral
                    ? text.preparationPlanPointsHint
                    : '',
                controller: _champ(code, state.bodies[code] ?? ''),
                onChanged: (valeur) {
                  notifier.write(code, valeur);
                  _noter();
                },
                // Ce qu'il a écrit dans le fil en désignant ce point — gardé,
                // rangé, et **pas encore dans son plan**.
                notes: _notesDe(code, state.sections.indexOf(code)),
                notesLabel: text.preparationPlanNotes,
                promoteLabel: text.preparationPlanPromote,
                onPromote: _promotion == null ? _promouvoir : null,
                promoting: _promotion,
                articulateLabel: text.preparationPlanArticulate,
                // Une demande en vol ferme les autres : un seul appel, un seul
                // texte à lire.
                onArticulate: _demande == null ? () => _articuler(code) : null,
                articulating: _demande == code,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (state.addable.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addSection(state.addable),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(text.preparationPlanAdd),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: state.saving ? null : _save,
              child: Text(text.preparationPlanSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    required this.articulateLabel,
    required this.onArticulate,
    required this.articulating,
    required this.notes,
    required this.notesLabel,
    required this.promoteLabel,
    required this.onPromote,
    required this.promoting,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  final String articulateLabel;

  /// Nul pendant qu'une autre section attend sa proposition.
  final VoidCallback? onArticulate;
  final bool articulating;

  /// Ce que le pasteur a écrit dans le fil sous ce point — **et qui n'est pas
  /// encore son point**.
  ///
  /// 🔴 Elles étaient perdues : le fil ne se gardait pas. Elles sont maintenant
  /// rangées ici, dans son écriture, en attente d'un geste. C'est la réponse à
  /// *« ça peut être point ou pas, il peut mettre une pause et revenir
  /// changer »* — on ne décide pas, on garde.
  final List<ThreadLine> notes;
  final String Function(int) notesLabel;
  final String promoteLabel;
  final void Function(String entryId)? onPromote;
  final String? promoting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: 2,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            notesLabel(notes.length),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceWarm,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.body,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: promoting != null
                            ? null
                            : () => onPromote?.call(note.id),
                        child: Text(promoteLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        // Sous le champ, et discret : ce qu'Urim propose vient **après** ce que
        // le pasteur écrit, jamais avant.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: articulating ? null : onArticulate,
            icon: articulating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined, size: 18),
            label: Text(articulateLabel),
          ),
        ),
      ],
    );
  }
}

/// La proposition, lue avant d'être reprise.
///
/// ⚠️ **La signature du modèle a été retirée le 22/08, sur décision du fondateur.**
///
/// J'avais plaidé l'inverse le matin même — *une proposition sans son auteur
/// ressemble, six mois plus tard, à quelque chose qu'un homme a écrit*. L'usage
/// a tranché autrement : lire « écrit par mistral-small-latest » sous chaque
/// paragraphe encombre sans rien apprendre à celui qui vient de le demander.
///
/// **La provenance n'est pas perdue pour autant** : `urim_plan_suggestion.model`
/// la garde en base, à côté du texte. Elle n'est plus affichée ; elle reste
/// vérifiable.
class _ArticulationSheet extends StatelessWidget {
  const _ArticulationSheet(this.proposition);

  final Articulation proposition;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text.preparationPlanArticulateTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (proposition.body.trim().isNotEmpty)
                Text(
                  proposition.body.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              if (proposition.transition.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  text.preparationPlanArticulateTransition,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  proposition.transition.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                text.preparationPlanArticulateNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(text.preparationPlanArticulateClose),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(text.preparationPlanArticulateTake),
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
