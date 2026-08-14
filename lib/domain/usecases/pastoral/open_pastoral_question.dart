import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/pastoral/pastoral_question.dart';
import 'package:urim/domain/repositories/pastoral_question_repository.dart';

final class OpenPastoralQuestionParams extends Equatable {
  const OpenPastoralQuestionParams({
    required this.title,
    this.context = '',
    this.tags = const {},
  });

  final String title;
  final String context;
  final Set<String> tags;

  @override
  List<Object?> get props => [title, context, tags];
}

/// Ouvre une question pastorale au discernement.
final class OpenPastoralQuestion
    implements UseCase<PastoralQuestion, OpenPastoralQuestionParams> {
  const OpenPastoralQuestion(this._repository, this._clock, this._ids);

  final PastoralQuestionRepository _repository;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<PastoralQuestion>> call(
    OpenPastoralQuestionParams params,
  ) async {
    final title = params.title.trim();

    if (title.isEmpty) {
      return const Result.failed(
        ValidationFailure(
          message: 'Une question doit être formulée avant d\'être discernée.',
          code: 'empty_title',
          fieldErrors: {'title': 'Obligatoire'},
        ),
      );
    }

    return _repository.save(
      PastoralQuestion(
        id: _ids.newId(),
        title: title,
        context: params.context.trim(),
        askedAt: _clock.now(),
        tags: params.tags,
      ),
    );
  }
}
