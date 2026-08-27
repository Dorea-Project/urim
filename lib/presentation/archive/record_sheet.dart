import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/archive/archive_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Consigner une prédication qui n'est pas passée par Urim.
///
/// 🔴 **Sans elle, l'archive ne mesurerait que ce qui est passé par l'outil** —
/// et ce n'est pas la même chose que le ministère de quelqu'un. Un pasteur a
/// prêché avant Dorea, et il prêche ailleurs.
///
/// ⚠️ **La référence part dans sa notation.** Le serveur lit « Hb 2v29 » comme
/// « Jn14v28 » et vérifie contre le corpus ; un refus dit ce qui manque au
/// corpus — *« Hébreux 2 compte 18 versets »* — jamais ce qui manque au
/// pasteur. L'écran rend donc ce message tel quel, sans le reformuler.
Future<void> showRecordSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _RecordSheet(),
    );

class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet();

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  final TextEditingController _reference = TextEditingController();

  DateTime? _jour;
  bool _envoi = false;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  /// Le jour n'est **pas** préchoisi à aujourd'hui.
  ///
  /// Cette feuille sert d'abord à rattraper le passé : proposer aujourd'hui
  /// ferait consigner la date du jour à celui qui tape vite, et une archive
  /// mal datée fausse la couverture sans que rien ne le signale.
  Future<void> _choisirLeJour() async {
    final maintenant = ref.read(clockProvider).now();

    final choisi = await showDatePicker(
      context: context,
      initialDate: _jour ?? maintenant,
      firstDate: DateTime(maintenant.year - 20),
      lastDate: maintenant,
      helpText: AppText.of(context).archiveRecordDate,
    );

    if (choisi != null) setState(() => _jour = choisi);
  }

  Future<void> _consigner() async {
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    final text = AppText.of(context);

    setState(() => _envoi = true);

    final result = await ref.read(studyRepositoryProvider).recordPreached(
          reference: _reference.text.trim(),
          preachedOn: _jour!,
        );

    if (!mounted) return;
    setState(() => _envoi = false);

    result.fold(
      onSuccess: (_) {
        // L'archive et la couverture ont vieilli toutes les deux.
        ref.invalidate(archiveProvider);
        ref.invalidate(coverageProvider);

        navigateur.pop();
        messager.showSnackBar(
          SnackBar(content: Text(text.archiveRecordDone)),
        );
      },
      // Le motif du corpus, tel quel : il dit ce qui manque au corpus, et le
      // reformuler ferait perdre la seule information utile.
      onFailure: (Failure failure) => messager.showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    final pret = _reference.text.trim().isNotEmpty && _jour != null && !_envoi;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.archiveRecordManual,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _reference,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: text.archiveRecordHint,
                hintStyle: TextStyle(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.event_outlined, size: 18),
                label: Text(
                  _jour == null
                      ? text.archiveRecordDate
                      : frenchShortDate(_jour!),
                ),
                onPressed: _choisirLeJour,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: pret ? _consigner : null,
                child: _envoi
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(text.archiveRecordSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
