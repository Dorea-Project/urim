import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/preparation/recording.dart';
import 'package:urim/domain/entities/transcription/synthesis_draft.dart';
import 'package:urim/domain/entities/transcription/transcription_review.dart';

/// Relecture d'une prédication transcrite, **en mémoire**.
///
/// Aucun moteur ne transcrit encore quoi que ce soit (Q2), et aucun modèle
/// n'écrit de capsule (Q3). Ce dépôt sert l'exemple des maquettes pour que le
/// parcours soit traversable et discutable ; la validation, elle, fonctionne
/// vraiment — c'est la seule mécanique de l'écran qui ne dépend d'aucune
/// décision en attente.
final class InMemoryTranscriptionRepository {
  InMemoryTranscriptionRepository({required this.preparationId}) {
    _review = _seedReview();
    _synthesis = _seedSynthesis();
  }

  /// Préparation transcrite du jeu d'exemple.
  final String preparationId;

  late TranscriptionReview _review;
  late SynthesisDraft _synthesis;

  Future<Result<TranscriptionReview>> review() async => Result.success(_review);

  Future<Result<SynthesisDraft>> synthesis() async =>
      Result.success(_synthesis);

  /// Valide la synthèse. Avant cela, rien n'est lisible à voix haute.
  Future<Result<SynthesisDraft>> validate() async {
    if (_synthesis.isValidated) {
      return const Result.failed(
        ValidationFailure(
          message: 'Cette synthèse est déjà validée.',
          code: 'synthesis_already_validated',
        ),
      );
    }

    _synthesis = _synthesis.validated();
    return Result.success(_synthesis);
  }

  static final QuotedPassage _brotherlyLove = QuotedPassage(
    ref: const VerseRef(bookId: 'heb', chapter: 13, verse: 1).asPassage(),
    referenceLabel: 'Hébreux 13:1',
    text: 'Que l\'amour fraternel continue.',
    translationLabel: 'LSG 1910',
  );

  TranscriptionReview _seedReview() => TranscriptionReview(
        preparationId: preparationId,
        title: 'Hébreux 13 — 9 août',
        recording: Recording(
          id: 'rec-heb-13',
          duration: const Duration(minutes: 41, seconds: 7),
          status: RecordingStatus.transcribed,
          fragmentCount: 57,
          fragmentsAcknowledged: 55,
          audioDeletedOn: DateTime(2026, 8, 16),
          waveform: _waveform,
        ),
        convoked: [
          ConvokedScripture(
            passage: _brotherlyLove,
            at: const Duration(minutes: 4, seconds: 12),
            kind: ConvocationKind.announced,
            wasPlanned: true,
          ),
          ConvokedScripture(
            passage: QuotedPassage(
              ref: const VerseRef(bookId: 'heb', chapter: 13, verse: 3)
                  .asPassage(),
              referenceLabel: 'Hébreux 13:3',
              text: 'Souvenez-vous des prisonniers, comme si vous étiez aussi '
                  'prisonniers.',
              translationLabel: 'LSG 1910',
            ),
            at: const Duration(minutes: 22, seconds: 38),
            kind: ConvocationKind.recognizedInQuote,
            wasPlanned: false,
          ),
        ],
        remarks: const [
          TranscriptionRemark(
            label: 'CONSTAT',
            body: 'Trois textes ont été convoqués sans avoir été prévus, tous '
                'dans le même chapitre. Tu as prêché une chaîne là où la '
                'préparation portait une unité.',
          ),
          TranscriptionRemark(
            label: 'ALIGNEMENT AU SQUELETTE',
            body: 'Mouvement 3 non repéré : son verset d\'ancrage n\'a été '
                'reconnu à aucun moment. Je ne sais pas s\'il a été traité — '
                'je sais seulement que je ne l\'ai pas entendu.',
          ),
        ],
      );

  SynthesisDraft _seedSynthesis() => SynthesisDraft(
        preparationId: preparationId,
        capsules: const [
          SynthesisCapsule(
            text: 'L\'amour fraternel n\'est pas un sentiment à retrouver : '
                'c\'est une pratique à continuer. Le texte ne dit pas de '
                'recommencer, il dit de ne pas s\'arrêter.',
            saidAt: Duration(minutes: 4, seconds: 12),
          ),
          SynthesisCapsule(
            text: 'Se souvenir des prisonniers, c\'est se mettre à leur place '
                '— « comme si vous étiez aussi prisonniers ». La solidarité '
                'passe par l\'imagination avant de passer par les actes.',
            saidAt: Duration(minutes: 18, seconds: 40),
          ),
        ],
        verse: _brotherlyLove,
        voices: const [
          ReadAloudVoice(
            language: 'Français',
            kind: ReadAloudKind.synthetic,
            note: 'Voix de synthèse',
            duration: Duration(minutes: 2, seconds: 40),
          ),
          ReadAloudVoice(
            language: 'Dioula',
            kind: ReadAloudKind.translated,
            note: 'Traduction à relire par un locuteur avant diffusion',
          ),
          ReadAloudVoice(
            language: 'Baoulé',
            kind: ReadAloudKind.translated,
            note: 'Traduction à relire par un locuteur avant diffusion',
          ),
          ReadAloudVoice(
            language: 'Bété',
            kind: ReadAloudKind.translated,
            note: 'Traduction à relire par un locuteur avant diffusion',
          ),
          ReadAloudVoice(
            language: 'Ta propre voix',
            kind: ReadAloudKind.ownVoice,
            note: 'Enregistre-toi lisant la synthèse — rien à traduire, rien '
                'à générer',
          ),
        ],
      );

  /// Amplitudes de la maquette : une parole continue, avec des respirations.
  static const List<double> _waveform = [
    0.35, 0.62, 0.48, 0.81, 0.55, 0.72, 0.4, 0.9, 0.66, 0.5, //
    0.78, 0.44, 0.85, 0.6, 0.7, 0.38, 0.92, 0.52, 0.68, 0.46,
    0.8, 0.58, 0.74, 0.42, 0.88, 0.64, 0.5, 0.76, 0.36, 0.83,
    0.56, 0.7, 0.45, 0.9, 0.6, 0.52, 0.79, 0.4, 0.86, 0.63,
  ];
}

final transcriptionRepositoryProvider =
    Provider.family<InMemoryTranscriptionRepository, String>(
  (ref, preparationId) {
    // Maintenu en vie : la validation vit ici, et quitter l'écran ne doit pas
    // la défaire. Une vraie persistance rendra ce maintien inutile.
    ref.keepAlive();

    return InMemoryTranscriptionRepository(preparationId: preparationId);
  },
);
