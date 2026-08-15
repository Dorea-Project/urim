import 'package:equatable/equatable.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/pastoral/pastoral_question.dart';
import 'package:urim/domain/repositories/pastoral_question_repository.dart';

final class WatchPastoralQuestionsParams extends Equatable {
  const WatchPastoralQuestionsParams({this.statuses = const {}});

  /// Étapes retenues. Vide signifie « toutes ».
  final Set<DiscernmentStatus> statuses;

  /// Les questions ouvertes ou en cours — ce que l'écran d'accueil du module
  /// décisionnel a vocation à montrer.
  static const active = WatchPastoralQuestionsParams(
    statuses: {DiscernmentStatus.open, DiscernmentStatus.discerning},
  );

  @override
  List<Object?> get props => [statuses];
}

/// Suit la liste des questions, en réagissant aux modifications.
final class WatchPastoralQuestions
    implements
        StreamUseCase<List<PastoralQuestion>, WatchPastoralQuestionsParams> {
  const WatchPastoralQuestions(this._repository);

  final PastoralQuestionRepository _repository;

  @override
  Stream<Result<List<PastoralQuestion>>> call(
    WatchPastoralQuestionsParams params,
  ) =>
      _repository.watchQuestions(statuses: params.statuses);
}
