import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/speech/dictation.dart';
import 'package:urim/core/speech/field_dictation.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/datasources/draft_local_data_source.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/draft_keeper.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/presentation/home/home_view_model.dart';
import 'package:urim/presentation/home/opening_rule.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// La première phrase, écrite là où on est déjà.
///
/// Il y avait ici un bouton qui menait à un écran qui portait un champ. Trois
/// gestes pour une phrase — et le pasteur qui ouvre Urim avec une idée en tête
/// la perd en chemin. Le champ est donc à l'accueil, sous le fil, et ce qu'on y
/// tape ouvre directement la préparation.
///
/// **Un seul champ, et aucun mode** : c'est l'ordre des mots qui décide de ce
/// qu'Urim fera de la phrase, pas une case cochée avant d'écrire. Le micro à
/// droite ne fait qu'écrire à la place des doigts — ce n'est pas la capture
/// d'une prédication, qui vit sur l'autre page et n'a rien à voir.
class PreparationComposer extends ConsumerStatefulWidget {
  const PreparationComposer({super.key, required this.onOpened});

  /// Ce qu'on fait de la préparation une fois ouverte.
  ///
  /// ⚠️ **Le composeur ne navigue pas.** Il poussait l'écran de la
  /// conversation, ce qui remettait un second champ identique sous les yeux du
  /// pasteur au moment où il venait d'écrire dans le premier. C'est l'accueil
  /// qui décide : chez lui, la conversation prend la place du champ vide, sans
  /// transition.
  final void Function(String id) onOpened;

  @override
  ConsumerState<PreparationComposer> createState() =>
      _PreparationComposerState();
}

class _PreparationComposerState extends ConsumerState<PreparationComposer> {
  final TextEditingController _controller = TextEditingController();
  late final DraftKeeper _brouillon;

  /// ⚠️ **Construite en `initState`.** Un `ref.read` dans `dispose` lève : le
  /// contexte est déjà démonté, et c'est exactement là qu'il faut refermer le
  /// micro.
  late final FieldDictation _dictee;

  DateTime? _serviceDate;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _dictee = FieldDictation(
      dictation: ref.read(dictationProvider),
      controller: _controller,
      onChanged: _quandLaDicteeParle,
    );
    // La même clé que le formulaire d'avant : une phrase laissée en plan par
    // l'ancienne version se retrouve ici, et non nulle part.
    _brouillon = DraftKeeper(
      source: ref.read(draftLocalDataSourceProvider),
      key: DraftLocalDataSource.ouvertureKey,
    );
    _reprendre();
  }

  /// La phrase de départ est ce qui a coûté le plus cher à écrire : c'est celle
  /// qu'on est allé chercher, et souvent la seule qu'on avait. Elle revient si
  /// l'ouverture n'a pas abouti.
  Future<void> _reprendre() async {
    final garde = await _brouillon.restore();
    if (garde == null || !mounted || _controller.text.isNotEmpty) return;

    _controller.text = garde.text;
    setState(() => _hasText = garde.text.trim().isNotEmpty);
  }

  void _quandLaDicteeParle() {
    if (!mounted) return;

    _brouillon.remember(_controller.text);
    setState(() => _hasText = _controller.text.trim().isNotEmpty);
  }

  @override
  void dispose() {
    _dictee.dispose();

    // On écrit d'abord, on détruit ensuite.
    _brouillon.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickServiceDate() async {
    final now = ref.read(clockProvider).now();

    // La date proposée suit l'assemblée, pas le calendrier : la même déduction
    // qui choisit l'écran d'ouverture sait quel jour on prêche ici.
    final summaries =
        ref.read(studyFeedProvider).value?.value ?? const <StudySummary>[];

    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate ?? nextService(from: now, summaries: summaries),
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
    // Le micro ne suit pas le pasteur sur l'écran suivant. Ce qui est déjà dans
    // le champ est ce qu'il a voulu dire ; la fin d'une phrase reconnue après
    // le départ n'irait nulle part.
    if (_dictee.isListening) {
      await _dictee.cancel();
      if (!mounted) return;
    }

    final (id, failure) =
        await ref.read(preparationOpenerProvider.notifier).open(
              text: _controller.text,
              serviceDate: _serviceDate,
            );

    if (!mounted) return;

    if (id == null) {
      // ⚠️ **Ouvrir est le seul geste qui ne peut pas attendre le réseau.**
      // Décider, écarter, parler se mettent en file (Q4) parce que le serveur
      // sait les rejouer. Lire une phrase, non : ça demande le corpus, et il
      // n'est pas sur l'appareil. On le dit avec sa raison, et on rappelle que
      // la phrase est gardée — sinon le pasteur croit l'avoir perdue au moment
      // où il vient de l'écrire.
      final message = switch (failure) {
        NetworkFailure() => AppText.of(context).newPreparationNeedsNetwork,
        final Failure autre => autre.message,
        null => AppText.of(context).newPreparationFailed,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    // La préparation existe : la copie locale n'a plus de raison d'être.
    // **Sans attendre** — ranger le brouillon est du ménage, et faire dépendre
    // la navigation d'une écriture locale ferait rater sa préparation au
    // pasteur pour une raison qui ne le concerne pas.
    _brouillon.forget();

    // Le champ se vide : ce qu'on vient d'ouvrir n'a plus à traîner sous le fil
    // quand on reviendra.
    _controller.clear();
    setState(() {
      _hasText = false;
      _serviceDate = null;
    });

    widget.onOpened(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);
    final isBusy = ref.watch(preparationOpenerProvider).isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ce qui n'apparaît qu'une fois la phrase commencée : tant qu'il n'y a
        // rien à ouvrir, la date du culte n'a rien à dater.
        if (_hasText) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                _serviceDate == null
                    ? text.newPreparationServiceDate
                    : frenchShortDate(_serviceDate!),
              ),
              onPressed: _pickServiceDate,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_dictee.refusal case final DictationRefusal refus) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              _refusalMessage(text, refus),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.45,
              ),
            ),
          ),
        ],
        TextField(
          controller: _controller,
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) {
            _brouillon.remember(value);
            setState(() => _hasText = value.trim().isNotEmpty);
          },
          decoration: InputDecoration(
            // Le champ dit lui-même qu'on l'écoute. Un libellé séparé sous le
            // champ ferait un deuxième endroit à regarder pour savoir si le
            // micro est ouvert — et c'est déjà ce qu'on reproche à un micro.
            hintText: _dictee.isListening
                ? text.newPreparationDictateListening
                : text.homeComposerHint,
            hintStyle: TextStyle(color: colors.textMuted),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _dictee.isListening ? Icons.stop_circle_outlined : Icons.mic_none,
                    color: _dictee.isListening
                        ? theme.colorScheme.primary
                        : colors.textSecondary,
                  ),
                  tooltip: _dictee.isListening
                      ? text.newPreparationDictateStop
                      : text.newPreparationDictateStart,
                  onPressed: _dictee.toggle,
                ),
                if (_hasText)
                  IconButton(
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward),
                    tooltip: text.newPreparationOpen,
                    onPressed: isBusy ? null : _open,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Un refus est une réponse, pas une panne : chacun dit ce qui manque et ce
/// qu'on peut faire à la place.
String _refusalMessage(AppText text, DictationRefusal refusal) =>
    switch (refusal) {
      DictationRefusal.noEngine => text.newPreparationDictateNoEngine,
      DictationRefusal.micRefused => text.newPreparationDictateMicRefused,
      DictationRefusal.engineFailed => text.newPreparationDictateFailed,
    };
