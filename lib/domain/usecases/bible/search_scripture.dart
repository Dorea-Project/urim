import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/bible/verse.dart';
import 'package:urim/domain/repositories/bible_repository.dart';

final class SearchScriptureParams extends Equatable {
  const SearchScriptureParams({
    required this.query,
    required this.translationId,
    this.limit = 50,
  });

  final String query;
  final String translationId;
  final int limit;

  @override
  List<Object?> get props => [query, translationId, limit];
}

/// Recherche plein texte dans une traduction.
///
/// Rejette les requêtes trop courtes avant d'atteindre le dépôt : sur un
/// corpus de cette taille, un ou deux caractères ramènent l'essentiel du
/// texte sans rien apprendre à personne.
final class SearchScripture implements UseCase<List<Verse>, SearchScriptureParams> {
  const SearchScripture(this._repository);

  static const int minimumQueryLength = 3;

  final BibleRepository _repository;

  @override
  Future<Result<List<Verse>>> call(SearchScriptureParams params) async {
    final query = params.query.trim();

    if (query.length < minimumQueryLength) {
      return const Result.failed(
        ValidationFailure(
          message: 'La recherche demande au moins '
              '$minimumQueryLength caractères.',
          code: 'query_too_short',
          fieldErrors: {'query': 'Trop court'},
        ),
      );
    }

    return _repository.search(
      query: query,
      translationId: params.translationId,
      limit: params.limit,
    );
  }
}
