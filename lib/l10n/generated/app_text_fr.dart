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
  String get profileDeleteAccount => 'Supprimer mon compte';

  @override
  String get profileDeleteAccountTitle => 'Supprimer votre compte ?';

  @override
  String get profileDeleteAccountBody =>
      'Vos préparations, vos enregistrements et votre compte seront effacés — sur cet appareil comme sur le serveur. Rien n\'est récupérable.\n\nUn code va partir par SMS : il faut le saisir pour confirmer.';

  @override
  String get profileDeleteAccountConfirm => 'Recevoir le code';

  @override
  String get profileDeleteAccountDone =>
      'Votre compte et son contenu ont été supprimés.';

  @override
  String get profileDeleteAccountFailed =>
      'Le code n\'est pas parti. Votre compte est intact.';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String get profileSignOutTitle => 'Fermer la session ?';

  @override
  String get profileSignOutBody =>
      'Vos préparations restent sur cet appareil. Il faudra votre code secret, ou un nouveau code par SMS si l\'appareil n\'est plus reconnu.';

  @override
  String get profileSignOutEverywhere => 'Sur tous mes appareils';

  @override
  String get profileSignOutConfirm => 'Se déconnecter';

  @override
  String get profileSignOutFailed =>
      'La session est fermée ici, mais le serveur n\'a pas répondu.';

  @override
  String get splashPoweredBy => 'Propulsé par Dorea';

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
      'Impossible d\'enregistrer votre progression. La présentation réapparaîtra au prochain lancement.';

  @override
  String onboardingStep(int position, int total) {
    return 'Étape $position sur $total';
  }

  @override
  String get onboardingWeighingTitle =>
      'Écrivez votre phrase.\nUrim cherche le texte dedans.';

  @override
  String get onboardingWeighingBody =>
      'Une référence, une citation approximative, ou juste une intention. Vous n\'avez aucun mode à choisir — la porte regarde si les mots se suivent comme dans l\'Écriture.';

  @override
  String get onboardingHandbackTitle => 'Il s\'arrête\net te rend la main.';

  @override
  String get onboardingHandbackBody =>
      'Chaque étage dit pourquoi il a fait ce qu\'il a fait. Quand il ne peut pas trancher seul, il vous pose la question au lieu de choisir à votre place.';

  @override
  String get onboardingResistanceTitle =>
      'Il te montre les textes qui te résistent.';

  @override
  String get onboardingResistanceBody =>
      'Ceux qui ne vont pas dans le sens de votre lecture. C\'est le seul moyen de ne pas faire dire au texte ce qu\'on avait décidé d\'y trouver.';

  @override
  String get back => 'Retour';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get authPhoneTitleSignIn => 'Votre numéro';

  @override
  String get authPhoneTitleRegistration => 'Votre numéro valide';

  @override
  String get authPhoneHint => '07 47 76 9069';

  @override
  String get authSwitchToSignIn => 'Déjà un compte ? Se connecter';

  @override
  String get authSwitchToRegistration => 'Pas encore de compte ? En créer un';

  @override
  String get authGoToSignIn => 'Se connecter';

  @override
  String get authPhoneSubmit => 'Soumettre';

  @override
  String get authPrivacyConsent => 'J\'ai lu et j\'accepte la ';

  @override
  String get authPrivacyLink => 'politique de confidentialité';

  @override
  String authOtpTitle(int count) {
    return 'Utiliser code SMS de $count chiffres';
  }

  @override
  String get authOtpValidate => 'Validation';

  @override
  String get authOtpResend => 'Renvoyer le code';

  @override
  String get authOtpRequestNew => 'Demander un nouveau code';

  @override
  String get authOtpExpiredShort => 'Code expiré';

  @override
  String authOtpRemainingMinutes(int minutes, String seconds) {
    return 'il reste $minutes min $seconds';
  }

  @override
  String authOtpRemainingSeconds(int seconds) {
    return 'il reste $seconds s';
  }

  @override
  String get secretCodeChooseTitle => 'Choisissez un code secret';

  @override
  String get secretCodeConfirmTitle => 'Confirmez votre code secret';

  @override
  String secretCodeChooseHelper(int count) {
    return '$count chiffres, demandés à chaque ouverture';
  }

  @override
  String get secretCodeConfirmHelper => 'Saisissez-le une seconde fois';

  @override
  String get secretCodeUnlockTitle => 'Votre code secret';

  @override
  String get secretCodeUnlockHelper => 'Saisissez vos chiffres';

  @override
  String get secretCodeWrong => 'Code incorrect';

  @override
  String get signInForgotten => 'Code oublié ?';

  @override
  String get errorOtpExpired => 'Ce code a expiré. Demandes-en un nouveau.';

  @override
  String get errorOtpInvalid => 'Code incorrect.';

  @override
  String get errorOtpTooManyAttempts =>
      'Trop d\'essais sur ce code. Demandes-en un nouveau.';

  @override
  String get errorOtpTooManyRequests =>
      'Trop de codes demandés. Patiente quelques minutes.';

  @override
  String get errorPhoneAlreadyRegistered =>
      'Ce numéro a déjà un compte. Connectez-vous.';

  @override
  String get errorSecretCodeIncorrect => 'Code secret incorrect.';

  @override
  String get errorTooManyAttempts =>
      'Trop d\'essais. Attends quelques minutes avant de réessayer.';

  @override
  String get errorAccountInactive => 'Ce compte est désactivé.';

  @override
  String get errorNoConnection => 'Pas de connexion.';

  @override
  String get errorVerificationUnavailable =>
      'Vérification impossible pour l\'instant.';

  @override
  String get errorSignInUnavailable => 'Connexion impossible pour l\'instant.';

  @override
  String get demoPhone =>
      'Serveur simulé : aucun SMS ne part. Le numéro est prérempli, coche la politique et soumets.';

  @override
  String demoOtp(String code) {
    return 'Serveur simulé : le code est $code.';
  }

  @override
  String demoSecretCodeSetup(String code) {
    return 'Pour l\'essai : $code. Un code répété (0000) ou suivi (1234) est refusé.';
  }

  @override
  String demoSecretCodeUnlock(String code) {
    return 'Celui que vous avez choisi à la création — $code si vous avez suivi la suggestion.';
  }

  @override
  String demoSignIn(String code) {
    return 'Serveur simulé : le code est celui que vous avez posé à l\'inscription — $code si vous avez suivi la suggestion.';
  }

  @override
  String get privacyTitle => 'Vos données';

  @override
  String get privacyIntro =>
      'Trois choses qu\'Urim ne fera jamais. Elles sont tenues par le code, pas par une promesse.';

  @override
  String get privacyNoProfilingTitle => 'Aucune analyse de personne';

  @override
  String get privacyNoProfilingBody =>
      'Urim traite des textes. Il ne produit aucun jugement, score ou profil sur un membre, un fidèle ou un collaborateur.';

  @override
  String get privacyOwnershipTitle => 'Vos préparations restent les vôtres';

  @override
  String get privacyOwnershipBody =>
      'Elles ne sont lues par personne d\'autre — ni par votre église, ni par Dorea, ni par un responsable.';

  @override
  String get privacyNoResaleTitle => 'Rien n\'est revendu';

  @override
  String get privacyNoResaleBody =>
      'Aucune publicité, aucun entraînement de modèle sur votre contenu. Les traitements techniques passent par des prestataires qui agissent pour Dorea, jamais pour leur propre compte.';

  @override
  String get privacyRetainedLabel => 'CE QUI EST CONSERVÉ';

  @override
  String get privacyRetainedPhone =>
      'Votre numéro de téléphone, pour vous reconnaître.';

  @override
  String get privacyRetainedWork =>
      'Vos préparations et enregistrements, jusqu\'à ce que vous les supprimiez.';

  @override
  String get privacyRetainedDevices =>
      'Les appareils sur lesquels vous vous êtes connecté.';

  @override
  String get privacyLegalNotice =>
      'Traitement soumis à la loi ivoirienne n° 2013-450 relative à la protection des données à caractère personnel. Vous pouvez supprimer votre compte et tout son contenu à tout moment.';

  @override
  String get privacyAccept => 'J\'ai lu et j\'accepte';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSectionReading => 'Lecture';

  @override
  String get settingsSectionScripture => 'Écriture';

  @override
  String get settingsSectionOffline => 'Hors connexion';

  @override
  String get settingsSectionReminders => 'Rappels';

  @override
  String get settingsSectionContent => 'Contenu';

  @override
  String get settingsTextSize => 'Taille du texte';

  @override
  String get settingsTextSizeSmall => 'Petit';

  @override
  String get settingsTextSizeNormal => 'Normal';

  @override
  String get settingsTextSizeLarge => 'Grand';

  @override
  String get settingsTextSizeExtraLarge => 'Très grand';

  @override
  String get settingsReadingSample =>
      'Ils persévéraient dans l\'enseignement des apôtres…';

  @override
  String get settingsDefaultVersion => 'Version par défaut';

  @override
  String get settingsAlwaysShowReference => 'Toujours afficher la référence';

  @override
  String get settingsAlwaysShowReferenceHint =>
      'Livre, chapitre, verset et version sous chaque citation.';

  @override
  String get settingsBibleDownloaded => 'Texte biblique téléchargé';

  @override
  String get settingsBibleDownloadedPending =>
      'Disponible quand la source du texte biblique aura été choisie.';

  @override
  String get settingsTranscribeOnDevice => 'Transcrire sur l\'appareil';

  @override
  String get settingsTranscribeOnDevicePending =>
      'L\'audio ne quittera jamais le téléphone. Le moteur de transcription reste à retenir.';

  @override
  String get settingsWifiOnly => 'Synchroniser en Wi-Fi seulement';

  @override
  String get settingsWifiOnlyPending =>
      'Rien n\'est encore synchronisé : vos préparations ne quittent pas cet appareil.';

  @override
  String get settingsReminderInProgress => 'Préparation en cours';

  @override
  String get settingsReminderInProgressPending =>
      'Un rappel le samedi si un message n\'est pas terminé — dès qu\'une préparation saura dire qu\'elle ne l\'est pas.';

  @override
  String get exportStartingPoint => 'Point de départ';

  @override
  String get exportTheme => 'Thème';

  @override
  String get exportVerses => 'Le texte';

  @override
  String get exportContext => 'Le contexte';

  @override
  String get preparationExport => 'Copier en texte';

  @override
  String get preparationExportDone =>
      'Préparation copiée. Collez-la où vous voulez.';

  @override
  String get settingsExport => 'Exporter mes préparations';

  @override
  String get settingsExportPending =>
      'Une par une, depuis le menu d\'une préparation. L\'export de tout, et le PDF, restent à faire.';

  @override
  String get settingsStorageUsed => 'Espace utilisé';

  @override
  String get settingsStorageUsedPending =>
      'Mesurable une fois le stockage des préparations choisi.';

  @override
  String get settingsTrainingNotice =>
      'Urim n\'utilise jamais vos préparations pour entraîner un modèle.';

  @override
  String get settingsSaveFailed => 'Ce réglage n\'a pas pu être enregistré.';

  @override
  String get settingsReadFailed => 'Les réglages n\'ont pas pu être lus.';

  @override
  String get translationPublicDomain => 'Domaine public';

  @override
  String get translationLicenceNotice =>
      'Les autres traductions demandent une licence : Urim ne les proposera qu\'une fois les droits obtenus.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileNoName => 'Sans nom';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileSectionChurches => 'Églises';

  @override
  String get profileSecretCodeChangeTitle => 'Changer votre code secret ?';

  @override
  String profileSecretCodeChangeBody(String phone) {
    return 'Un code vous sera envoyé par SMS au $phone. Vos autres appareils devront se reconnecter : changer la serrure laisse rarement les anciennes clés en circulation.';
  }

  @override
  String get profileSecretCodeChangeConfirm => 'Recevoir le code';

  @override
  String get profileSecretCodeChangeFailed =>
      'Le code n\'a pas pu être envoyé.';

  @override
  String get profileSectionDevices => 'Appareils';

  @override
  String profileDevicesCount(int count, int max) {
    return '$count sur $max';
  }

  @override
  String get profileDevicesFull =>
      'Deux appareils au maximum. Pour en lier un nouveau, retire d\'abord l\'un de ceux-ci — sinon la connexion y sera refusée.';

  @override
  String profileDevicesRoom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places restent pour d\'autres appareils.',
      one: 'Une place reste pour un autre appareil.',
    );
    return '$_temp0';
  }

  @override
  String get profileDisplayName => 'Nom affiché';

  @override
  String get profileDisplayNameEmpty => 'À définir';

  @override
  String get profileDisplayNameHint => 'Kouadio Aristide';

  @override
  String get profileDisplayNameExplanation =>
      'Ce nom ne sort pas de l\'application : il sert à vous reconnaître sur cet écran, et à former votre monogramme.';

  @override
  String get profileNoNameAvatar => 'Aucun nom défini';

  @override
  String get searchTitle => 'Chercher';

  @override
  String get searchPassageTab => 'Un passage';

  @override
  String get searchWordTab => 'Un mot de l’original';

  @override
  String get searchPassageHint => 'Marc 10:46-52';

  @override
  String get searchWordHint => 'εἴδωλον';

  @override
  String get searchAction => 'Chercher';

  @override
  String get searchEmpty =>
      'Rien pour l’instant. Écrivez une référence, ou un mot de l’original.';

  @override
  String get searchUnitsTitle => 'Les unités qui couvrent votre demande';

  @override
  String searchReviewedBy(String qui) {
    return 'Relu par $qui';
  }

  @override
  String get searchNotReviewed => 'Proposé par le modèle, non relu';

  @override
  String get searchBearingsTitle => 'Les dix pesées, absentes comprises';

  @override
  String get searchCaveatsTitle => 'Ce que ce texte ne dit pas';

  @override
  String get searchContextTitle => 'Le contexte';

  @override
  String get searchVariantsTitle => 'Ce que les manuscrits portent';

  @override
  String searchOccurrences(int total) {
    return '$total occurrences dans le corpus';
  }

  @override
  String searchTruncated(int montrees) {
    return 'Voici les $montrees premières — un extrait présenté comme un tout ferait conclure d’un échantillon.';
  }

  @override
  String get searchNoGloss =>
      'Le corpus ne porte pas le sens de ce mot. Voici où il paraît — c’est ce que je peux soutenir.';

  @override
  String get preparationSupportsTitle => 'Ma chaîne de textes';

  @override
  String get preparationSupportsIntro =>
      'Dans votre ordre, pas celui du canon : l’annonce avant l’accomplissement. Écrivez comme vous notez — « Hb 2v29 » se lit.';

  @override
  String get preparationSupportsAdd => 'Ajouter un texte';

  @override
  String get preparationSupportsSave => 'Vérifier et enregistrer';

  @override
  String get preparationSupportsSaved => 'Votre chaîne est enregistrée.';

  @override
  String get preparationSupportsHint => 'Hb 2v29';

  @override
  String get preparationDeckTitle => 'Ce que l’assemblée verra';

  @override
  String get preparationDeckIntro =>
      'Chaque diapositive porte une référence et le texte tel qu’il montera à l’écran. Rien ne sort tant qu’un verset projeté n’est pas celui de la Bible.';

  @override
  String get preparationDeckAdd => 'Ajouter une diapositive';

  @override
  String get preparationDeckSubmit => 'Soumettre au contrôle';

  @override
  String get preparationDeckRemove => 'Retirer cette diapositive';

  @override
  String get preparationDeckReference => 'Référence';

  @override
  String get preparationDeckProjected => 'Texte projeté';

  @override
  String preparationDeckSlide(int rang) {
    return 'Diapositive $rang';
  }

  @override
  String get preparationDocumentWorking => 'Je prépare le document…';

  @override
  String preparationDocumentReady(String dossier) {
    return 'Votre document est dans « $dossier ».';
  }

  @override
  String get preparationDocumentRefusedTitle =>
      'Une citation ne correspond pas au corpus';

  @override
  String get preparationDocumentRefusedBody =>
      'Le document n’est pas produit tant qu’un verset projeté n’est pas celui de la Bible. Corrige, puis redemande.';

  @override
  String get preparationPlanTitle => 'Mes points';

  @override
  String get preparationPlanIntro =>
      'Le document met en page ce que vous écrivez. Rien n’est imposé : une section vide reste vide.';

  @override
  String get preparationPlanSave => 'Enregistrer';

  @override
  String get preparationPlanSaved => 'Votre plan est enregistré.';

  @override
  String get preparationPlanAdd => 'Ajouter une section';

  @override
  String get preparationPlanPointsHint =>
      'Au moins un point : c’est ce que le document exige avant de sortir.';

  @override
  String get preparationMaterialTitle => 'Le texte et le contexte';

  @override
  String get preparationThinking => 'Urim cherche…';

  @override
  String preparationPlanNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes écrites dans le fil',
      one: '1 note écrite dans le fil',
    );
    return '$_temp0';
  }

  @override
  String get preparationPlanPromote => 'En faire mon point';

  @override
  String get preparationPlanPromoted =>
      'Ajouté à la fin de votre point. À vous de le retailler.';

  @override
  String get preparationPlanArticulate => 'Faire articuler ce point';

  @override
  String get preparationPlanArticulateTitle => 'Ce qu’Urim propose';

  @override
  String get preparationPlanArticulateTransition => 'Pour enchaîner';

  @override
  String get preparationPlanArticulateNotice =>
      'Rien n’entre dans votre document tant que vous ne l’avez pas repris.';

  @override
  String get preparationPlanArticulateTake => 'Reprendre dans mon point';

  @override
  String get preparationPlanArticulateTaken =>
      'Repris à la suite de votre point. À vous de le retailler.';

  @override
  String get preparationPlanArticulateClose => 'Fermer';

  @override
  String get preparationPlanArticulateUnavailable =>
      'Urim n’a pas de proposition ici. Votre point reste écrit, et vous le développez comme vous l’avez toujours fait.';

  @override
  String get preparationPlanArticulateEmpty =>
      'Écrivez d’abord ce point : Urim articule ce que vous avez écrit, il ne l’écrit pas.';

  @override
  String get preparationSectionTitre => 'Titre';

  @override
  String get preparationSectionIntroduction => 'Introduction';

  @override
  String get preparationSectionProposition => 'Proposition';

  @override
  String get preparationSectionPhraseInterrogative => 'Phrase interrogative';

  @override
  String get preparationSectionPhraseDeTransition => 'Phrase de transition';

  @override
  String get preparationSectionDivisions => 'Les points';

  @override
  String get preparationSectionSubdivisions => 'Les sous-points';

  @override
  String get preparationSectionIllustrations => 'Illustrations';

  @override
  String get preparationSectionApplication => 'Application';

  @override
  String get preparationSectionConclusion => 'Conclusion';

  @override
  String get preparationSectionObjectif => 'Objectif';

  @override
  String get preparationSectionContexte => 'Contexte du livre';

  @override
  String get preparationSectionDefinitions => 'Définitions';

  @override
  String get preparationSectionNb => 'NB';

  @override
  String get preparationSectionTemoignage => 'Témoignage';

  @override
  String get preparationActionAVenir =>
      'Le serveur accepte déjà vos points ; l\'écran pour les écrire n\'existe pas encore.';

  @override
  String get profilePhone => 'Numéro de téléphone';

  @override
  String get profilePhoneChangeTitle => 'Changer de numéro';

  @override
  String get profilePhoneChangeBody =>
      'Le code partira sur le nouveau numéro : il faut l\'avoir en main.';

  @override
  String get profilePhoneChangeConfirm => 'Recevoir le code';

  @override
  String get profilePhoneChangeFailed =>
      'Le code n\'est pas parti. Votre numéro n\'a pas changé.';

  @override
  String get profilePhoneChangeDone => 'Votre numéro a été changé.';

  @override
  String get profileSecretCode => 'Code à 4 chiffres';

  @override
  String get profileSecretCodeAction => 'Modifier';

  @override
  String get profileSecretCodePending =>
      'Le changement passera par l\'écran de création, encore réservé au premier accès.';

  @override
  String get profileNoChurch => 'Aucune église rattachée';

  @override
  String get profileNoChurchHint =>
      'Le rattachement viendra de l\'annuaire de la plateforme, pas d\'Urim.';

  @override
  String get profileChurchRecognised =>
      'Votre numéro y est reconnu. Vos préparations n\'y sont pas visibles.';

  @override
  String get profileChurchesNote =>
      'Une seule identité, plusieurs églises possibles. Ce que vous écrivez dans Urim ne traverse jamais vers elles.';

  @override
  String get profileDeviceCurrent => 'Cet appareil · actif maintenant';

  @override
  String profileDeviceLastSeen(String date) {
    return 'Dernière activité le $date';
  }

  @override
  String get profileDeviceRemove => 'Retirer';

  @override
  String profileDeviceRemoveTitle(String device) {
    return 'Retirer $device ?';
  }

  @override
  String get profileDeviceRemoveBody =>
      'Cet appareil devra se reconnecter par SMS pour ouvrir Urim.';

  @override
  String get profileReadFailed => 'Le profil n\'a pas pu être lu.';

  @override
  String get profileChangeRefused => 'Cette modification a été refusée.';

  @override
  String get profileChangeFailed =>
      'Cette modification n\'a pas pu être enregistrée.';

  @override
  String get profileNoSession => 'Aucune session ouverte.';

  @override
  String get save => 'Enregistrer';

  @override
  String get drawerNewPreparation => 'Nouvelle préparation';

  @override
  String get drawerPreparations => 'PRÉPARATIONS';

  @override
  String get drawerPreached => 'PRÉDICATIONS';

  @override
  String get drawerEmptyPreached =>
      'Rien encore. Enregistrez votre prochain culte.';

  @override
  String get drawerProjects => 'Projets';

  @override
  String get drawerProjectsPending => 'Bientôt';

  @override
  String get drawerEmpty => 'Rien encore. Écrivez votre première phrase.';

  @override
  String get homeSwitchTitle => 'Voulez-vous basculer à…';

  @override
  String get homeSwitchPrepare => 'Préparer un message';

  @override
  String get homeSwitchPrepareBody =>
      'Faites-vous assister pour accélérer votre préparation.';

  @override
  String get homeSwitchPreach => 'Mes prédications';

  @override
  String get homeSwitchPreachBody => 'Donnez vie à votre prédication.';

  @override
  String get preachedMark => 'J\'ai prêché celle-ci';

  @override
  String preachedMarkDone(String date) {
    return 'Consignée comme prêchée le $date.';
  }

  @override
  String get archiveTitle => 'Ce que vous avez prêché';

  @override
  String get archiveEmpty =>
      'Rien de consigné. Marquez une préparation comme prêchée, ou consignez un message prêché ailleurs.';

  @override
  String get archiveRecordManual => 'Consigner une prédication';

  @override
  String get archiveRecordHint => 'Actes 1:1-14 — ou Hb 2v29, comme vous notez';

  @override
  String get archiveRecordDate => 'Quand l\'avez-vous prêchée ?';

  @override
  String get archiveRecordSubmit => 'Consigner';

  @override
  String get archiveRecordDone => 'Prédication consignée.';

  @override
  String get archiveUnfiled => 'Non rangé';

  @override
  String get coverageTitle => 'Où vous êtes allé';

  @override
  String coverageBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres',
      one: '1 livre',
    );
    return '$_temp0';
  }

  @override
  String coveragePassages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passages',
      one: '1 passage',
    );
    return '$_temp0';
  }

  @override
  String coveragePreachings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prédications',
      one: '1 prédication',
    );
    return '$_temp0';
  }

  @override
  String coverageUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres sans sermon rangé',
      one: '1 livre sans sermon rangé',
      zero: 'Aucun livre sans sermon rangé',
    );
    return '$_temp0';
  }

  @override
  String get coverageNotice =>
      '« Aucun sermon rangé ici » ne veut pas dire que vous ne l\'avez jamais prêché : un texte peut l\'avoir été sous une autre unité, ou sans axe retenu.';

  @override
  String get homeComposerHint =>
      'Une phrase, une référence, ou ce qui pèse cette semaine';

  @override
  String get homeTabPreach => 'Prédications';

  @override
  String get homeTabPrepare => 'Préparations';

  @override
  String get homeRecordSermon => 'Enregistrer la prédication';

  @override
  String get homeServiceToday => 'Culte aujourd\'hui';

  @override
  String get homeServiceTodayPending => 'rien n\'est encore capté';

  @override
  String homeGroupPreached(int count) {
    return 'PRÊCHÉS · $count';
  }

  @override
  String get homePreachedEmptyTitle => 'Aucune prédication captée.';

  @override
  String get homePreachedEmptyBody =>
      'Enregistrez le culte : la prédication s\'ajoutera ici, dans votre voix.';

  @override
  String get homeEmptyTitle => 'Rien en cours.';

  @override
  String get homeEmptyBody =>
      'Écrivez ce que vous voulez dire : une phrase, une référence, ou ce qui pèse cette semaine.';

  @override
  String get homeReadFailed => 'La liste n\'a pas pu être lue.';

  @override
  String get homeGroupThisWeek => 'CETTE SEMAINE';

  @override
  String get homeGroupEarlier => 'PLUS TÔT';

  @override
  String homeActivityToday(String time) {
    return 'Aujourd\'hui, $time';
  }

  @override
  String homeActivityYesterday(String time) {
    return 'Hier, $time';
  }

  @override
  String homeCardMeta(String activity) {
    return '· $activity';
  }

  @override
  String homeCardMetaWithService(String activity, String service) {
    return '· $activity · $service';
  }

  @override
  String gesturePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gestes attendent le réseau',
      one: 'Un geste attend le réseau',
    );
    return '$_temp0';
  }

  @override
  String get gesturePendingBody =>
      'Le moteur répondra dès que la connexion reviendra. Rien n\'est perdu.';

  @override
  String get corpusDrifted =>
      'Le corpus a été relu depuis l\'ouverture — ce qu\'Urim dit ici n\'est plus mot pour mot ce qu\'il disait alors.';

  @override
  String servedFromDevice(String when) {
    return 'Gardé sur cet appareil · $when';
  }

  @override
  String turnSignature(String signature) {
    return 'Découpage relu par $signature';
  }

  @override
  String get turnSignatureMachine => 'Découpage proposé par l’IA, non relu';

  @override
  String turnFoldedBearings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ce que le texte porte — $count axes',
      one: 'Ce que le texte porte — 1 axe',
    );
    return '$_temp0';
  }

  @override
  String turnFoldedFeasibility(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les plans que ce texte tient — $count',
      one: 'Les plans que ce texte tient — 1',
    );
    return '$_temp0';
  }

  @override
  String turnFoldedChips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres propositions',
      one: '1 autre proposition',
    );
    return '$_temp0';
  }

  @override
  String turnFoldedUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count textes relus',
      one: '1 texte relu',
    );
    return '$_temp0';
  }

  @override
  String studyText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Le texte — $count versets',
      one: 'Le texte — 1 verset',
    );
    return '$_temp0';
  }

  @override
  String studyContext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Le contexte — $count notes',
      one: 'Le contexte',
    );
    return '$_temp0';
  }

  @override
  String get studyContextLiterary => 'Littéraire';

  @override
  String get studyContextHistorical => 'Historique';

  @override
  String get turnThemeLabel => 'THÈME';

  @override
  String get turnBearingsSwitchable =>
      'Touchez un axe pour prêcher ce texte dessus.';

  @override
  String get strengthDominant => 'En fait son sujet';

  @override
  String get strengthSupports => 'Le soutient';

  @override
  String get strengthResists => 'Lui résiste';

  @override
  String get strengthAbsent => 'Absent';

  @override
  String get stateHandsBack => 'Rend la main';

  @override
  String get stateServed => 'Matière servie';

  @override
  String get stateDegraded => 'Réponse partielle';

  @override
  String get stateRefused => 'Refus motivé';

  @override
  String get stateFeedbackReady => 'Retour disponible';

  @override
  String get homeRecordStop => 'Arrêter l\'enregistrement';

  @override
  String get homeCaptureRunning => 'Enregistrement';

  @override
  String get homeCaptureStop => 'Arrêter';

  @override
  String get sermonTabSaid => 'Ce qui a été dit';

  @override
  String get sermonTabSynthesis => 'La synthèse';

  @override
  String get sermonTabOutput => 'La sortie';

  @override
  String homeCaptureFragments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fragments écrits',
      one: '1 fragment écrit',
      zero: 'aucun fragment écrit',
    );
    return '$_temp0';
  }

  @override
  String homeCapturePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fragments attendent le réseau',
      one: '1 fragment attend le réseau',
    );
    return '$_temp0';
  }

  @override
  String get homeCaptureStaysHere =>
      'Cet enregistrement reste sur ce téléphone. Il ne se retrouvera pas sur une autre tablette, même connectée au même compte.';

  @override
  String homeCaptureSaved(String duree) {
    return 'Prédication captée · $duree';
  }

  @override
  String get homeCaptureMicRefused =>
      'Urim a besoin du micro pour enregistrer votre prédication. Autorisez-le dans les réglages de l\'appareil.';

  @override
  String get homeCaptureNoMicrophone =>
      'Cet appareil n\'a pas de micro utilisable.';

  @override
  String get homeCaptureStorageFull =>
      'Il n\'y a plus de place pour l\'audio. Libérez quelques centaines de mégaoctets.';

  @override
  String get homeCaptureFailed =>
      'L\'enregistrement n\'a pas pu commencer. Réessayez.';

  @override
  String get homeCaptureInterrupted => 'Interrompue';

  @override
  String homeCaptureAudioLeft(int jours) {
    return 'audio effacé dans $jours j';
  }

  @override
  String get homeCaptureAudioToday => 'audio effacé aujourd\'hui';

  @override
  String get homeCaptureNotSent => 'sur cet appareil, pas encore transcrite';

  @override
  String captureTitle(String date) {
    return 'Culte du $date';
  }

  @override
  String get captureSectionState => 'CE QUI A ÉTÉ CAPTÉ';

  @override
  String captureDuration(String duration) {
    return '$duration enregistrées';
  }

  @override
  String captureFragments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fragments de trente secondes',
      one: '1 fragment de trente secondes',
    );
    return '$_temp0';
  }

  @override
  String get captureUploadAllSent => 'Tout est arrivé au serveur.';

  @override
  String captureUploadPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fragments attendent de partir',
      one: '1 fragment attend de partir',
    );
    return '$_temp0';
  }

  @override
  String get captureUploadNoChurch =>
      'Cette capture attend de savoir devant quelle assemblée elle a été prêchée. Sans elle, elle ne peut pas partir.';

  @override
  String get captureInterrupted =>
      'L\'enregistrement s\'est arrêté tout seul. Ce qui a été capté avant est intact.';

  @override
  String capturePurgeIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'L\'audio est effacé dans $days jours',
      one: 'L\'audio est effacé demain',
      zero: 'L\'audio est effacé aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get transcribeOfferTitle => 'Lire ce culte';

  @override
  String transcribeOfferBody(int megaoctets) {
    return 'Urim peut transcrire cet enregistrement sur ce téléphone. Il doit d\'abord télécharger son modèle : $megaoctets Mo, une seule fois. L\'audio, lui, ne partira pas.';
  }

  @override
  String transcribeModelChip(String gabarit, int megaoctets) {
    return '$gabarit · $megaoctets Mo';
  }

  @override
  String get transcribeDownload => 'Télécharger le modèle';

  @override
  String transcribeDownloading(int received, int total) {
    return 'Téléchargement… $received Mo sur $total';
  }

  @override
  String get transcribeStart => 'Transcrire ce culte';

  @override
  String get transcribeResume => 'Reprendre la transcription';

  @override
  String transcribeRunning(int done, int total) {
    return '$done fragment sur $total';
  }

  @override
  String get transcribeSectionText => 'CE QUI A ÉTÉ DIT';

  @override
  String get transcribeAdditive =>
      'Le texte s\'ajoute par blocs et ne se corrige pas tout seul : ce que vous avez lu ne changera pas.';

  @override
  String get transcribeFailedModel =>
      'Le téléchargement n\'a pas abouti. Réessayez quand le réseau sera meilleur — rien n\'est perdu.';

  @override
  String get transcribeFailedAudio => 'Cet enregistrement n\'est pas lisible.';

  @override
  String get transcribeFailedEngine =>
      'La transcription s\'est arrêtée. Ce qui était déjà lu est gardé.';

  @override
  String get captureSaidPending =>
      'Rien n\'a encore été transcrit. Le moteur qui lira cet audio n\'est pas retenu : son gabarit se décide en le mesurant sur un vrai téléphone, pas en le décrétant.';

  @override
  String get captureSynthesisPending =>
      'La synthèse résume ce qui a été dit. Elle attend donc la transcription — résumer un enregistrement qu\'on n\'a pas lu serait inventer.';

  @override
  String get captureOutputPending =>
      'La lecture à voix haute et l\'interprétation partent d\'une synthèse validée. Elles attendent celle-ci.';

  @override
  String get captureListenResume => 'Reprendre';

  @override
  String get captureListenPause => 'Pause';

  @override
  String get captureNameIt => 'Nommer ce culte';

  @override
  String get captureNameHint => 'Nouvelle naissance, Actes 2…';

  @override
  String get captureNameSave => 'Enregistrer';

  @override
  String get captureNameCancel => 'Annuler';

  @override
  String get captureNameRemove => 'Retirer le nom';

  @override
  String captureUnnamed(String date) {
    return 'Culte du $date';
  }

  @override
  String get captureListen => 'Réécouter ce culte';

  @override
  String get captureListenStop => 'Arrêter';

  @override
  String get captureListenPreparing => 'Préparation de la lecture…';

  @override
  String get captureListenEmpty =>
      'Il n\'y a rien à réécouter : aucun fragment n\'a été écrit.';

  @override
  String get captureListenFailed => 'La lecture n\'a pas pu commencer.';

  @override
  String get captureLocalOnly =>
      'Cet enregistrement reste sur ce téléphone. Il ne se retrouvera pas sur une autre tablette, même connectée au même compte.';

  @override
  String get homeRecordPending =>
      'Le moteur de transcription n\'est pas encore retenu. Les prédications déjà transcrites restent lisibles ici.';

  @override
  String get newPreparationDictateListening =>
      'Urim vous écoute. Appuyez pour arrêter.';

  @override
  String get newPreparationDictateStart => 'Dicter';

  @override
  String get newPreparationDictateStop => 'Arrêter la dictée';

  @override
  String get newPreparationDictateNoEngine =>
      'Cet appareil n\'a pas de reconnaissance vocale. Écrivez votre phrase.';

  @override
  String get newPreparationDictateMicRefused =>
      'Urim a besoin du micro pour écrire ce que vous dites. Autorisez-le dans les réglages de l\'appareil.';

  @override
  String get newPreparationDictateFailed =>
      'La dictée s\'est arrêtée. Réessayez, ou écrivez votre phrase.';

  @override
  String get newPreparationServiceDate => 'Date du culte';

  @override
  String get newPreparationOpen => 'Ouvrir la préparation';

  @override
  String get newPreparationFailed =>
      'Cette préparation n\'a pas pu être ouverte.';

  @override
  String get newPreparationNeedsNetwork =>
      'Ouvrir demande le réseau : Urim consulte les textes pour lire votre phrase. Elle est gardée — vous la retrouverez ici.';

  @override
  String get preparationEmpty =>
      'Posez votre première idée en bas de l\'écran.';

  @override
  String get preparationLoadFailed => 'Chargement impossible.';

  @override
  String get preparationComposerHint => 'Écrivez votre réponse, ou choisissez…';

  @override
  String get preparationDictationSoon => 'Dictée — bientôt disponible';

  @override
  String get preparationSend => 'Ajouter au fil';

  @override
  String get blockUrim => 'URIM';

  @override
  String get blockTrace => 'Comment j\'en suis arrivé là';

  @override
  String get blockScripture => 'ÉCRITURE';

  @override
  String blockRecognisedInQuote(String at) {
    return 'RECONNU DANS LA CITATION · $at';
  }

  @override
  String get blockSynthesis => 'SYNTHÈSE D\'URIM';

  @override
  String blockMoreLink(String label) {
    return '$label →';
  }

  @override
  String get lociUnavailable =>
      'La liste des loci n\'est pas encore écrite. Les trois axes proposés viennent de votre phrase ; les sept autres attendent que le moteur existe.';

  @override
  String get stanceSubject => 'Ce texte en fait son sujet';

  @override
  String get stanceSupports => 'Ce texte le soutient';

  @override
  String get stanceComplicates => 'Ce texte le complique';

  @override
  String get transcriptionFallbackTitle => 'Transcription';

  @override
  String get transcriptionOptions => 'Options';

  @override
  String get transcriptionResume => 'Reprendre l\'enregistrement';

  @override
  String get transcriptionAudioDeleted =>
      'L\'audio a été effacé : la reprise repartira d\'une nouvelle capture.';

  @override
  String get transcriptionRecorded => 'Enregistré';

  @override
  String transcriptionFragmentsAcknowledged(int count) {
    return '$count fragments acquittés';
  }

  @override
  String transcriptionAudioDeletedOn(String date) {
    return 'audio supprimé le $date';
  }

  @override
  String get transcriptionSectionFragments => 'Fragments';

  @override
  String get transcriptionSectionConvoked => 'Ce que vous avez convoqué';

  @override
  String get transcriptionAllAcknowledged =>
      'Tous les fragments sont acquittés.';

  @override
  String transcriptionFragmentsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fragments attendent le réseau. Ils partiront seuls, dans l\'ordre.',
      one: 'Un fragment attend le réseau. Il partira seul, dans l\'ordre.',
    );
    return '$_temp0';
  }

  @override
  String get transcriptionConvokedAnnounced => 'ANNONCÉ À VOIX HAUTE';

  @override
  String get transcriptionConvokedRecognised => 'RECONNU DANS LA CITATION';

  @override
  String transcriptionPlanned(String reference) {
    return '$reference — prévu dans votre préparation';
  }

  @override
  String transcriptionUnplanned(String reference) {
    return '$reference — non prévu';
  }

  @override
  String get transcriptionSpeakerNotice =>
      'Aucune séparation de locuteurs. Les voix éloignées du micro sont écartées avant écriture, jamais enregistrées puis filtrées.';

  @override
  String get transcriptionFixText => 'Corriger la transcription';

  @override
  String get transcriptionSeeSynthesis => 'Voir la synthèse';

  @override
  String get transcriptionOpenPreparation => 'Ouvrir la préparation';

  @override
  String get transcriptionNotFound =>
      'Cette préparation n\'a pas d\'enregistrement transcrit.';

  @override
  String get synthesisTitleDraft => 'Synthèse — à valider';

  @override
  String get synthesisTitleValidated => 'Synthèse — validée';

  @override
  String get synthesisNotFound => 'Cette prédication n\'a pas de synthèse.';

  @override
  String get synthesisSealTitleDraft => 'Rien n\'est encore parti.';

  @override
  String get synthesisSealBodyDraft =>
      'Tant que vous n\'avez pas validé, cette synthèse n\'existe que pour vous. Aucun membre ne la voit, aucune voix ne la lit.';

  @override
  String get synthesisSealTitleValidated => 'Validée par vous.';

  @override
  String get synthesisSealBodyValidated =>
      'Elle peut être lue à voix haute. Vous restez le seul à pouvoir la modifier.';

  @override
  String get synthesisSectionCapsules => 'Ce qu\'Urim a retenu';

  @override
  String synthesisCapsuleLabelPlain(int index) {
    return 'CAPSULE $index';
  }

  @override
  String synthesisCapsuleLabel(int index, String at) {
    return 'CAPSULE $index · DIT À $at';
  }

  @override
  String get synthesisCapsuleSource =>
      'Voir où c\'est dit dans votre prédication';

  @override
  String get synthesisSectionVerse => 'Le verset, non réécrit';

  @override
  String get synthesisModelNotice =>
      'Les capsules sont écrites par un modèle à partir de votre transcription. Les versets, eux, viennent de la Bible — jamais du modèle. Relisez avant de valider.';

  @override
  String get synthesisValidate => 'Valider cette synthèse';

  @override
  String get synthesisValidated => 'Synthèse validée';

  @override
  String get synthesisValidatedToast =>
      'Synthèse validée. Elle peut maintenant être lue.';

  @override
  String get synthesisSectionReadAloud => 'Lire à voix haute';

  @override
  String get synthesisReadAloudIntro =>
      'Pour ceux de l\'assemblée qui écouteront plutôt que de lire.';

  @override
  String get synthesisReadAloudLocked =>
      'Disponible une fois la synthèse validée.';

  @override
  String get synthesisReadAloudOpen =>
      'La lecture reprend la synthèse telle que vous l\'avez validée.';

  @override
  String get synthesisVoiceComing => 'Lecture à venir';

  @override
  String get synthesisVoiceLocked => 'Disponible une fois la synthèse validée';

  @override
  String get synthesisVoiceRead => 'Écouter la synthèse';

  @override
  String get synthesisVoiceStop => 'Arrêter la lecture';

  @override
  String get synthesisVoiceNoLanguage =>
      'Cette voix n\'est pas installée sur ce téléphone. Elle se télécharge depuis les réglages, dans « Synthèse vocale ».';

  @override
  String get synthesisVoiceNoEngine =>
      'Ce téléphone n\'a pas de synthèse vocale.';

  @override
  String get synthesisVoiceFailed => 'La lecture n\'a pas pu commencer.';

  @override
  String get synthesisVoiceNotValidated =>
      'Validez la synthèse avant de la faire lire.';

  @override
  String get synthesisVoiceEnglish => 'Anglais';

  @override
  String get voiceFrenchLabel => 'Français';

  @override
  String get voiceFrenchNote => 'Voix de synthèse, sur cet appareil';

  @override
  String get voiceEnglishNote => 'Voix de synthèse, sur cet appareil';

  @override
  String get voiceOwnLabel => 'Votre propre voix';

  @override
  String get voiceOwnNote =>
      'Enregistrez-vous disant la synthèse dans la langue de votre assemblée — rien à traduire, rien à générer';

  @override
  String get voiceMalinkeLabel => 'Malinké';

  @override
  String get voiceMalinkeNote =>
      'Interprétée par l\'équipe Dorea — la langue que nous savons tenir aujourd\'hui';

  @override
  String get trackRecordStart => 'Enregistrer votre voix';

  @override
  String get trackRecordStop => 'Arrêter l\'enregistrement';

  @override
  String get trackListen => 'Écouter votre piste';

  @override
  String get trackListenStop => 'Arrêter';

  @override
  String get trackRedo => 'Refaire';

  @override
  String get trackRedoHint => 'Un nouvel enregistrement remplace celui-ci.';

  @override
  String get trackLanguageTitle => 'Dans quelle langue ?';

  @override
  String get trackLanguageBody =>
      'Nommez-la comme vous la nommez. Ce n\'est pas une liste : c\'est la langue de votre assemblée.';

  @override
  String get trackLanguageHint => 'Baoulé, dioula, français…';

  @override
  String get trackLanguageCancel => 'Annuler';

  @override
  String get trackLanguageConfirm => 'Ouvrir le micro';

  @override
  String trackRecordingIn(String language) {
    return 'Enregistrement en $language';
  }

  @override
  String trackSaved(String language, String duration) {
    return 'Piste enregistrée en $language · $duration';
  }

  @override
  String get trackNotValidated =>
      'Validez la synthèse avant d\'enregistrer votre voix.';

  @override
  String get trackEmpty =>
      'Le micro s\'est fermé sans rien enregistrer. Rien n\'a été gardé.';

  @override
  String get trackMicRefused =>
      'Le micro n\'est pas autorisé. Ouvrez les réglages du téléphone pour le permettre.';

  @override
  String get trackNoMicrophone => 'Ce téléphone n\'a pas de micro utilisable.';

  @override
  String get trackStorageFull =>
      'Plus assez de place pour enregistrer. Libérez quelques mégaoctets.';

  @override
  String get trackEngineFailed => 'L\'enregistrement n\'a pas pu commencer.';

  @override
  String get trackFileMissing =>
      'Le fichier de cette piste n\'est plus sur le téléphone.';

  @override
  String get trackNoPlayer => 'Ce téléphone ne sait pas jouer cette piste.';

  @override
  String get trackPlaybackFailed => 'La lecture n\'a pas pu commencer.';

  @override
  String synthesisSpokenMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String synthesisSpokenMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds';
  }

  @override
  String get options => 'Options';

  @override
  String blockToday(String time) {
    return 'AUJOURD\'HUI $time';
  }

  @override
  String blockYesterday(String time) {
    return 'HIER $time';
  }

  @override
  String blockOnDate(String date, String time) {
    return '$date $time';
  }

  @override
  String synthesisPointRange(String from, String to) {
    return '  — $from à $to';
  }

  @override
  String get editorTitle => 'Tailler une pièce';

  @override
  String get editorPreparing => 'Lecture de l\'onde…';

  @override
  String get editorEmpty =>
      'Il n\'y a rien à tailler : aucun fragment n\'a été écrit.';

  @override
  String get editorGesture =>
      'Écoutez, arrêtez-vous à la frontière, puis posez la borne. L\'onde sert à viser ; l\'oreille tranche.';

  @override
  String get editorPlay => 'Écouter';

  @override
  String get editorPause => 'Pause';

  @override
  String get editorBack => 'Reculer de dix secondes';

  @override
  String get editorForward => 'Avancer de dix secondes';

  @override
  String get editorZoomIn => 'Resserrer';

  @override
  String get editorZoomOut => 'Élargir';

  @override
  String editorPosition(String position, String duration) {
    return '$position sur $duration';
  }

  @override
  String get editorSetStart => 'Début ici';

  @override
  String get editorSetEnd => 'Fin ici';

  @override
  String get editorPiece => 'La pièce';

  @override
  String editorRange(String from, String to) {
    return '$from → $to';
  }

  @override
  String editorLength(String duration) {
    return '$duration de pièce';
  }

  @override
  String get editorHearStart => 'Écouter le début';

  @override
  String get editorHearEnd => 'Écouter la fin';

  @override
  String get editorCut => 'Tailler cette pièce';

  @override
  String get editorCutting => 'Découpage…';

  @override
  String get editorTooShort => 'Une pièce fait au moins une seconde.';

  @override
  String get editorCutDone =>
      'Pièce taillée. Elle vit avec sa publication, et ne disparaîtra pas au septième jour.';

  @override
  String get editorNext => 'Enchaîner sur la suite';

  @override
  String get editorSafety =>
      'La matière reste entière. Tailler écrit une pièce à côté ; vous pouvez recommencer autant de fois qu\'il faut.';

  @override
  String get editorName => 'Nom de la pièce';

  @override
  String get editorNameHint => 'Prédication, prière…';

  @override
  String get piecesTitle => 'Les pièces taillées';

  @override
  String get piecesEmpty =>
      'Rien n\'a encore été taillé dans ce culte. L\'audio brut disparaît au septième jour ; une pièce, non.';

  @override
  String get piecesCut => 'Tailler une pièce';

  @override
  String piecesFrom(String from, String to) {
    return 'de $from à $to';
  }

  @override
  String get piecesPlay => 'Écouter';

  @override
  String get piecesStop => 'Arrêter';

  @override
  String get piecesSurvives =>
      'Ces pièces survivent à la purge du septième jour.';

  @override
  String get piecesShare => 'Envoyer';

  @override
  String get piecesShareMissing => 'Ce fichier n\'est plus sur le téléphone.';

  @override
  String get piecesShareFailed =>
      'Le partage n\'a pas pu s\'ouvrir sur cet appareil.';

  @override
  String get piecesRename => 'Renommer';

  @override
  String get piecesRenameSave => 'Enregistrer';

  @override
  String get piecesRenameCancel => 'Annuler';

  @override
  String get piecesDelete => 'Supprimer';

  @override
  String get piecesDeleteTitle => 'Supprimer cette pièce ?';

  @override
  String get piecesDeleteBody =>
      'L\'audio part avec elle, et ne se retrouvera pas. Si le culte a passé sept jours, il n\'y a plus de quoi la retailler.';

  @override
  String get synthesisFromPlanGone =>
      'La synthèse ne se fabrique plus depuis votre plan. Un résumé du plan résume ce que vous comptiez dire, pas ce que vous avez dit — et lu à une assemblée, il présenterait un projet comme une parole prononcée.\n\nElle reviendra, tirée du texte de ce que vous avez réellement prêché.';

  @override
  String get outputWaitsSynthesis =>
      'La lecture à voix haute et l\'interprétation partent d\'une synthèse. Elles attendent celle qui naîtra de ce que vous avez prêché.';
}
