import 'package:flutter/material.dart';
import 'package:urim/domain/entities/preparation/turn.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/ruled_content.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Ce que le pasteur a fait d'un geste : une décision, ou un rejet.
typedef OnDecision = void Function({
  required String stageCode,
  required String optionCode,
  required String label,
});

typedef OnDismiss = void Function({
  required String stageCode,
  required String optionCode,
});

/// Un tour d'Urim : les trois phrases, puis les blocs.
///
/// **Rien n'est réécrit ici.** Le `say`, le `why` et le `ask` viennent du
/// serveur tels quels, et les intitulés de groupe aussi. L'écran fournit la
/// mise en forme, jamais les mots : une phrase fabriquée côté application
/// échapperait à la relecture, aux tests, et à la règle du filet doré.
class TurnView extends StatelessWidget {
  const TurnView({
    super.key,
    required this.turn,
    required this.live,
    required this.onDecision,
    required this.onDismiss,
  });

  final Turn turn;

  /// Seul le dernier tour est vivant. Plus haut, le moteur a avancé : répondre
  /// enverrait une décision à un étage qui n'attend plus.
  final bool live;

  final OnDecision onDecision;
  final OnDismiss onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.of(context).blockUrim,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DottedRuledContent(
            color: colors.textSecondary,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ce qu'Urim vient de faire.
                  if (turn.say.isNotEmpty)
                    Text(
                      turn.say,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                  for (final block in turn.blocks) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _BlockView(
                      block: block,
                      turn: turn,
                      live: live,
                      onDecision: onDecision,
                      onDismiss: onDismiss,
                    ),
                  ],
                  // La question vient après ce qu'il y a à regarder : on ne
                  // demande pas de choisir avant d'avoir montré entre quoi.
                  if (turn.ask.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      turn.ask,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Le filet doré. Il n'est jamais replié : c'est ce qui distingue une
          // proposition d'un oracle, et le replier reviendrait à le rendre
          // facultatif.
          if (turn.why.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: RuledContent(
                color: colors.border,
                gap: AppSpacing.md,
                child: Text(
                  turn.why,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
          if (turn.signature case final String signature) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl),
              child: Text(
                AppText.of(context).turnSignature(signature),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le `switch` est exhaustif sur un type scellé : un bloc nouveau fera échouer
/// la compilation ici, ce qui est exactement le rappel voulu.
class _BlockView extends StatelessWidget {
  const _BlockView({
    required this.block,
    required this.turn,
    required this.live,
    required this.onDecision,
    required this.onDismiss,
  });

  final TurnBlock block;
  final Turn turn;
  final bool live;
  final OnDecision onDecision;
  final OnDismiss onDismiss;

  @override
  Widget build(BuildContext context) => switch (block) {
        ChipsBlock(:final items) => _Chips(
            items: items,
            stageCode: turn.stageCode,
            live: live,
            onDecision: onDecision,
            onDismiss: onDismiss,
          ),
        UnitsBlock(:final groups) => _Units(
            groups: groups,
            stageCode: turn.stageCode,
            live: live,
            onDecision: onDecision,
          ),
        BoundsBlock(:final items, :final consequence) => _Bounds(
            items: items,
            consequence: consequence,
            stageCode: turn.stageCode,
            live: live,
            onDecision: onDecision,
          ),
        BearingsBlock(:final items, :final caveats, :final decideStage) =>
          _Bearings(
            items: items,
            caveats: caveats,
            // ⚠️ L'étage des pesées, pas celui du tour. Envoyer la décision à
            // l'étage courant serait refusé par le serveur.
            stageCode: decideStage,
            live: live,
            onDecision: onDecision,
          ),
        FeasibilityBlock(:final items) => _Feasibility(items: items),
        ThemeBlock(:final body) => _Theme(body: body),
        ActionsBlock(:final items) => _Actions(items: items),
        // Un `kind` que cette version ne connaît pas : tu plutôt que rendu de
        // travers. Le reste du tour reste lisible.
        UnknownBlock() => const SizedBox.shrink(),
      };
}

/// Une carte tactile, l'unité visuelle de tous les choix.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.hint,
    required this.live,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.badge,
  });

  final String label;
  final String hint;
  final bool live;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? colors.textPrimary : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: live ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
              ),
              if (badge case final Widget badge) badge,
            ],
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );

    if (!live || onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      onLongPress: onLongPress,
      child: card,
    );
  }
}

