import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/pastoral/decision.dart';
import 'package:urim/domain/entities/pastoral/pastoral_question.dart';
import 'package:urim/domain/repositories/pastoral_question_repository.dart';

final class RecordDecisionParams extends Equatable {
  const RecordDecisionParams({
    required this.questionId,
    required this.statement,
    this.rationale = '',
    this.reviewAt,
  });

  final String questionId;
  final String statement;
  final String rationale;
  final DateTime? reviewAt;

  @override
  List<Object?> get props => [questionId, statement, rationale, reviewAt];
}

/// Consigne la décision qui clôt un discernement.
///
/// La décision s'ajoute à l'historique de la question, elle ne remplace pas
/// la précédente : une question rouverte puis redécidée conserve les deux, ce
/// qui est précisément ce qui rend le cheminement relisible.
final class RecordDecision implements UseCase<Decision, RecordDecisionParams> {
  const RecordDecision(this._repository, this._clock, this._ids);

  final PastoralQuestionRepository _repository;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<Decision>> call(RecordDecisionParams params) async {
    final statement = params.statement.trim();

    if (statement.isEmpty) {
      return const Result.failed(
        ValidationFailure(
          message: 'Une décision doit être énoncée.',
          code: 'empty_statement',
          fieldErrors: {'statement': 'Obligatoire'},
        ),
      );
    }

    final PastoralQuestion question;
    switch (await _repository.getById(params.questionId)) {
      case Failed(:final failure):
        return Result.failed(failure);
      case Success(:final value):
        question = value;
    }

    if (!question.canTransitionTo(DiscernmentStatus.decided)) {
      return Result.failed(
        ValidationFailure(
          message: 'Une question à l\'étape « ${question.status.name} » ne '
              'peut pas être décidée en l\'état.',
          code: 'invalid_transition',
        ),
      );
    }

    final decisionResult = await _repository.addDecision(
      Decision(
        id: _ids.newId(),
        questionId: question.id,
        statement: statement,
        rationale: params.rationale.trim(),
        decidedAt: _clock.now(),
        reviewAt: params.reviewAt,
      ),
    );

    if (decisionResult case Failed(:final failure)) {
      return Result.failed(failure);
    }

    // La question n'est close qu'une fois la décision effectivement écrite :
    // l'inverse laisserait une question « décidée » sans décision.
    final statusResult = await _repository.save(
      question.copyWith(status: DiscernmentStatus.decided),
    );

    if (statusResult case Failed(:final failure)) {
      return Result.failed(failure);
    }

    return decisionResult;
  }
}
