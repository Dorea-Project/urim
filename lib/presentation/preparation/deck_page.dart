import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/data/datasources/draft_local_data_source.dart';
import 'package:urim/domain/entities/preparation/deliverable.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/draft_keeper.dart';
import 'package:urim/presentation/preparation/deliverable_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Composer ce que l'assemblée verra.
///
/// **Ce n'est pas un export, c'est une soumission au contrôle.** Chaque
/// diapositive porte une référence et le texte tel qu'il montera à l'écran ;
/// le serveur le confronte au corpus, sur toutes les versions détenues, et
/// aucun fichier n'existe tant qu'un verset projeté n'est pas celui de la
/// Bible.
class DeckPage extends ConsumerStatefulWidget {
  const DeckPage({required this.study, super.key});

  final Study study;

  @override
  ConsumerState<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends ConsumerState<DeckPage> {
  late List<Slide> _slides = _depuisLeTexte();

  /// Ce qui est composé et pas encore soumis.
  ///
  /// ⚠️ Rien ne part avant le bouton. Douze diapositives coupées et reprises,
  /// un appel reçu, et le travail disparaissait — la même perte que la barre de
  /// saisie avant qu'elle soit gardée.
  late final DraftKeeper _brouillon;

  /// Les versets servis par le corpus, un par diapositive.
  ///
  /// Le pasteur part de ce que le texte porte plutôt que d'une page blanche —
  /// et il coupe. C'est **son** texte projeté qui sera jugé : partir du corpus
  /// ne garantit rien, ça évite seulement de recopier à la main ce qu'Urim a
  /// déjà servi.
  List<Slide> _depuisLeTexte() => [
        for (final verse in widget.study.verses)
          Slide(reference: verse.reference, projectedText: verse.text),
      ];

  final Map<int, TextEditingController> _references = {};
  final Map<int, TextEditingController> _textes = {};

  @override
  void initState() {
    super.initState();
    _brouillon = DraftKeeper(
      source: ref.read(draftLocalDataSourceProvider),
      key: DraftLocalDataSource.deckKey(widget.study.id),
    );
    _reprendre();
  }

  /// Ce qui avait été composé et jamais soumis revient à l'écran.
  ///
  /// Il remplace ce que le corpus avait pré-rempli : la composition du pasteur
  /// est postérieure, et lui rendre les versets nus effacerait ses coupes.
  Future<void> _reprendre() async {
    final garde = await _brouillon.restore();
    if (garde == null || !mounted || garde.text.isEmpty) return;

    final reprises = <Slide>[];
    for (final ligne in garde.text.split(DraftLocalDataSource.ligne)) {
      final morceaux = ligne.split(DraftLocalDataSource.champ);
      if (morceaux.length != 3) continue;
      reprises.add(Slide(
        title: morceaux[0],
        reference: morceaux[1],
        projectedText: morceaux[2],
      ));
    }

    if (reprises.isEmpty) return;

    setState(() {
      _slides = reprises;
      _references.clear();
      _textes.clear();
    });
  }

  /// Une diapositive par ligne — titre, référence, texte — séparés par un
  /// caractère nul, le seul qu'un pasteur ne tapera jamais.
  void _noter() => _brouillon.remember([
        for (final slide in _slides)
          [slide.title, slide.reference, slide.projectedText].join(DraftLocalDataSource.champ),
      ].join(DraftLocalDataSource.ligne));

  @override
  void dispose() {
    // On écrit d'abord, on détruit ensuite.
    _brouillon.dispose();
    for (final champ in [..._references.values, ..._textes.values]) {
      champ.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final text = AppText.of(context);
    final messager = ScaffoldMessenger.of(context);

    messager.showSnackBar(
      SnackBar(content: Text(text.preparationDocumentWorking)),
    );

    final issue = await ref.read(deliverableProducerProvider.notifier).produce(
          studyId: widget.study.id,
          kind: 'deck',
          slides: _slides.where((s) => s.isReady).toList(),
        );

    if (!mounted) return;
    messager.hideCurrentSnackBar();

    switch (issue) {
      case DocumentReady(:final path):
        // Le document existe : ce qui a servi à le composer n'a plus à être gardé.
        _brouillon.forget();
        messager.showSnackBar(
          SnackBar(content: Text(text.preparationDocumentReady(path))),
        );
        if (mounted) await Navigator.maybePop(context);
      case CitationRefused(:final dossier):
        setState(() => _verdicts = {
              for (final controle in dossier.controls)
                controle.slideNo: controle,
            });
      case DeliverableFailed(:final failure):
        messager.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  /// Ce que le corpus a répondu, diapositive par diapositive.
  Map<int, CitationCheck> _verdicts = const {};

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(text.preparationDeckTitle),
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
              text.preparationDeckIntro,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final (index, slide) in _slides.indexed) ...[
              _SlideCard(
                rang: index + 1,
                slide: slide,
                verdict: _verdicts[index + 1],
                reference: _references.putIfAbsent(
                  index,
                  () => TextEditingController(text: slide.reference),
                ),
                texte: _textes.putIfAbsent(
                  index,
                  () => TextEditingController(text: slide.projectedText),
                ),
                onReference: (valeur) {
                  setState(() => _slides[index] = slide.copyWith(reference: valeur));
                  _noter();
                },
                onTexte: (valeur) {
                  setState(
                    () => _slides[index] = slide.copyWith(projectedText: valeur),
                  );
                  _noter();
                },
                onRemove: () {
                  setState(() {
                    _slides.removeAt(index);
                    _references.clear();
                    _textes.clear();
                    _verdicts = const {};
                  });
                  _noter();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => _slides = [..._slides, const Slide(reference: '')],
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(text.preparationDeckAdd),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _slides.any((s) => s.isReady) ? _submit : null,
              child: Text(text.preparationDeckSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une diapositive, et le verdict du corpus quand il y en a un.
class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.rang,
    required this.slide,
    required this.verdict,
    required this.reference,
    required this.texte,
    required this.onReference,
    required this.onTexte,
    required this.onRemove,
  });

  final int rang;
  final Slide slide;
  final CitationCheck? verdict;
  final TextEditingController reference;
  final TextEditingController texte;
  final ValueChanged<String> onReference;
  final ValueChanged<String> onTexte;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);
    final refuse = verdict?.verdict == 'altere';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: refuse ? theme.colorScheme.error : colors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text.preparationDeckSlide(rang),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: colors.textSecondary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
                tooltip: text.preparationDeckRemove,
              ),
            ],
          ),
          TextField(
            controller: reference,
            onChanged: onReference,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: text.preparationDeckReference,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: texte,
            onChanged: onTexte,
            minLines: 2,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: text.preparationDeckProjected,
            ),
          ),
          // Le verdict se lit **sous la diapositive qu'il juge** : le pasteur
          // corrige là où il regarde, sans chercher quelle ligne d'un rapport
          // parle de quelle image.
          if (verdict case final CitationCheck controle) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              controle.rationale,
              style: theme.textTheme.bodySmall?.copyWith(
                color: refuse ? theme.colorScheme.error : colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
