import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Saisie d'un code chiffre par chiffre.
///
/// Une seule zone de saisie invisible pilote toutes les cases. L'alternative —
/// un champ par case — oblige à gérer soi-même le passage d'une case à
/// l'autre, le collage depuis le presse-papiers et l'effacement arrière, pour
/// un résultat toujours un peu faux.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.length,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.hasError = false,
    this.obscure = false,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final bool hasError;

  /// Masque les chiffres — pour un code secret, pas pour un code SMS que
  /// l'utilisateur relit depuis sa messagerie.
  final bool obscure;

  @override
  State<CodeInput> createState() => CodeInputState();
}

class CodeInputState extends State<CodeInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Vide la saisie — après un code refusé, sans renvoyer l'utilisateur sur
  /// l'écran précédent.
  void reset() {
    _controller.clear();
    setState(() {});
    _focusNode.requestFocus();
  }

  void _handleChange(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text;

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final filled = index < value.length;
            return _CodeBox(
              character: filled
                  ? (widget.obscure ? '•' : value[index])
                  : '',
              isActive: index == value.length && _focusNode.hasFocus,
              hasError: widget.hasError,
            );
          }),
        ),
        // Champ réel, rendu invisible mais bien présent : c'est lui qui reçoit
        // la frappe, ouvre le clavier et gère le presse-papiers.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onChanged: _handleChange,
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.character,
    required this.isActive,
    required this.hasError,
  });

  final String character;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final borderColor = hasError
        ? scheme.error
        : isActive
            ? scheme.primary
            : context.colors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 52,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 2 : 1,
        ),
      ),
      child: Text(
        character,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
            ),
      ),
    );
  }
}
