import 'package:flutter/material.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Demande le **nouveau** numéro. Renvoie `null` si l'utilisateur renonce.
///
/// Le code partira là-bas, et non sur l'ancien : c'est le nouveau numéro qu'il
/// faut prouver, l'ancien l'ayant été le jour de l'inscription.
Future<PhoneNumber?> askNewPhone({
  required BuildContext context,
  required PhoneNumber current,
}) {
  return showDialog<PhoneNumber>(
    context: context,
    builder: (dialogContext) => _PhoneChangeDialog(current: current),
  );
}

class _PhoneChangeDialog extends StatefulWidget {
  const _PhoneChangeDialog({required this.current});

  final PhoneNumber current;

  @override
  State<_PhoneChangeDialog> createState() => _PhoneChangeDialogState();
}

class _PhoneChangeDialogState extends State<_PhoneChangeDialog> {
  // Le contrôleur vit avec la boîte : le libérer depuis l'appelant le
  // détruirait avant la fin de l'animation de sortie, pendant laquelle le
  // champ est encore reconstruit.
  late final TextEditingController _dialCode =
      TextEditingController(text: widget.current.dialCode);
  late final TextEditingController _number = TextEditingController();

  PhoneNumber get _entered => PhoneNumber(
        dialCode: _dialCode.text.trim(),
        nationalNumber: PhoneNumber.normalize(_number.text),
      );

  @override
  void dispose() {
    _dialCode.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final phone = _entered;
    // Le même numéro n'est pas un changement : le serveur enverrait un code
    // pour ne rien changer.
    final valid = phone.isValid && phone != widget.current;

    return AlertDialog(
      title: Text(text.profilePhoneChangeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text.profilePhoneChangeBody),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _dialCode,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _number,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (valid) Navigator.of(context).pop(phone);
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: widget.current.nationalNumber,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.cancel),
        ),
        TextButton(
          onPressed: valid ? () => Navigator.of(context).pop(phone) : null,
          child: Text(text.profilePhoneChangeConfirm),
        ),
      ],
    );
  }
}
