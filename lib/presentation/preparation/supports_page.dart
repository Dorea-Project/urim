import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// La chaîne de textes d'appui.
///
/// **Un sermon convoque une chaîne ; Urim n'en tenait qu'un maillon.** Deux
/// prédications réelles portaient huit textes, puis douze — et dans la seconde,
/// deux références inexistantes. Le contrôle savait le dire depuis le premier
/// jour ; il manquait une surface où ces textes soient soumis.
///
/// Les saisies partent **brutes**, dans la notation du pasteur : c'est le
/// serveur qui les lit, parce que c'est lui qui a le corpus. Une saisie
/// illisible n'interrompt rien — elle revient avec son motif, et le pasteur
/// garde ce qu'il voulait citer.
class SupportsPage extends ConsumerStatefulWidget {
  const SupportsPage({required this.study, super.key});

  final Study study;

  @override
  ConsumerState<SupportsPage> createState() => _SupportsPageState();
}

class _SupportsPageState extends ConsumerState<SupportsPage> {
  late List<SupportText> _textes = [...widget.study.supports];
  final Map<int, TextEditingController> _champs = {};
  bool _envoi = false;

  @override
  void dispose() {
    for (final champ in _champs.values) {
      champ.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final text = AppText.of(context);
    final messager = ScaffoldMessenger.of(context);

    setState(() => _envoi = true);

    final result = await ref.read(studyRepositoryProvider).setSupports(
          studyId: widget.study.id,
          supports: [
            for (final texte in _textes)
              if (texte.raw.trim().isNotEmpty) texte.raw.trim(),
          ],
        );

    if (!mounted) return;
    setState(() => _envoi = false);

    result.fold(
      onSuccess: (etude) {
        // Ce que le serveur a lu remplace ce qui était à l'écran : chaque
        // saisie revient résolue, ou avec la raison pour laquelle elle ne l'est
        // pas. C'est tout l'objet de l'envoi.
        setState(() {
          _textes = [...etude.supports];
          _champs.clear();
        });
        messager.showSnackBar(
          SnackBar(content: Text(text.preparationSupportsSaved)),
        );
      },
      onFailure: (failure) => messager.showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(text.preparationSupportsTitle),
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
              text.preparationSupportsIntro,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final (index, texte) in _textes.indexed) ...[
              _SupportRow(
                texte: texte,
                controller: _champs.putIfAbsent(
                  index,
                  () => TextEditingController(text: texte.raw),
                ),
                onChanged: (valeur) => _textes[index] = SupportText(
                  raw: valeur,
                  reference: texte.reference,
                  text: texte.text,
                  verdict: texte.verdict,
                ),
                onRemove: () => setState(() {
                  _textes.removeAt(index);
                  _champs.clear();
                }),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => _textes = [..._textes, const SupportText(raw: '')],
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(text.preparationSupportsAdd),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _envoi ? null : _save,
              child: Text(text.preparationSupportsSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une saisie, et ce que le corpus en a fait.
class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.texte,
    required this.controller,
    required this.onChanged,
    required this.onRemove,
  });

  final SupportText texte;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);
    final refuse = texte.verdict.isNotEmpty && !texte.isResolved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: text.preparationSupportsHint,
                  errorText: refuse ? texte.verdict : null,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              tooltip: text.preparationDeckRemove,
            ),
          ],
        ),
        // Ce que le corpus a servi pour cette saisie. Le verset s'affiche sous
        // la ligne qui l'a demandé : le pasteur vérifie qu'il a bien convoqué
        // ce qu'il croyait convoquer.
        if (texte.isResolved) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(texte.reference, style: theme.textTheme.titleSmall),
          if (texte.text.isNotEmpty)
            Text(
              texte.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
        ],
      ],
    );
  }
}
