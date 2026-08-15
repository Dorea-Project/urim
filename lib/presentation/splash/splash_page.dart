import 'package:flutter/material.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Écran de lancement.
///
/// Affiché le temps de lire l'état de la présentation dans les préférences —
/// quelques millisecondes en pratique. Ce n'est pas une attente artificielle :
/// dès que la redirection du routeur sait où aller, il s'efface.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            BrandMonogram(color: scheme.onPrimary),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Text(
                'Propulsé par Dorea',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.75),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
