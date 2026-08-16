import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';

/// Une capsule : ce qu'Urim a retenu d'un moment de la prédication.
///
/// Écrite par un modèle à partir de la transcription — d'où [saidAt], qui
/// permet de retourner à l'endroit exact et de vérifier. Une capsule sans son
/// point d'ancrage serait invérifiable.
final class SynthesisCapsule extends Equatable {
  const SynthesisCapsule({required this.text, required this.saidAt});

  final String text;
  final Duration saidAt;

  @override
  List<Object?> get props => [text, saidAt];
}

/// Comment la synthèse est portée à la voix.
///
/// Ces langues ne sont **pas** des langues d'interface : aucun écran ne sera
/// traduit en dioula, en baoulé ou en bété. Elles ne concernent que la lecture
/// à voix haute — ceux de l'assemblée que l'écrit laisse dehors. C'est une
/// modalité de sortie, jamais une locale.
enum ReadAloudKind {
  /// Voix de synthèse dans la langue de la prédication.
  synthetic,

  /// Traduction, à relire par un locuteur avant diffusion.
  ///
  /// Deux briques derrière, dans des langues très peu dotées : traduire, puis
  /// dire. Une traduction approximative d'un texte biblique n'est pas un défaut
  /// d'ergonomie — c'est une faute. Elles attendront d'être bonnes.
  translated,

  /// La voix de celui qui a prêché : rien à traduire, rien à générer.
  ///
  /// La seule qui ne demande aucun modèle, et la plus juste — c'est la voix que
  /// l'assemblée reconnaît.
  ownVoice,
}

/// Une lecture proposée de la synthèse.
final class ReadAloudVoice extends Equatable {
  const ReadAloudVoice({
    required this.language,
    required this.kind,
    required this.note,
    this.duration,
  });

  /// « Français », « Dioula », « Baoulé », « Ta propre voix ».
  final String language;

  final ReadAloudKind kind;

  /// Ce que vaut cette lecture : « Traduction à relire par un locuteur avant
  /// diffusion ».
  final String note;

  final Duration? duration;

  @override
  List<Object?> get props => [language, kind, note, duration];
}

/// La synthèse d'une prédication, avant validation.
///
/// [isValidated] commande tout : tant qu'elle est fausse, la synthèse n'existe
/// que pour son auteur. C'est la promesse écrite sur l'écran — aucun membre ne
/// la voit, aucune voix ne la lit — et elle doit être tenue par le code, pas
/// par l'intention.
final class SynthesisDraft extends Equatable {
  const SynthesisDraft({
    required this.preparationId,
    required this.capsules,
    required this.verse,
    this.voices = const [],
    this.isValidated = false,
  });

  final String preparationId;
  final List<SynthesisCapsule> capsules;

  /// Le verset, **non réécrit** : il vient de la Bible, jamais du modèle.
  final QuotedPassage verse;

  final List<ReadAloudVoice> voices;
  final bool isValidated;

  /// Rien ne peut être lu à voix haute avant validation.
  bool get canBeReadAloud => isValidated;

  SynthesisDraft validated() => SynthesisDraft(
        preparationId: preparationId,
        capsules: capsules,
        verse: verse,
        voices: voices,
        isValidated: true,
      );

  @override
  List<Object?> get props =>
      [preparationId, capsules, verse, voices, isValidated];
}
