import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';

/// Accès aux préparations.
///
/// Muet sur le support : les préparations peuvent vivre uniquement sur
/// l'appareil, ou se synchroniser un jour. La politique de confidentialité
/// engage sur le second point — « tes préparations restent à toi » —, ce qui
/// est une contrainte d'implémentation, pas de contrat.
abstract interface class PreparationRepository {
  /// Liste complète, de la plus récemment modifiée à la plus ancienne.
  ///
  /// Un flux : créer une préparation depuis la feuille de création doit la
  /// faire apparaître sur l'accueil sans rechargement.
  Stream<Result<List<Preparation>>> watchPreparations();

  Future<Result<Preparation>> getById(String preparationId);

  Future<Result<Preparation>> save(Preparation preparation);

  Future<Result<void>> delete(String preparationId);

  /// Ajoute un bloc au fil et met à jour la date de dernière activité.
  Future<Result<Preparation>> appendBlock({
    required String preparationId,
    required PreparationBlock block,
  });

  /// Recherche dans les titres, les résumés et le texte des blocs.
  ///
  /// [query] vide renvoie une liste vide plutôt que tout le corpus : le champ
  /// de recherche de l'accueil ne doit pas tout recharger à chaque effacement.
  Future<Result<List<Preparation>>> search(String query);
}
