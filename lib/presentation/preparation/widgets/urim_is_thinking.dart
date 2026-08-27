import 'package:flutter/material.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// La bulle d'attente — **le moteur travaille, et l'écran le dit**.
///
/// Ce qu'elle remplace : rien. Entre la parole du pasteur et la réponse, il n'y
/// avait aucun signe. Sur un téléphone, une seconde de silence se lit comme une
/// panne, et le pasteur touche une seconde fois.
///
/// ⚠️ **Elle ne dit pas « Urim écrit ».** Il ne rédige pas : il cherche dans le
/// corpus, borne, pèse. Écrire un mot faux ici serait promettre à la porte
/// exactement ce que le produit refuse de faire.
///
/// Trois points, décalés d'un tiers de cycle. Le mouvement est le message —
/// c'est pourquoi il porte aussi un libellé pour les lecteurs d'écran, qui ne
/// voient pas les points bouger.
class UrimIsThinking extends StatefulWidget {
  const UrimIsThinking({super.key});

  @override
  State<UrimIsThinking> createState() => _UrimIsThinkingState();
}

class _UrimIsThinkingState extends State<UrimIsThinking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      liveRegion: true,
      label: AppText.of(context).preparationThinking,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceWarm,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: AnimatedBuilder(
            animation: _cycle,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var rang = 0; rang < 3; rang++) ...[
                  if (rang > 0) const SizedBox(width: AppSpacing.xs),
                  Opacity(
                    // Chaque point est en retard d'un tiers de cycle sur le
                    // précédent : c'est ce décalage qui fait la vague.
                    opacity: _opacite((_cycle.value + rang / 3) % 1),
                    child: _Point(color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Une vague qui monte et redescend, jamais éteinte tout à fait : un point
  /// qui disparaît se lit comme un point manquant.
  double _opacite(double phase) => 0.3 + 0.7 * (1 - (phase * 2 - 1).abs());
}

class _Point extends StatelessWidget {
  const _Point({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
