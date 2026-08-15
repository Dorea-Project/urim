import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Demande le nom affiché. Renvoie `null` si l'utilisateur renonce.
///
/// Le nom peut être effacé : personne n'est tenu de se nommer pour préparer un
/// message. Le champ vide est donc une réponse valide, pas une erreur.
Future<String?> askDisplayName({
  required BuildContext context,
  required String current,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _DisplayNameDialog(current: current),
  );
}

/// Boîte de saisie du nom.
///
/// Elle porte son propre contrôleur : le libérer depuis l'appelant, à la
/// fermeture de la boîte, le détruirait avant la fin de l'animation de sortie
/// — le champ est encore reconstruit pendant celle-ci.
class _DisplayNameDialog extends StatefulWidget {
  const _DisplayNameDialog({required this.current});

  final String current;

  @override
  State<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<_DisplayNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nom affiché'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 60,
            decoration: const InputDecoration(hintText: 'Kouadio Aristide'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ce nom ne sort pas de l\'application : il sert à te reconnaître '
            'sur cet écran, et à former ton monogramme.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
