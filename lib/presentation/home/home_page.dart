import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';

/// Écran d'accueil — **placeholder posé par la piste 2**.
///
/// PISTE 1 : cet écran n'a pas vocation à survivre. Il existe uniquement pour
/// que l'application démarre et que le routage soit vérifiable. Remplacez-le
/// entièrement ; conservez seulement le nom de la classe, référencé par
/// `core/router/app_router.dart`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Urim')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Socle architectural en place',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Environnement : ${config.flavor.name}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
