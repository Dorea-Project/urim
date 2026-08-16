// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_text.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppTextFr extends AppText {
  AppTextFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Urim';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Continuer';

  @override
  String get onboardingCreateAccount => 'Créer mon compte';

  @override
  String get onboardingSignIn => 'J\'ai déjà un compte';

  @override
  String get onboardingSaveFailed =>
      'Impossible d\'enregistrer ta progression. La présentation réapparaîtra au prochain lancement.';

  @override
  String onboardingStep(int position, int total) {
    return 'Étape $position sur $total';
  }

  @override
  String get onboardingWeighingTitle =>
      'Écris ta phrase.\nUrim cherche le texte dedans.';

  @override
  String get onboardingWeighingBody =>
      'Une référence, une citation approximative, ou juste une intention. Tu n\'as aucun mode à choisir — la porte regarde si les mots se suivent comme dans l\'Écriture.';

  @override
  String get onboardingHandbackTitle => 'Il s\'arrête\net te rend la main.';

  @override
  String get onboardingHandbackBody =>
      'Chaque étage dit pourquoi il a fait ce qu\'il a fait. Quand il ne peut pas trancher seul, il te pose la question au lieu de choisir à ta place.';

  @override
  String get onboardingResistanceTitle =>
      'Il te montre les textes qui te résistent.';

  @override
  String get onboardingResistanceBody =>
      'Ceux qui ne vont pas dans le sens de ta lecture. C\'est le seul moyen de ne pas faire dire au texte ce qu\'on avait décidé d\'y trouver.';

  @override
  String get back => 'Retour';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';
}
