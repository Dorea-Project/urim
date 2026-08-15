import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/auth/otp_page.dart';
import 'package:urim/presentation/auth/phone_page.dart';
import 'package:urim/presentation/auth/secret_code_page.dart';
import 'package:urim/presentation/home/home_page.dart';
import 'package:urim/presentation/onboarding/onboarding_page.dart';
import 'package:urim/presentation/onboarding/onboarding_view_model.dart';
import 'package:urim/presentation/splash/splash_page.dart';

/// Table de routage de l'application.
///
/// La redirection est le seul endroit qui décide de l'écran de départ. Les
/// écrans ne naviguent pas eux-mêmes : ils modifient l'état, la redirection en
/// tire les conséquences. Le jour où l'authentification arrive, sa garde
/// s'ajoute ici et nulle part ailleurs.
final goRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);

  // GoRouter n'observe pas les providers : il faut lui signaler qu'une
  // réévaluation s'impose. Sans ce pont, marquer la présentation comme vue ne
  // déclencherait aucune redirection.
  final refreshSignal = ValueNotifier<int>(0);
  ref.onDispose(refreshSignal.dispose);
  ref.listen(onboardingCompletedProvider, (_, _) => refreshSignal.value++);
  ref.listen(authGateProvider, (_, _) => refreshSignal.value++);

  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: config.enableVerboseLogging,
    refreshListenable: refreshSignal,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // --- 1. Présentation ---------------------------------------------------

      final onboarding = ref.read(onboardingCompletedProvider);
      if (onboarding.isLoading) {
        return location == AppRoutes.splashPath ? null : AppRoutes.splashPath;
      }

      // Une lecture en échec vaut « jamais vue » : mieux vaut une présentation
      // en trop qu'un démarrage bloqué.
      if (!(onboarding.value ?? false)) {
        return location == AppRoutes.onboardingPath
            ? null
            : AppRoutes.onboardingPath;
      }

      // --- 2. Accès ----------------------------------------------------------

      final gate = ref.read(authGateProvider);
      if (gate.isLoading) {
        return location == AppRoutes.splashPath ? null : AppRoutes.splashPath;
      }

      // En cas d'échec de lecture, on retombe sur la connexion : le pire
      // scénario est de redemander un SMS, jamais d'ouvrir l'accès.
      return switch (gate.value ?? AuthGate.signedOut) {
        // Le parcours compte deux écrans : les deux restent atteignables.
        AuthGate.signedOut =>
          location == AppRoutes.signInPath || location == AppRoutes.otpPath
              ? null
              : AppRoutes.signInPath,

        AuthGate.needsSecretCode => location == AppRoutes.secretCodeSetupPath
            ? null
            : AppRoutes.secretCodeSetupPath,

        AuthGate.locked => location == AppRoutes.secretCodePath
            ? null
            : AppRoutes.secretCodePath,

        // Accès ouvert : plus aucune route d'entrée n'est atteignable.
        AuthGate.ready =>
          AppRoutes.entryPaths.contains(location) ? AppRoutes.homePath : null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboardingName,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.signInPath,
        name: AppRoutes.signInName,
        builder: (context, state) => const PhonePage(),
      ),
      GoRoute(
        path: AppRoutes.otpPath,
        name: AppRoutes.otpName,
        builder: (context, state) => const OtpPage(),
      ),
      GoRoute(
        path: AppRoutes.secretCodeSetupPath,
        name: AppRoutes.secretCodeSetupName,
        builder: (context, state) => const SecretCodeSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.secretCodePath,
        name: AppRoutes.secretCodeName,
        builder: (context, state) => const SecretCodeUnlockPage(),
      ),
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
