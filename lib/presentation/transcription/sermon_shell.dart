import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';
import 'package:urim/presentation/transcription/transcription_page.dart';
import 'package:urim/presentation/transcription/transcription_view_model.dart';

/// **La coque à trois onglets** — A3, la charpente qui manquait.
///
/// Ce qui a été dit · La synthèse · La sortie. Une prédication, trois moments,
/// et ils ne s'ouvrent pas ensemble.
///
/// ---
///
/// ## 🔴 Ce qui n'est pas encore ouvert dit quoi et pourquoi (D13)
///
/// C'est toute la raison d'être de cette coque, et la raison pour laquelle elle
/// se construit **avant** que les routes existent.
///
/// - **Ce qui a été dit** attend le modèle embarqué (D52), qui attend son banc
///   d'essai. L'onglet existe, il est vide, et il nomme ce qu'il attend.
/// - **La sortie** attend une signature. L'onglet existe, il est fermé, et il
///   dit *rien n'est lu à voix haute avant validation* — la promesse écrite sur
///   l'onglet d'à côté.
///
/// Un onglet absent ne se distingue pas d'un oubli. Un onglet grisé qui explique
/// se distingue d'une panne.
///
/// ## Pourquoi trois, et pas une page qui déroule
///
/// Les trois portent des gestes différents et des **moments** différents : on
/// relit, puis on signe, puis on choisit comment ça sort. Les empiler dans une
/// seule page ferait défiler le pasteur à travers ce qu'il a déjà fait pour
/// atteindre ce qu'il vient faire — c'est exactement le défaut que D42 a corrigé
/// ailleurs, onze écrans devenus trois.
class SermonShell extends ConsumerWidget {
  const SermonShell({
    super.key,
    required this.preparationId,
    this.initialTab = 1,
  });

  final String preparationId;

  /// L'onglet ouvert à l'arrivée. **La synthèse par défaut** : c'est le seul
  /// des trois qui ait quelque chose à montrer aujourd'hui (D59).
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final review = ref.watch(transcriptionReviewProvider(preparationId));

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            review.value?.title ?? text.transcriptionFallbackTitle,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            tooltip: text.back,
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: text.sermonTabSaid),
              Tab(text: text.sermonTabSynthesis),
              Tab(text: text.sermonTabOutput),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              switch (review) {
                AsyncData(:final value) => ReviewSection(
                    review: value,
                    preparationId: preparationId,
                  ),
                AsyncError() => const ReviewMissing(),
                _ => const Center(child: CircularProgressIndicator()),
              },
              // ⛔ **Éteint le 06/09** (D72). Ces deux onglets servaient la
              // synthèse née de la **préparation** — péricope, axe, plan écrit.
              // Elle résumait une intention, pas un sermon : lue à une
              // assemblée ou interprétée en malinké, elle aurait présenté un
              // projet comme la parole prononcée.
              //
              // 🔴 **Ils ne disparaissent pas, ils disent pourquoi** (D13). Un
              // onglet absent ne se distingue pas d'un oubli ; un onglet fermé
              // qui explique se distingue d'une panne — et c'est d'autant plus
              // vrai ici que le pasteur les a vus fonctionner hier.
              //
              // ⚠️ `SynthesisSection` et `OutputSection` restent dans l'arbre,
              // volontairement. Elles montrent une synthèse, la font signer, la
              // lisent à voix haute et enregistrent la voix du pasteur — tout
              // cela vaudra pour la synthèse d'une **pièce**, qui naîtra du
              // transcript. Les détruire serait les réécrire.
              _Attend(motif: text.synthesisFromPlanGone),
              _Attend(motif: text.outputWaitsSynthesis),
            ],
          ),
        ),
      ),
    );
  }

}

/// Un onglet qui n'a rien — **et qui dit quoi**.
class _Attend extends StatelessWidget {
  const _Attend({required this.motif});

  final String motif;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          motif,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
        ),
      ),
    );
  }
}
