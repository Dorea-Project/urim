import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/presentation/common/french_dates.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/section_card.dart';
import 'package:urim/presentation/home/home_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Ouverture d'une préparation écrite.
///
/// Un seul champ, et aucun mode : c'est l'ordre des mots qui décide de ce
/// qu'Urim fera de la phrase, pas une case cochée avant d'écrire.
class NewPreparationPage extends ConsumerStatefulWidget {
  const NewPreparationPage({super.key});

  @override
  ConsumerState<NewPreparationPage> createState() => _NewPreparationPageState();
}

class _NewPreparationPageState extends ConsumerState<NewPreparationPage> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _serviceDate;
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickServiceDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate ?? _nextSunday(now),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: AppText.of(context).newPreparationServiceDate,
      // Le dimanche est le cas courant, pas une contrainte : on prêche aussi
      // en semaine.
      selectableDayPredicate: null,
    );

    if (picked != null) setState(() => _serviceDate = picked);
  }

  Future<void> _open() async {
    final (id, failure) = await ref.read(preparationOpenerProvider.notifier).open(
          text: _controller.text,
          serviceDate: _serviceDate,
        );

    if (!mounted) return;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure?.message ??
                AppText.of(context).newPreparationFailed,
          ),
        ),
      );
      return;
    }

    // On remplace le formulaire : revenir dessus depuis le fil n'aurait aucun
    // sens, la préparation est déjà ouverte.
    context.pushReplacementNamed(
      AppRoutes.preparationName,
      pathParameters: {'id': id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final isBusy = ref.watch(preparationOpenerProvider).isLoading;
    final text = AppText.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(text.newPreparationTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: text.back,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    text.newPreparationIntro,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _controller,
                    minLines: 5,
                    maxLines: 8,
                    autofocus: true,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) =>
                        setState(() => _hasText = value.trim().isNotEmpty),
                    decoration: InputDecoration(
                      hintText: text.newPreparationHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _DictationRow(),
                  const SizedBox(height: AppSpacing.xl),
                  SectionLabel(text.newPreparationServiceSection),
                  SectionCard(
                    children: [
                      SettingNavRow(
                        title: text.newPreparationServiceDate,
                        value: _serviceDate == null
                            ? text.newPreparationServiceDateEmpty
                            : text.newPreparationServiceDateValue(
                                frenchDayMonth(_serviceDate!),
                              ),
                        onTap: _pickServiceDate,
                      ),
                      SettingNavRow(
                        title: text.newPreparationSpace,
                        value: text.newPreparationSpacePersonal,
                        subtitle: text.newPreparationSpacePending,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    text.newPreparationNoModeNotice,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                  onPressed: _hasText && !isBusy ? _open : null,
                  child: Text(text.newPreparationOpen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La dictée, annoncée mais pas encore branchée.
class _DictationRow extends StatelessWidget {
  const _DictationRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(Icons.mic_none, size: 20, color: colors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            AppText.of(context).newPreparationDictate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}

/// Dimanche suivant, comme date proposée par défaut.
DateTime _nextSunday(DateTime from) {
  final daysUntilSunday = (DateTime.sunday - from.weekday + 7) % 7;
  return DateTime(from.year, from.month, from.day)
      .add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
}
