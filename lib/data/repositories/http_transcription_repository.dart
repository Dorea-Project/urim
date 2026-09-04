import 'package:dio/dio.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/transcription/synthesis_draft.dart';
import 'package:urim/domain/entities/transcription/transcription_review.dart';
import 'package:urim/domain/repositories/transcription_repository.dart';

/// La synthèse, servie par le serveur — **A4.8, la fin du jeu d'exemple**.
///
/// ```
/// GET  /urim/studies/{id}/synthese          ⛔ n'existe plus
/// POST /urim/studies/{id}/synthese/validation ⛔ n'existe plus
/// ```
///
/// ⛔ **CES DEUX ROUTES ONT ÉTÉ RETIRÉES DU SERVEUR LE 06/09/2026** (D27 côté
/// S6, D72 côté application). Ce fichier ne les appelle donc plus de nulle part :
/// `SermonShell` n'ouvre plus la synthèse, et rien d'autre ne la demandait.
///
/// 🔴 **Ne pas rebrancher cet appel.** Il rendrait un 404 que l'écran
/// traduirait en panne réseau, là où la vérité est une décision : *une synthèse
/// bâtie sur le plan résume une intention, pas un sermon*. Celle qui remplacera
/// celle-ci naîtra du **transcript d'une pièce**, et son chemin ne sera pas
/// `/studies/{id}/…` — il pendra d'une pièce.
///
/// Ce dépôt reste dans l'arbre parce que [review] le partage, et parce que la
/// forme de sa lecture servira le nouvel objet. Tout ce qui suit décrit ce qui
/// **était** vrai jusqu'au 05/09.
///
/// ---
///
/// ## 🔴 D59 : cette synthèse ne vient pas d'un transcript
///
/// Le verrou de séquencement interdit *transcript → synthèse* tant que la
/// transcription n'a pas été mesurée dans trois églises — *une synthèse bâtie
/// sur une transcription non mesurée est une invention présentée comme un
/// souvenir*. Il tient entier.
///
/// Ce que ce dépôt lit est autre chose : des capsules tirées de la
/// **préparation** — péricope bornée, axe retenu, plan que le pasteur a écrit.
/// Aucun micro ne s'est allumé, aucune mesure ne la garde.
///
/// ## Ce que le serveur répond quand il n'a rien
///
/// ⚠️ **Pas un 404, pas un corps vide : `ready: false` et un motif.** La
/// préparation existe ; ce qui manque est un passage servi, un axe, ou un plan
/// écrit. D13 : *ce qui n'est pas encore ouvert dit quoi et pourquoi* — un
/// écran vide ne se distingue pas d'un oubli.
///
/// ## Ce que [review] ne peut pas faire
///
/// Elle échoue, et **c'est vrai** : personne ne transcrit encore. Le modèle
/// embarqué (D52) attend son banc d'essai. Les deux verbes ne s'ouvrent pas
/// ensemble, et l'écran doit pouvoir dire l'un disponible et l'autre non.
final class HttpTranscriptionRepository implements TranscriptionRepository {
  const HttpTranscriptionRepository({
    required Dio dio,
    required String preparationId,
  })  : _dio = dio,
        _preparationId = preparationId;

  final Dio _dio;
  final String _preparationId;

  static const Failure _pasDeTranscript = ValidationFailure(
    message: 'Aucune transcription n\'existe encore pour cette prédication.',
    code: 'transcription_unavailable',
  );

  @override
  Future<Result<TranscriptionReview>> review() async =>
      const Result.failed(_pasDeTranscript);

  @override
  Future<Result<SynthesisDraft>> synthesis() => _appel(
        () => _dio.get<Map<String, dynamic>>(
          '/urim/studies/$_preparationId/synthese',
        ),
      );

  @override
  Future<Result<SynthesisDraft>> validate() => _appel(
        () => _dio.post<Map<String, dynamic>>(
          '/urim/studies/$_preparationId/synthese/validation',
        ),
      );

  Future<Result<SynthesisDraft>> _appel(
    Future<Response<Map<String, dynamic>>> Function() envoi,
  ) async {
    try {
      final corps = (await envoi()).data ?? const <String, dynamic>{};

      // Le serveur répond 200 avec `ready: false` quand il manque de quoi
      // proposer. Le motif vient de lui : il sait ce qui manque, l'écran non.
      if (corps['ready'] == false) {
        return Result.failed(
          ValidationFailure(
            message: (corps['reason'] as String?) ?? _pasDeTranscript.message,
            code: 'synthesis_not_ready',
          ),
        );
      }

      return Result.success(_synthese(corps));
    } on DioException catch (erreur) {
      return Result.failed(_echec(erreur));
    }
  }

