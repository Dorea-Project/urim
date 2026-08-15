import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/preparation/recording.dart';

/// Par où la préparation a commencé.
///
/// Le choix est fait une fois, à la création — « Tu pourras changer en cours
/// de route » porte sur la manière de saisir, pas sur la nature de la
/// préparation : une transcription reste adossée à un enregistrement, même
/// si on écrit ensuite dedans.
enum PreparationOrigin {
  /// Écrite ou dictée directement.
  written,

  /// Issue d'un enregistrement transcrit.
  transcribed;

  /// Étiquette affichée sur la carte d'accueil.
  String get label => switch (this) {
        PreparationOrigin.written => 'Écrit',
        PreparationOrigin.transcribed => 'Transcrit',
      };
}

/// Où en est le travail, du point de vue de celui qui prêche.
///
/// Ce n'est pas un état d'avancement en pourcentage : c'est **à qui est la
/// main**. L'accueil s'ordonne là-dessus — ce qui attend une réponse se voit
/// en premier.
enum PreparationState {
  /// Urim a posé une question et attend : la main est à l'utilisateur.
  handsBack('Rend la main'),

  /// Urim a servi de la matière ; rien n'est bloqué.
  served('Matière servie'),

  /// Le message a été prêché, Urim a quelque chose à en dire.
  feedbackReady('Retour disponible'),

  /// Urim n'a pas pu travailler, et dit pourquoi.
  refused('Refus motivé');

  const PreparationState(this.label);

  /// Étiquette de la pastille sur la carte d'accueil.
  final String label;

  /// Vrai quand la préparation attend une action de l'utilisateur.
  bool get waitsForUser => this == PreparationState.handsBack;
}

/// Une préparation : le message ou l'enseignement en cours de travail.
///
/// Racine de l'agrégat. Le fil de [blocks] est la préparation elle-même — il
/// n'y a pas de « contenu » séparé à côté : ce que l'utilisateur a écrit, les
/// passages convoqués et les synthèses d'Urim s'y succèdent dans l'ordre.
final class Preparation extends Equatable {
  const Preparation({
    required this.id,
    required this.title,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
    this.state = PreparationState.handsBack,
    this.summary = '',
    this.blocks = const [],
    this.recording,
    this.serviceDate,
  });

  final String id;

  /// Titre affiché. Repris du premier bloc à défaut d'être choisi.
  final String title;

  /// Résumé d'une ou deux lignes, affiché sur la carte d'accueil.
  final String summary;

  final PreparationOrigin origin;
  final DateTime createdAt;

  /// Sert au regroupement de l'accueil (« Cette semaine », « Plus tôt ») et
  /// au tri : c'est la dernière activité qui compte, pas la création.
  final DateTime updatedAt;

  /// À qui est la main.
  final PreparationState state;

  final List<PreparationBlock> blocks;

  /// Présent uniquement pour [PreparationOrigin.transcribed].
  final Recording? recording;

  /// Dimanche visé. Nul quand la préparation n'est pas datée : on prépare
  /// aussi sans savoir quand on prêchera.
  final DateTime? serviceDate;

  bool get hasRecording => recording != null;

  /// Dernière synthèse produite, s'il y en a une.
  SynthesisBlock? get latestSynthesis {
    for (final block in blocks.reversed) {
      if (block is SynthesisBlock) return block;
    }
    return null;
  }

  /// Passages convoqués, dans l'ordre d'apparition. Doublons conservés : un
  /// même verset repris plus loin marque une insistance, pas une redite.
  List<ScriptureBlock> get scriptures =>
      blocks.whereType<ScriptureBlock>().toList();

  Preparation copyWith({
    String? title,
    String? summary,
    DateTime? updatedAt,
    PreparationState? state,
    List<PreparationBlock>? blocks,
    Recording? recording,
    DateTime? serviceDate,
  }) =>
      Preparation(
        id: id,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        origin: origin,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        state: state ?? this.state,
        blocks: blocks ?? this.blocks,
        recording: recording ?? this.recording,
        serviceDate: serviceDate ?? this.serviceDate,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        origin,
        createdAt,
        updatedAt,
        state,
        blocks,
        recording,
        serviceDate,
      ];

  @override
  String toString() => 'Preparation($id, ${origin.name}, "$title")';
}
