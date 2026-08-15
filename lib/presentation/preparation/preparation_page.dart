import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/presentation/preparation/preparation_view_model.dart';
import 'package:urim/presentation/preparation/widgets/block_views.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Une préparation et son fil.
class PreparationPage extends ConsumerWidget {
  const PreparationPage({super.key, required this.preparationId});

  final String preparationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preparation = ref.watch(preparationProvider(preparationId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: 'Retour',
        ),
        title: Text(
          preparation.value?.title ?? '',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            // Renommer, exporter, supprimer : rien de tout cela n'existe
            // encore.
            onPressed: null,
            tooltip: 'Options',
          ),
        ],
      ),
      body: SafeArea(
        // Répondre en touchant un choix ou en écrivant, c'est la même chose :
        // les deux passent par le même ajout au fil.
        child: ChoiceAnswer(
          onAnswer: (label) => ref
              .read(preparationComposerProvider.notifier)
              .append(preparationId: preparationId, text: label),
          child: Column(
            children: [
              Expanded(
                child: switch (preparation) {
                  AsyncData(:final value) => _Thread(preparation: value),
                  AsyncError(:final error) => _ThreadError(error: error),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
              _Composer(preparationId: preparationId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({required this.preparation});

  final Preparation preparation;

  @override
  Widget build(BuildContext context) {
    if (preparation.blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'Pose ta première idée en bas de l\'écran.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      itemCount: preparation.blocks.length,
      itemBuilder: (context, index) => BlockView(
        block: preparation.blocks[index],
        isLive: index == preparation.blocks.length - 1,
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message =
        error is Failure ? (error as Failure).message : 'Chargement impossible.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }
}

/// Barre de saisie : écrire, dicter, envoyer.
class _Composer extends ConsumerStatefulWidget {
  const _Composer({required this.preparationId});

  final String preparationId;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final failure = await ref.read(preparationComposerProvider.notifier).append(
          preparationId: widget.preparationId,
          text: _controller.text,
        );

    if (!mounted) return;

    if (failure == null) {
      _controller.clear();
      setState(() => _hasText = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBusy = ref.watch(preparationComposerProvider).isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              onChanged: (value) =>
                  setState(() => _hasText = value.trim().isNotEmpty),
              decoration: const InputDecoration(
                hintText: 'Écris ta réponse, ou choisis…',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.mic_none),
            // La dictée suppose un moteur de reconnaissance vocale — question
            // Q2, non tranchée. Le bouton reste visible pour ne pas laisser
            // croire que la saisie vocale a été oubliée.
            onPressed: null,
            tooltip: 'Dictée — bientôt disponible',
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            onPressed: _hasText && !isBusy ? _send : null,
            icon: isBusy
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.arrow_upward),
            tooltip: 'Ajouter au fil',
          ),
        ],
      ),
    );
  }
}