  Failure _echec(DioException erreur) {
    final code = erreur.response?.statusCode;
    final detail = erreur.response?.data;
    final message = detail is Map<String, dynamic>
        ? (detail['detail'] ?? detail['message'])?.toString()
        : null;

    // 🔴 **403 : signer la synthèse d'un autre.** Deux pasteurs d'une même
    // église se relisent — la lecture est partagée, la signature non. Après
    // validation, la synthèse *devient la parole de son auteur*.
    if (code == 403) {
      return ValidationFailure(
        message: message ??
            'Cette préparation n\'est pas la vôtre : sa synthèse se signe par '
                'son auteur.',
        code: 'synthesis_not_yours',
      );
    }
    if (code == 409) {
      return ValidationFailure(
        message: message ?? _pasDeTranscript.message,
        code: 'synthesis_not_ready',
      );
    }
    if (code != null && code >= 400 && code < 500) {
      return ValidationFailure(
        message: message ?? 'Cette synthèse n\'a pas pu être servie.',
        code: 'synthesis_refused',
      );
    }

    // Le reste est du réseau : l'écran le distingue déjà et propose de
    // réessayer, là où un refus se lit comme un jugement.
    return const NetworkFailure(
      message: 'Le serveur n\'a pas répondu.',
      code: 'network',
    );
  }

  SynthesisDraft _synthese(Map<String, dynamic> corps) {
    final verset = corps['verse'] as Map<String, dynamic>?;

    return SynthesisDraft(
      preparationId: (corps['preparation_id'] as String?) ?? _preparationId,
      capsules: [
        for (final brut in (corps['capsules'] as List<dynamic>? ?? const []))
          if (brut is Map<String, dynamic> &&
              (brut['text'] as String?)?.trim().isNotEmpty == true)
            // ⚠️ **Aucun `saidAt`, et surtout pas un zéro de remplacement.**
            // Ces capsules naissent d'un plan qui n'a pas été prêché : il n'y
            // a aucun instant à pointer, et « DIT À 0:00 » ferait mentir
            // l'écran poliment.
            SynthesisCapsule(text: (brut['text'] as String).trim()),
      ],
      verse: QuotedPassage(
        referenceLabel: (verset?['reference_label'] as String?) ?? '',
        text: (verset?['text'] as String?) ?? '',
        // 🔴 **Le verset vient du corpus, jamais du modèle** — c'est le serveur
        // qui le sert à part, et son invite interdit au modèle d'en citer un.
        // La version est celle qu'Urim sert partout ailleurs.
        translationLabel: 'LSG 1910',
      ),
      isValidated: corps['is_validated'] == true,
      voices: _voix,
    );
  }

  /// Les lectures **offertes** — composées ici, jamais servies par le serveur.
  ///
  /// 🔴 **Sans elles, l'onglet « sortie » est vide.** Le 29/08, le dépôt réel
  /// laissait `voices` retomber sur sa valeur par défaut : face au serveur,
  /// l'écran n'affichait ni lecture française, ni ligne « Votre propre voix »,
  /// donc **aucun bouton d'enregistrement**. Tout marchait en démonstration, où
  /// le jeu d'essai les fournissait — et rien ne marchait ailleurs.
  ///
  /// ⚠️ **C'est une offre, pas de la donnée.** « Voici ce qu'on peut faire
  /// entendre » ne décrit pas un état du serveur : ça décrit ce que cette
  /// version de l'application sait produire. Les faire venir du serveur
  /// obligerait à redéployer le back pour ajouter une langue, et ferait
  /// dépendre d'un aller-retour réseau un écran qui n'en a pas besoin.
  ///
  /// L'ordre est celui de D60, et il n'est pas décoratif : ce que la machine
  /// sait dire, puis **la voix du pasteur** — la seule qui ne demande aucun
  /// modèle et la plus juste — puis ce que l'équipe Dorea sait tenir.
  static const List<ReadAloudVoice> _voix = [
    ReadAloudVoice(
      code: 'fr',
      language: 'Français',
      kind: ReadAloudKind.synthetic,
      note: 'Voix de synthèse, sur cet appareil',
    ),
    ReadAloudVoice(
      code: 'en',
      language: 'Anglais',
      kind: ReadAloudKind.synthetic,
      note: 'Voix de synthèse, sur cet appareil',
    ),
    ReadAloudVoice(
      code: 'own',
      language: 'Votre propre voix',
      kind: ReadAloudKind.ownVoice,
      note: 'Enregistrez-vous disant la synthèse dans la langue de votre '
          'assemblée — rien à traduire, rien à générer',
    ),
    // ⚠️ **Proposée, jamais imposée** (D63). Elle dit ce que Dorea sait tenir
    // aujourd'hui, jamais ce que le pasteur est censé parler : une langue est
    // une identité, et un pasteur baoulé à qui on propose le malinké sans motif
    // lirait une présomption sur qui il est. Le bouton reste fermé — l'atelier
    // d'interprétation n'existe pas encore.
    ReadAloudVoice(
      code: 'man',
      language: 'Malinké',
      kind: ReadAloudKind.translated,
      note: "Interprétée par l'équipe Dorea — la langue que nous savons "
          "tenir aujourd'hui",
    ),
  ];
}