/// Les pastilles.
///
/// Des raccourcis, jamais des barreaux : le pasteur peut aussi taper le libellé
/// dans la barre, et le serveur le reconnaîtra. Un appui long écarte — ce qui
/// n'avance aucun étage, mais apprend au tour suivant de ne pas reproposer.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.items,
    required this.stageCode,
    required this.live,
    required this.onDecision,
    required this.onDismiss,
  });

  final List<ChipItem> items;
  final String stageCode;
  final bool live;
  final OnDecision onDecision;
  final OnDismiss onDismiss;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final item in items) ...[
            _OptionCard(
              label: item.label,
              hint: item.hint,
              live: live,
              selected: item.selected,
              badge: item.signature == null
                  ? null
                  : _SignatureBadge(signature: item.signature!),
              onTap: () => onDecision(
                stageCode: stageCode,
                optionCode: item.code,
                label: item.label,
              ),
              onLongPress: () => onDismiss(
                stageCode: stageCode,
                optionCode: item.code,
              ),
            ),
            if (item != items.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
}

/// Les unités relues, groupées par ce qu'elles font du sujet.
///
/// « Lui résiste » s'affiche **au même rang** que les deux autres groupes :
/// c'est la seule mécanique anti-proof-texting du produit, et la reléguer
/// reviendrait à fabriquer la preuve de ce qu'on avait décidé de trouver.
class _Units extends StatelessWidget {
  const _Units({
    required this.groups,
    required this.stageCode,
    required this.live,
    required this.onDecision,
  });

  final List<UnitGroup> groups;
  final String stageCode;
  final bool live;
  final OnDecision onDecision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (group.role == 'resiste') ...[
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  // L'intitulé vient du serveur — l'application ne le traduit
                  // pas et n'en invente pas d'autre.
                  child: Text(
                    group.heading,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: group.role == 'resiste'
                          ? theme.colorScheme.error
                          : colors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final item in group.items) ...[
            _OptionCard(
              label: item.label,
              hint: item.rationale,
              live: live,
              onTap: () => onDecision(
                stageCode: stageCode,
                optionCode: item.code,
                label: item.label,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

/// L'unité relue contre les bornes du pasteur.
///
/// La conséquence se lit **avant** de choisir : garder ses bornes coupe
/// l'alerte sur le risque de proof-texting, et l'apprendre après serait
/// l'apprendre trop tard.
class _Bounds extends StatelessWidget {
  const _Bounds({
    required this.items,
    required this.consequence,
    required this.stageCode,
    required this.live,
    required this.onDecision,
  });

  final List<ChipItem> items;
  final String consequence;
  final String stageCode;
  final bool live;
  final OnDecision onDecision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (consequence.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  consequence,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final item in items) ...[
          _OptionCard(
            label: item.label,
            hint: item.hint,
            live: live,
            onTap: () => onDecision(
              stageCode: stageCode,
              optionCode: item.code,
              label: item.label,
            ),
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Ce que le texte porte — et ce à quoi il résiste.
///
/// Un axe `selectable` peut être pris **à la place** de celui qui est retenu.
/// Le geste existait de bout en bout côté serveur ; rien ne le disait. Une
/// porte ouverte que personne ne voit est pire qu'une porte fermée.
class _Bearings extends StatelessWidget {
  const _Bearings({
    required this.items,
    required this.caveats,
    required this.stageCode,
    required this.live,
    required this.onDecision,
  });

  final List<BearingItem> items;
  final List<String> caveats;
  final String stageCode;
  final bool live;
  final OnDecision onDecision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          _OptionCard(
            label: item.label,
            hint: item.rationale,
            live: live && item.selectable,
            selected: item.selected,
            badge: _StrengthBadge(strength: item.strength),
            onTap: item.selectable
                ? () => onDecision(
                      stageCode: stageCode,
                      optionCode: item.axisCode,
                      label: item.label,
                    )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final caveat in caveats) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  caveat,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (live && items.any((item) => item.selectable)) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            text.turnBearingsSwitchable,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Les couples plan × matière. Les refusés voyagent avec les faisables : les
/// cacher laisserait croire qu'on n'y a pas pensé.
class _Feasibility extends StatelessWidget {
  const _Feasibility({required this.items});

  final List<FeasibilityItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Column(
      children: [
        for (final item in items) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item.feasible ? Icons.check : Icons.block,
                      size: 15,
                      color: item.feasible
                          ? colors.success
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${item.planSource} · ${item.subjectMatter}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                for (final motif in [item.rationale, item.risk])
                  if (motif.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      motif,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
              ],
            ),
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Un thème, jamais un titre — le titre, c'est la voix du pasteur.
class _Theme extends StatelessWidget {
  const _Theme({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RuledContent(
      color: context.colors.success,
      gap: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.of(context).turnThemeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Les sorties. Un bouton fermé **porte toujours son motif** : un bouton grisé
/// muet est un mensonge poli.
class _Actions extends StatelessWidget {
  const _Actions({required this.items});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.enabled ? Icons.arrow_forward : Icons.lock_outline,
                size: 16,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: item.enabled
                            ? context.colors.textPrimary
                            : context.colors.textSecondary,
                      ),
                    ),
                    if (item.unavailableReason.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.unavailableReason,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// `dominant`, `porte`, `resiste`, `absent` — le vocabulaire du moteur, nommé
/// en français à un seul endroit.
class _StrengthBadge extends StatelessWidget {
  const _StrengthBadge({required this.strength});

  final String strength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(context);

    final (libelle, couleur) = switch (strength) {
      'dominant' => (text.strengthDominant, context.colors.success),
      'porte' => (text.strengthSupports, context.colors.success),
      'resiste' => (text.strengthResists, theme.colorScheme.error),
      'absent' => (text.strengthAbsent, context.colors.textSecondary),
      // Une force que cette version ne connaît pas : son code, plutôt qu'un
      // mot français inventé sur place.
      _ => (strength, context.colors.textSecondary),
    };

    return Text(
      libelle,
      style: theme.textTheme.labelLarge?.copyWith(
        fontSize: 12,
        color: couleur,
      ),
    );
  }
}

/// Qui a **habillé** la proposition, quand ce n'est pas le corpus.
class _SignatureBadge extends StatelessWidget {
  const _SignatureBadge({required this.signature});

  final String signature;

  @override
  Widget build(BuildContext context) => Text(
        signature,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
      );
}
