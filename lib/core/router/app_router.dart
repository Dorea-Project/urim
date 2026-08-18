import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/auth/auth_gate.dart';
import 'package:urim/presentation/auth/otp_page.dart';
import 'package:urim/presentation/auth/phone_page.dart';
import 'package:urim/presentation/auth/secret_code_page.dart';
import 'package:urim/presentation/auth/sign_in_secret_code_page.dart';
import 'package:urim/presentation/home/home_page.dart';
import 'package:urim/presentation/legal/privacy_policy_page.dart';
import 'package:urim/presentation/onboarding/onboarding_page.dart';
import 'package:urim/presentation/onboarding/onboarding_view_model.dart';
import 'package:urim/presentation/preparation/new_preparation_page.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import 'package:urim/presentation/profile/profile_page.dart';
import 'package:urim/presentation/settings/settings_page.dart';
import 'package:urim/presentation/splash/splash_page.dart';
import 'package:urim/presentation/transcription/synthesis_page.dart';
import 'package:urim/presentation/transcription/transcription_page.dart';

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

      // --- 0. Mentions légales ------------------------------------------------

      // Jamais redirigée : la politique de confidentialité doit pouvoir être
      // lue à n'importe quel moment du parcours, y compris avant d'avoir
      // consenti à quoi que ce soit.
      if (location == AppRoutes.privacyPath) return null;

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
        // Deux portes, quatre écrans : numéro, code SMS, code secret de
        // connexion, création du code secret. Tous restent atteignables tant
        // que la session n'est pas ouverte.
        AuthGate.signedOut => AppRoutes.signedOutPaths.contains(location)
            ? null
            : AppRoutes.signInPath,

        AuthGate.needsSecretCode => location == AppRoutes.secretCodeSetupPath
            ? null
            : AppRoutes.secretCodeSetupPath,

        AuthGate.locked => location == AppRoutes.secretCodePath
            ? null
            : AppRoutes.secretCodePath,

        // Accès ouvert : plus aucune route d'entrée n'est atteignable — sauf
        // les deux écrans du changement de code secret, et seulement tant que
        // cette porte-là est ouverte. Sans cette exception, changer son code
        // depuis le profil renverrait aussitôt à l'accueil.
        AuthGate.ready => _isChangingSecretCode(ref) &&
                AppRoutes.secretCodeChangePaths.contains(location)
            ? null
            : (AppRoutes.entryPaths.contains(location)
                ? AppRoutes.homePath
                : null),
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
        path: AppRoutes.signInSecretCodePath,
        name: AppRoutes.signInSecretCodeName,
        builder: (context, state) => const SignInSecretCodePage(),
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
        path: AppRoutes.privacyPath,
        name: AppRoutes.privacyName,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.newPreparationPath,
        name: AppRoutes.newPreparationName,
        builder: (context, state) => const NewPreparationPage(),
      ),
      GoRoute(
        path: AppRoutes.preparationPath,
        name: AppRoutes.preparationName,
        builder: (context, state) => PreparationPage(
          preparationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.transcriptionPath,
        name: AppRoutes.transcriptionName,
        builder: (context, state) => TranscriptionPage(
          preparationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.synthesisPath,
        name: AppRoutes.synthesisName,
        builder: (context, state) => SynthesisPage(
          preparationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.profilePath,
        name: AppRoutes.profileName,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.settingsPath,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorPage(error: state.error),
  );
});

/// La porte du changement de code secret est-elle ouverte ?
///
/// Lue sans écouter : la redirection est déjà réévaluée à chaque navigation et
/// à chaque changement de la porte d'accès. S'abonner ici ferait recalculer le
/// routeur à chaque frappe dans le formulaire.
bool _isChangingSecretCode(Ref ref) =>
    ref.read(authFlowViewModelProvider).door == AuthDoor.secretCodeReset;

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
