import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/legal/privacy_content.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Politique de confidentialité.
///
/// Atteignable à tout moment, y compris avant toute connexion : un texte à
/// portée juridique ne se lit pas seulement quand l'application y consent.
///
/// Accepter depuis cet écran coche le consentement de l'écran de connexion :
/// obliger à relire puis à cocher soi-même serait redondant.
class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(PrivacyContent.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/connexion'),
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    PrivacyContent.intro,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final commitment in PrivacyContent.commitments) ...[
                    _Commitment(commitment: commitment),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Text(
                    PrivacyContent.retainedLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _RetainedCard(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    PrivacyContent.legalNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Le bouton reste visible : le texte est long, et l'acceptation ne
            // doit pas dépendre du fait d'avoir atteint le bas de la page.
            _AcceptBar(
              onAccept: () {
                ref
                    .read(authFlowViewModelProvider.notifier)
                    .setPrivacyAccepted(true);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/connexion');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Un engagement, marqué d'un filet vertical à la couleur d'identité.
class _Commitment extends StatelessWidget {
  const _Commitment({required this.commitment});

  final PrivacyCommitment commitment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 3,
          margin: const EdgeInsets.only(right: AppSpacing.lg),
          color: theme.colorScheme.primary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(commitment.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                commitment.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RetainedCard extends StatelessWidget {
  const _RetainedCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in PrivacyContent.retained)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 7,
                      right: AppSpacing.md,
                    ),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.colors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AcceptBar extends StatelessWidget {
  const _AcceptBar({required this.onAccept});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: FilledButton(
        // Orange, comme sur la maquette. Voir la note de charte : si l'orange
        // devient la couleur d'action de toute l'application, il vaudra mieux
        // permuter `primary` et `secondary` que d'habiller chaque bouton.
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          minimumSize: const Size(0, 56),
        ),
        onPressed: onAccept,
        child: const Text(PrivacyContent.accept),
      ),
    );
  }
}
