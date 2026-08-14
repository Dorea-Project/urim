import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/presentation/home/home_page.dart';

/// Table de routage de l'application.
///
/// Déclarée comme provider pour pouvoir dépendre de l'état de session : une
/// fois l'authentification en place, `redirect` lira le provider concerné pour
/// rediriger vers l'écran de connexion.
final goRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);

  return GoRouter(
    initialLocation: AppRoutes.homePath,
    debugLogDiagnostics: config.enableVerboseLogging,
    routes: [
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) => const HomePage(),
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorPage(error: state.error),
  );
});

/// Écran de repli pour une route inconnue ou en échec.
class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error?.toString() ?? 'Cette page n\'existe pas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.goNamed(AppRoutes.homeName),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
