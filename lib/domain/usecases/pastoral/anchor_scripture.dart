import 'package:equatable/equatable.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';
import 'package:urim/domain/entities/pastoral/pastoral_question.dart';
import 'package:urim/domain/entities/pastoral/scripture_anchor.dart';
import 'package:urim/domain/repositories/pastoral_question_repository.dart';

final class AnchorScriptureParams extends Equatable {
  const AnchorScriptureParams({
    required this.questionId,
    required this.ref,
    this.translationId,
    this.note = '',
    this.weight = AnchorWeight.informs,
  });

  final String questionId;
  final PassageRef ref;
  final String? translationId;
  final String note;
  final AnchorWeight weight;

  @override
  List<Object?> get props => [questionId, ref, translationId, note, weight];
}

/// Rattache un passage biblique à une question.
///
/// Rattacher un passage, c'est engager le discernement : une question encore
/// `open` bascule pour cette seule raison en `discerning`. Les autres étapes
/// sont laissées telles quelles — une question déjà décidée peut recevoir un
/// passage supplémentaire sans être rouverte à son insu.
final class AnchorScripture
    implements UseCase<ScriptureAnchor, AnchorScriptureParams> {
  const AnchorScripture(this._repository, this._clock, this._ids);

  final PastoralQuestionRepository _repository;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<ScriptureAnchor>> call(AnchorScriptureParams params) async {
    final PastoralQuestion question;
    switch (await _repository.getById(params.questionId)) {
      case Failed(:final failure):
        return Result.failed(failure);
      case Success(:final value):
        question = value;
    }

    final anchorResult = await _repository.addAnchor(
      ScriptureAnchor(
        id: _ids.newId(),
        questionId: question.id,
        ref: params.ref,
        translationId: params.translationId,
        note: params.note.trim(),
        weight: params.weight,
        addedAt: _clock.now(),
      ),
    );

    if (anchorResult case Failed(:final failure)) {
      return Result.failed(failure);
    }

    if (question.status == DiscernmentStatus.open) {
      // L'échec de cette mise à jour ne doit pas masquer le rattachement, qui
      // lui a réussi : l'étape se rattrapera à la prochaine action.
      await _repository.save(
        question.copyWith(status: DiscernmentStatus.discerning),
      );
    }

    return anchorResult;
  }
}
