import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';

/// Manière dont un passage pèse sur une question.
///
/// Consigner qu'un passage *interroge* la piste envisagée a autant de valeur
/// que consigner qu'il la conforte : un discernement qui n'enregistre que ce
/// qui l'arrange n'est pas un discernement.
enum AnchorWeight {
  /// Le passage oriente vers la piste envisagée.
  supports,

  /// Le passage la met en question.
  challenges,

  /// Le passage éclaire le contexte sans trancher.
  informs,
}

/// Rattachement d'un passage biblique à une question pastorale.
///
/// [note] porte le travail réel : non pas le texte du passage, mais ce que
/// celui qui discerne y a vu pour cette question précise.
final class ScriptureAnchor extends Equatable {
  const ScriptureAnchor({
    required this.id,
    required this.questionId,
    required this.ref,
    required this.addedAt,
    this.translationId,
    this.note = '',
    this.weight = AnchorWeight.informs,
  });

  final String id;
  final String questionId;
  final PassageRef ref;

  /// Traduction dans laquelle le passage a été lu. Nulle si la référence
  /// vaut indépendamment de la traduction.
  final String? translationId;

  /// Ce que ce passage éclaire pour cette question.
  final String note;

  final AnchorWeight weight;
  final DateTime addedAt;

  @override
  List<Object?> get props =>
      [id, questionId, ref, translationId, note, weight, addedAt];

  @override
  String toString() => 'ScriptureAnchor(${ref.canonical}, ${weight.name})';
}
