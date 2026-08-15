import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/onboarding/onboarding_content.dart';
import 'package:urim/presentation/onboarding/onboarding_view_model.dart';
import 'package:urim/presentation/onboarding/widgets/page_indicator.dart';
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

  Future<void> _finish() async {
    final failure = await ref.read(onboardingViewModelProvider.notifier).complete();

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
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: OnboardingContent.steps.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) =>
                    _StepView(step: OnboardingContent.steps[index]),
              ),
            ),
            PageIndicator(
              count: OnboardingContent.steps.length,
              currentIndex: _index,
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
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
            ),
            SizedBox(
              height: 56,
              child: Center(
                child: _SecondaryAction(
                  index: _index,
                  isBusy: isBusy,
                  onSkip: _finish,
                  onPrevious: () => _goTo(_index - 1),
                  onSignIn: _finish,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Action secondaire, différente à chaque étape : passer, revenir, se
/// connecter.
class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.index,
    required this.isBusy,
    required this.onSkip,
    required this.onPrevious,
    required this.onSignIn,
  });

  final int index;
  final bool isBusy;
  final VoidCallback onSkip;
  final VoidCallback onPrevious;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      return TextButton(
        onPressed: isBusy ? null : onSkip,
        child: const Text(OnboardingContent.skip),
      );
    }

    if (index < OnboardingContent.steps.length - 1) {
      return TextButton(
        onPressed: isBusy ? null : onPrevious,
        child: const Text(OnboardingContent.previous),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          OnboardingContent.alreadyRegistered,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
        ),
        // Le module d'authentification n'existe pas encore : ce lien mène au
        // meme endroit que le bouton principal. Il pointera vers /connexion
        // des que ce module sera ouvert.
        TextButton(
          onPressed: isBusy ? null : onSignIn,
          child: const Text(OnboardingContent.signIn),
        ),
      ],
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(flex: 3),
          switch (step.mark) {
            OnboardingMark.monogram =>
              BrandMonogram(color: scheme.primary, size: 110),
            OnboardingMark.wordmark =>
              BrandWordmark(color: scheme.primary),
          },
          const Spacer(flex: 4),
          Text(
            step.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
