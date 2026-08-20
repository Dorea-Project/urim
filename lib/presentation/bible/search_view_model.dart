import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/bible/passage_detail.dart';

/// Ce que la recherche cherche.
enum SearchMode {
  /// Une référence : « Marc 10:46-52 ».
  passage,

  /// Un mot de l'original : « εἴδωλον ».
  word,
}

/// Regarder dans le corpus **sans ouvrir de préparation**.
///
/// C'est la réponse à deux questions qu'un pasteur pose en séance — *« en
/// savoir plus sur ce livre »*, *« le sens original de ce mot »* — et
/// auxquelles le produit n'avait aucun écran à opposer, alors que le serveur y
/// répondait déjà.
final class SearchViewModel extends Notifier<AsyncValue<Object?>> {
  @override
  AsyncValue<Object?> build() => const AsyncData(null);

  Future<void> search({required SearchMode mode, required String query}) async {
    final saisie = query.trim();
    if (saisie.isEmpty) return;

    state = const AsyncLoading();

    final repository = ref.read(studyRepositoryProvider);
    final result = switch (mode) {
      SearchMode.passage => await repository.explorePassage(saisie),
      SearchMode.word => await repository.concordance(saisie),
    };

    state = result.fold(
      onSuccess: AsyncData<Object?>.new,
      // Le refus du serveur porte sa phrase : « εἴδωλον ne paraît dans aucun
      // texte original de ce corpus » vaut mieux qu'un « introuvable » sec.
      onFailure: (failure) => AsyncError(failure, StackTrace.current),
    );
  }
}

final searchViewModelProvider =
    NotifierProvider<SearchViewModel, AsyncValue<Object?>>(
  SearchViewModel.new,
);

/// Raccourci de lecture : ce que l'écran a reçu, quand il a reçu quelque chose.
PassageDetail? passageOf(AsyncValue<Object?> state) =>
    state.value is PassageDetail ? state.value! as PassageDetail : null;

Concordance? concordanceOf(AsyncValue<Object?> state) =>
    state.value is Concordance ? state.value! as Concordance : null;
