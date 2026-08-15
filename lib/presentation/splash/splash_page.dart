import 'package:flutter/material.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Écran de lancement.
///
/// Affiché le temps de lire l'état de la présentation dans les préférences —
/// quelques millisecondes en pratique. Ce n'est pas une attente artificielle :
/// dès que la redirection sait où aller, il s'efface, quitte à interrompre son
/// animation. C'est voulu : l'animation habille l'attente, elle ne la crée pas.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _markFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  late final Animation<double> _markScale = Tween<double>(
    begin: 0.86,
    end: 1,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<double> _footerFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 1, curve: Curves.easeOut),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            FadeTransition(
              opacity: _markFade,
              child: ScaleTransition(
                scale: _markScale,
                child: BrandMonogram(color: scheme.onPrimary),
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: _footerFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Text(
                  'Propulsé par Dorea',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.75),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
