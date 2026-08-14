import 'package:equatable/equatable.dart';

/// Décision consignée au terme d'un discernement.
///
/// Immuable une fois enregistrée : revenir sur une décision ne la modifie
/// pas, cela rouvre la question et en consigne une nouvelle. L'historique des
/// décisions successives est précisément ce qui rend le discernement
/// relisible.
final class Decision extends Equatable {
  const Decision({
    required this.id,
    required this.questionId,
    required this.statement,
    required this.decidedAt,
    this.rationale = '',
    this.reviewAt,
  });

  final String id;
  final String questionId;

  /// Ce qui a été décidé, en une phrase.
  final String statement;

  /// Les motifs : ce qui a emporté la décision, y compris ce qui a été écarté.
  final String rationale;

  final DateTime decidedAt;

  /// Échéance de relecture. Une décision pastorale se réévalue ; sans date,
  /// elle ne le sera pas.
  final DateTime? reviewAt;

  bool get hasReview => reviewAt != null;

  /// Vrai si l'échéance de relecture est atteinte à [now].
  bool isDueForReview(DateTime now) =>
      reviewAt != null && !now.isBefore(reviewAt!);

  @override
  List<Object?> get props =>
      [id, questionId, statement, rationale, decidedAt, reviewAt];

  @override
  String toString() => 'Decision($id, question: $questionId)';
}
