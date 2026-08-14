import 'package:equatable/equatable.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';
import 'package:urim/domain/entities/bible/verse.dart';
import 'package:urim/domain/repositories/bible_repository.dart';

final class GetPassageParams extends Equatable {
  const GetPassageParams({required this.ref, required this.translationId});

  final PassageRef ref;
  final String translationId;

  @override
  List<Object?> get props => [ref, translationId];
}

/// Lit un passage dans une traduction donnée.
final class GetPassage implements UseCase<Passage, GetPassageParams> {
  const GetPassage(this._repository);

  final BibleRepository _repository;

  @override
  Future<Result<Passage>> call(GetPassageParams params) =>
      _repository.getPassage(
        ref: params.ref,
        translationId: params.translationId,
      );
}
