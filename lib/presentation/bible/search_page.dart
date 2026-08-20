import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/domain/entities/bible/passage_detail.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/bible/search_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Regarder dans le corpus sans s'engager sur un texte.
///
/// Deux questions, un écran : *que dit ce passage* et *où ce mot paraît-il
/// ailleurs*. La seconde est la seule pierre du module de recherche qui ne
/// puisse rien inventer — elle montre le texte, elle ne dit rien du monde.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _saisie = TextEditingController();
  SearchMode _mode = SearchMode.passage;

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  void _chercher() => ref
      .read(searchViewModelProvider.notifier)
      .search(mode: _mode, query: _saisie.text);

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final state = ref.watch(searchViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(text.searchTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
          tooltip: text.back,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<SearchMode>(
                    segments: [
                      ButtonSegment(
                        value: SearchMode.passage,
                        label: Text(text.searchPassageTab),
                      ),
                      ButtonSegment(
                        value: SearchMode.word,
                        label: Text(text.searchWordTab),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (choix) =>
                        setState(() => _mode = choix.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _saisie,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _chercher(),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: _mode == SearchMode.passage
                          ? text.searchPassageHint
                          : text.searchWordHint,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _chercher,
                        tooltip: text.searchAction,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _resultat(state, text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultat(AsyncValue<Object?> state, AppText text) {
    if (state is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state case AsyncError(:final error)) {
      return _Message(body: _phrase(error));
    }

    final passage = passageOf(state);
    if (passage != null) return _PassageResult(passage: passage);

    final concordance = concordanceOf(state);
    if (concordance != null) return _ConcordanceResult(concordance: concordance);

    return _Message(body: text.searchEmpty);
  }

  /// Le message du serveur quand il en a un — « ce mot ne paraît dans aucun
  /// texte original de ce corpus » vaut mieux qu'un refus muet.
  String _phrase(Object error) {
    final brut = error.toString();

    return brut.contains('message: ')
        ? brut.split('message: ').last.split(',').first
        : brut;
  }
}

/// Qui a signé cette unité — ou l'aveu qu'aucun homme ne l'a fait.
///
/// `ia-mistral` n'est pas un relecteur : c'est le modèle qui a écrit. Les
/// confondre reviendrait à faire passer une production pour une relecture.
String _signature(AppText text, String? relu) =>
    relu == null || relu.startsWith('ia-') || relu == 'semis-demo'
        ? text.searchNotReviewed
        : text.searchReviewedBy(relu);

class _Message extends StatelessWidget {
  const _Message({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.colors.textSecondary, height: 1.5),
        ),
      );
}

/// Ce que le corpus sait d'un passage.
class _PassageResult extends StatelessWidget {
  const _PassageResult({required this.passage});

  final PassageDetail passage;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (passage.pericopeLabel case final String label) ...[
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          // Qui a signé, ou l'aveu. C'est la différence entre un énoncé relu et
          // un énoncé produit que personne n'a lu.
          Text(
            _signature(text, passage.reviewedBy),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          if (passage.pericopeRationale case final String motif) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(motif, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
        if (passage.units.length > 1) ...[
          _Titre(text.searchUnitsTitle),
          for (final unite in passage.units)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(unite.label),
              subtitle: Text(unite.reference),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (passage.verses.isNotEmpty) ...[
          for (final verset in passage.verses) ...[
            Text(verset.reference, style: theme.textTheme.titleSmall),
            Text(
              verset.text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (passage.context.isNotEmpty) ...[
          _Titre(text.searchContextTitle),
          for (final note in passage.context) ...[
            Text(note.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              note.sourceRef,
              style: theme.textTheme.labelSmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (passage.caveats.isNotEmpty) ...[
          _Titre(text.searchCaveatsTitle),
          for (final reserve in passage.caveats) ...[
            Text(reserve, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (passage.variants.isNotEmpty) ...[
          _Titre(text.searchVariantsTitle),
          for (final variante in passage.variants) ...[
            Text(variante.reference, style: theme.textTheme.titleSmall),
            Text(variante.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (passage.bearings.isNotEmpty) ...[
          _Titre(text.searchBearingsTitle),
          for (final pesee in passage.bearings) ...[
            Text(
              '${pesee.label} · ${pesee.strength}',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              pesee.rationale,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }
}

/// Où ce mot paraît ailleurs.
class _ConcordanceResult extends StatelessWidget {
  const _ConcordanceResult({required this.concordance});

  final Concordance concordance;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text(concordance.lemma, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          text.searchOccurrences(concordance.total),
          style: theme.textTheme.labelMedium?.copyWith(color: colors.textSecondary),
        ),
        // ⚠️ Le compte réel et ce qui est montré sont deux choses : un extrait
        // présenté comme un tout ferait conclure d'un échantillon.
        if (concordance.isTruncated) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            text.searchTruncated(concordance.occurrences.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Ce que le corpus n'a pas, dit une fois : la glose manque pour la
        // quasi-totalité des lemmes, et le taire laisserait croire que la
        // concordance *est* le sens.
        Text(
          text.searchNoGloss,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final occurrence in concordance.occurrences) ...[
          Text(
            '${occurrence.reference} · ${occurrence.surface}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            occurrence.text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.body);

  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          body,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 0.6,
              ),
        ),
      );
}
