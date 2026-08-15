import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/presentation/common/french_dates.dart';
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
      helpText: 'Date du culte',
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
            failure?.message ?? 'Cette préparation n\'a pas pu être ouverte.',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle préparation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: 'Retour',
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
                    'Une référence, une phrase que tu as en tête, ou ce que tu '
                    'veux dire. Écris comme ça vient.',
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
                    decoration: const InputDecoration(
                      hintText: 'Romains 8:15 — ou : que l\'amour fraternel '
                          'continue — ou : je veux parler de la persévérance à '
                          'des étudiants qui décrochent',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _DictationRow(),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Pour quel dimanche'),
                  SectionCard(
                    children: [
                      SettingNavRow(
                        title: 'Date du culte',
                        value: _serviceDate == null
                            ? 'À définir'
                            : 'dim. ${frenchDayMonth(_serviceDate!)}',
                        onTap: _pickServiceDate,
                      ),
                      const SettingNavRow(
                        title: 'Espace',
                        value: 'Personnel',
                        subtitle: 'Le partage avec une église attend que le '
                            'rattachement existe.',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aucun mode à choisir. Le moteur regarde si les mots que '
                    'tu écris se suivent comme dans l\'Écriture — c\'est '
                    'l\'ordre des mots qui décide, jamais le vocabulaire.',
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
                  child: const Text('Ouvrir la préparation'),
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
            'Ou dicte — Urim te fera confirmer avant d\'aller plus loin. '
            'La dictée attend le moteur de reconnaissance.',
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
