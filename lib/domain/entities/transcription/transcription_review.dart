import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/preparation/recording.dart';

/// Comment un texte est apparu dans la prédication.
enum ConvocationKind {
  /// La référence a été annoncée : « ouvrons Hébreux 13 ».
  announced,

  /// Le texte a été cité sans être annoncé — reconnu à l'ordre des mots.
  recognizedInQuote,
}

/// Un texte convoqué pendant la prédication.
///
/// [wasPlanned] est la seule information qui vaille ici : Urim ne juge pas la
/// prédication, il constate l'écart entre ce qui était préparé et ce qui a été
/// dit.
final class ConvokedScripture extends Equatable {
  const ConvokedScripture({
    required this.passage,
    required this.at,
    required this.kind,
    required this.wasPlanned,
  });

  final QuotedPassage passage;

  /// Position dans l'enregistrement.
  final Duration at;

  final ConvocationKind kind;
  final bool wasPlanned;

  @override
  List<Object?> get props => [passage, at, kind, wasPlanned];
}

/// Une observation d'Urim après coup : un constat, un alignement au squelette.
///
/// Le texte dit ce qu'Urim sait et **ce qu'il ne sait pas** — « je sais
/// seulement que je ne l'ai pas entendu ». Un constat qui déborderait de ce
/// qui a été mesuré deviendrait un jugement sur la prédication.
final class TranscriptionRemark extends Equatable {
  const TranscriptionRemark({required this.label, required this.body});

  /// « CONSTAT », « ALIGNEMENT AU SQUELETTE ».
  final String label;

  final String body;

  @override
  List<Object?> get props => [label, body];
}

/// Ce qu'il reste d'une prédication transcrite.
final class TranscriptionReview extends Equatable {
  const TranscriptionReview({
    required this.preparationId,
    required this.title,
    required this.recording,
    this.convoked = const [],
    this.remarks = const [],
  });

  final String preparationId;

  /// « Hébreux 13 — 9 août ».
  final String title;

  final Recording recording;
  final List<ConvokedScripture> convoked;
  final List<TranscriptionRemark> remarks;

  /// Textes venus sans avoir été prévus.
  List<ConvokedScripture> get unplanned =>
      convoked.where((scripture) => !scripture.wasPlanned).toList();

  @override
  List<Object?> get props =>
      [preparationId, title, recording, convoked, remarks];
}
