import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/preparation/widgets/folded_section.dart';
import 'package:urim/presentation/settings/settings_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/theme/app_typography.dart';

/// Ce que la préparation porte **et que personne ne montrait**.
///
/// 🔴 Le fil parle de l'unité, la pèse, propose des plans — et n'affiche jamais
/// les versets. Le pasteur travaillait sur un passage qu'il ne voyait nulle
/// part ; seul le document imprimé le portait. Et le contexte littéraire est
/// calculé à l'ouverture, écrit dans la trace, stocké : un pasteur l'a demandé
/// alors que la réponse était **déjà dans sa préparation**.
///
/// Offert, donc, sans qu'il ait à le demander — mais **replié**, sous son
/// intitulé et son nombre, comme le décor ambiant. Ce qui parle reste déplié ;
/// ce qui accompagne attend d'être ouvert.
///
/// Rien n'est affiché de ce qui est absent : le corpus n'a pas de note de
/// contexte sur toutes les unités, et une section vide promettrait ce qu'elle
/// n'a pas.
class StudyMaterial extends StatelessWidget {
  const StudyMaterial({super.key, required this.study});

  final Study study;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);

    if (study.verses.isEmpty && study.context.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (study.verses.isNotEmpty)
            FoldedSection(
              label: text.studyText(study.verses.length),
              builder: (_) => _Retrait(child: _Verses(verses: study.verses)),
            ),
          if (study.context.isNotEmpty)
            FoldedSection(
              label: text.studyContext(study.context.length),
              builder: (_) => _Retrait(child: _Context(notes: study.context)),
            ),
        ],
      ),
    );
  }
}

/// Le contenu ouvert, en retrait de son intitulé.
class _Retrait extends StatelessWidget {
  const _Retrait({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          bottom: AppSpacing.sm,
        ),
        child: child,
      );
}

/// Le texte, dans la police de lecture et à la taille réglée.
///
/// Servi par le corpus, jamais saisi — c'est ce qui le distingue d'une citation
/// projetée, et pourquoi rien n'est à contrôler ici.
class _Verses extends ConsumerWidget {
  const _Verses({required this.verses});

  final List<ServedVerse> verses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(effectiveSettingsProvider);
    final style = AppTypography.reading.copyWith(
      fontSize: AppTypography.reading.fontSize! * settings.readingTextSize.scale,
      color: context.colors.textPrimary,
      height: 1.55,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final verse in verses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${verse.reference}  ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextSpan(text: verse.text, style: style),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Le contexte, avec sa nature et sa provenance.
class _Context extends StatelessWidget {
  const _Context({required this.notes});

  final List<ContextNote> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (note.kind) {
                    'litteraire' => text.studyContextLiterary,
                    'historique' => text.studyContextHistorical,
                    // Une nature que cette version ne connaît pas : son code,
                    // plutôt qu'un mot français inventé sur place.
                    _ => note.kind,
                  },
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  note.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                if (note.sourceRef.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    note.sourceRef,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
