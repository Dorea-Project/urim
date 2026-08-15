import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/onboarding/onboarding_content.dart';
import 'package:urim/presentation/onboarding/onboarding_view_model.dart';
import 'package:urim/presentation/onboarding/widgets/page_indicator.dart';
import 'package:urim/presentation/onboarding/widgets/step_illustration.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Présentation en trois étapes, montrée au premier lancement.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  static const Duration _transition = Duration(milliseconds: 280);
  static const Curve _curve = Curves.easeInOut;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastStep => _index == OnboardingContent.steps.length - 1;

  void _goTo(int index) => _controller.animateToPage(
        index,
        duration: _transition,
        curve: _curve,
      );

  /// Termine la présentation, en retenant par quelle porte on entre.
  ///
  /// Le serveur ne dira jamais si un numéro est connu — ce serait un annuaire
  /// des inscrits. C'est donc ici, et seulement ici, que le choix se fait.
  Future<void> _finish({AuthDoor door = AuthDoor.registration}) async {
    ref.read(authFlowViewModelProvider.notifier).setDoor(door);

    final failure =
        await ref.read(onboardingViewModelProvider.notifier).complete();

    // La redirection du routeur prend le relais dès que la présentation est
    // marquée comme vue ; l'écran n'a pas à naviguer lui-même.
    if (failure != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(OnboardingContent.saveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(onboardingViewModelProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // « Passer » reste au même endroit sur les trois étapes : une
            // sortie qu'on cherche du regard une seule fois.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: TextButton(
                  onPressed: isBusy ? null : _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.textSecondary,
                  ),
                  child: const Text(OnboardingContent.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: OnboardingContent.steps.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) =>
                    _StepView(step: OnboardingContent.steps[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PageIndicator(
                  count: OnboardingContent.steps.length,
                  currentIndex: _index,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                onPressed: isBusy
                    ? null
                    : () => _isLastStep ? _finish() : _goTo(_index + 1),
                child: Text(
                  _isLastStep
                      ? OnboardingContent.enter
                      : OnboardingContent.next,
                ),
              ),
            ),
            // Deux portes, deux parcours : créer un compte commence par un
            // SMS, se connecter commence par le code secret (Q13).
            TextButton(
              onPressed:
                  isBusy ? null : () => _finish(door: AuthDoor.signIn),
              child: const Text(OnboardingContent.signIn),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Le motif cède la place au texte quand l'écran est court, et l'étape
    // défile plutôt que de déborder : trois lignes de titre suffisent à faire
    // sortir la mise en page d'un petit téléphone.
    return LayoutBuilder(
      builder: (context, constraints) {
        final motif = (constraints.maxHeight * 0.34).clamp(120.0, 220.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le motif est reconstruit à chaque étape : c'est ce qui
                // relance son animation quand la page change.
                Align(child: StepIllustration(step: step, size: motif)),
                const SizedBox(height: AppSpacing.xxxl),
                _MessageEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          height: 1.22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        step.body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Entrée du texte : fondu et remontée, légèrement après le motif.
///
/// Le décalage n'est pas décoratif — il conduit le regard du dessin vers le
/// texte, dans l'ordre où ils doivent être lus.
class _MessageEntrance extends StatelessWidget {
  const _MessageEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final immediate = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: immediate ? 1 : 0, end: 1),
      duration: immediate ? Duration.zero : const Duration(milliseconds: 620),
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
