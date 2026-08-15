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
    this.summary = '',
    this.blocks = const [],
    this.recording,
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

  final List<PreparationBlock> blocks;

  /// Présent uniquement pour [PreparationOrigin.transcribed].
  final Recording? recording;

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
    List<PreparationBlock>? blocks,
    Recording? recording,
  }) =>
      Preparation(
        id: id,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        origin: origin,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        blocks: blocks ?? this.blocks,
        recording: recording ?? this.recording,
      );

  @override
  List<Object?> get props =>
      [id, title, summary, origin, createdAt, updatedAt, blocks, recording];

  @override
  String toString() => 'Preparation($id, ${origin.name}, "$title")';
}
