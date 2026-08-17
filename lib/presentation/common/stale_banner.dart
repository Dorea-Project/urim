import 'package:flutter/material.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/french_dates.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Dit que ce qui est à l'écran vient de l'appareil, et depuis quand.
///
/// **Pourquoi ce n'est pas décoratif.** Le moteur rejoue son pipeline à chaque
/// lecture (D28) : ce qui a été gardé hier soir est ce qu'il *disait* hier
/// soir, pas ce qu'il dirait maintenant. Un pasteur qui prend une décision sur
/// un tour qu'il croit frais alors qu'il a une semaine agit sur une réponse
/// périmée — et il ne l'apprendrait qu'au refus du serveur.
///
/// Discret exprès : c'est une provenance, pas une alerte. Rien n'est cassé.
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.receivedAt, this.now});

  final DateTime receivedAt;

  /// Injectable pour les tests, qui ne peuvent pas dépendre de l'heure réelle.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 15,
            color: context.colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppText.of(context).servedFromDevice(
                _quand(receivedAt, now ?? DateTime.now()),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « aujourd'hui 21:14 », « hier 21:14 », « 16 août 21:14 ».
String _quand(DateTime at, DateTime now) {
  final heure = '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  final jours = DateTime(now.year, now.month, now.day)
      .difference(DateTime(at.year, at.month, at.day))
      .inDays;

  return switch (jours) {
    0 => heure,
    1 => 'hier $heure',
    _ => '${frenchDayMonth(at)} $heure',
  };
}
