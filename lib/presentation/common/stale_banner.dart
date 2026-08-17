import 'package:flutter/material.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/common/french_dates.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Les mentions de **provenance** : d'où vient ce qui est à l'écran.
///
/// ⚠️ **Où passe la frontière de D29.** Le client n'écrit jamais une phrase de
/// sa propre autorité — mais ces phrases-ci ne parlent ni de l'Écriture ni du
/// raisonnement d'Urim : elles parlent de **l'application elle-même**, de ce
/// qu'elle a gardé et de quand. Personne d'autre ne peut les dire, puisque le
/// serveur ne sait pas ce que l'appareil détient. La règle reste entière : ce
/// qui vient du moteur traverse intact, et l'application ne commente que son
/// propre état.

/// Dit que ce qui est à l'écran vient de l'appareil, et depuis quand.
///
/// Le moteur rejoue son pipeline à chaque lecture (D28) : ce qui a été gardé
/// hier soir est ce qu'il *disait* hier soir, pas ce qu'il dirait maintenant. Un
/// pasteur qui décide sur un tour qu'il croit frais alors qu'il a une semaine
/// agit sur une réponse périmée — et il ne l'apprendrait qu'au refus du serveur.
///
/// Discret exprès : c'est une provenance, pas une alerte. Rien n'est cassé.
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.receivedAt, this.now});

  final DateTime receivedAt;

  /// Injectable pour les tests, qui ne peuvent pas dépendre de l'heure réelle.
  final DateTime? now;

  @override
  Widget build(BuildContext context) => _Notice(
        icon: Icons.cloud_off_outlined,
        text: AppText.of(context).servedFromDevice(
          _quand(receivedAt, now ?? DateTime.now()),
        ),
      );
}

/// Dit que le corpus a été relu depuis l'ouverture de la préparation.
///
/// Le serveur le signale par `corpus_drifted` et ne l'a jamais commenté ;
/// l'application l'ignorait. Ce que ça change est réel : le moteur rejoue
/// contre un corpus qui a bougé — des unités ont pu être relues, des pesées
/// ajoutées. Le tour n'est pas faux ; il n'est plus **mot pour mot** celui que
/// le pasteur avait sous les yeux.
///
/// Ça se dit une fois, sobrement, et ça n'empêche rien : le travail continue.
class DriftNotice extends StatelessWidget {
  const DriftNotice({super.key});

  @override
  Widget build(BuildContext context) => _Notice(
        icon: Icons.autorenew,
        text: AppText.of(context).corpusDrifted,
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
          Icon(icon, size: 15, color: context.colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
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

/// « 21:14 », « hier 21:14 », « 16 août 21:14 ».
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
