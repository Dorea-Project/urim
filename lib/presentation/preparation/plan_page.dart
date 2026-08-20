import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/preparation/plan_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Écrire son plan.
///
/// **Le seul écran d'Urim où le pasteur écrit son sermon**, et le seul où Urim
/// ne propose rien : le squelette donne un ordre, pas un texte. Une section
/// vide reste vide — le document le dit lui-même, « il ne l'écrit pas à votre
/// place ».
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({required this.study, super.key});

  final Study study;

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  /// Un contrôleur par section, créé à la demande et libéré avec l'écran.
  ///
  /// Reconstruire le champ à chaque frappe déplacerait le curseur ; le
  /// contrôleur garde la position, l'état garde le texte.
  final Map<String, TextEditingController> _champs = {};

  @override
  void dispose() {
    for (final champ in _champs.values) {
      champ.dispose();
    }
    super.dispose();
  }

  TextEditingController _champ(String code, String valeur) =>
      _champs.putIfAbsent(code, () => TextEditingController(text: valeur));

  Future<void> _save() async {
    final text = AppText.of(context);
    final failure =
        await ref.read(planViewModelProvider(widget.study).notifier).save();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure?.message ?? text.preparationPlanSaved)),
    );

    // Poussé par le Navigator, refermé par lui : l'écran ne dépend pas du
    // routeur, ce qui le rend ouvrable depuis n'importe où dans le fil.
    if (failure == null) await Navigator.maybePop(context);
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
                onChanged: (valeur) => notifier.write(code, valeur),
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
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
      ],
    );
  }
}
