import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/security/token_store.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/domain/repositories/account_erasure.dart';

/// Efface tout ce qu'Urim a écrit sur cet appareil.
///
/// Trois magasins, et un seul survivant délibéré.
///
/// | Ce qui part | Où |
/// |---|---|
/// | Brouillons, tours gardés, gestes en attente | fichiers (`LocalDocuments`) |
/// | Session, profil, réglages, code secret, présentation vue | préférences |
/// | Jetons d'accès | coffre matériel |
///
/// ## Ce qui reste, et pourquoi
///
/// **L'identité de l'appareil.** Elle vit dans le coffre à côté des jetons,
/// mais elle n'est pas du contenu : c'est le nom de ce téléphone auprès du
/// serveur. L'effacer ferait passer le même appareil pour un neuf à la
/// reconnexion — il consommerait une **seconde place sur deux** (D45), et
/// l'ancienne resterait occupée par un fantôme que personne ne peut retirer.
///
/// ## Ce que cette suppression ne fait pas
///
/// Elle est **locale**. Le serveur n'expose aucune résiliation : ni
/// `AuthRepository`, ni `StudyRepository` n'ont de quoi supprimer un compte.
/// Le dialogue doit donc le dire plutôt que le taire. Le jour où l'appel
/// existera, il partira d'ici, et l'écran devra distinguer laquelle des deux
/// suppressions a réussi.
final class LocalAccountErasure implements AccountErasure {
  const LocalAccountErasure({
    required SharedPreferences preferences,
    required LocalDocuments documents,
    required TokenStore tokens,
  })  : _preferences = preferences,
        _documents = documents,
        _tokens = tokens;

  final SharedPreferences _preferences;
  final LocalDocuments _documents;
  final TokenStore _tokens;

  @override
  Future<Result<void>> eraseEverything() async {
    try {
      // Les fichiers d'abord. Si l'effacement s'arrête en chemin, mieux vaut
      // une application qui retrouve encore son compte qu'une application
      // vidée pointant sur des brouillons orphelins.
      for (final key in await _documents.keys()) {
        await _documents.delete(key);
      }

      // Les préférences en bloc, sans liste de clés : la tenir à jour est un
      // travail qu'on oublie, et une suppression qui oublie une clé est pire
      // qu'une suppression totale — elle laisse croire que tout est parti.
      await _preferences.clear();

      // Les jetons seuls : `clear` ne touche que `auth.tokens.v1`, et
      // l'identité de l'appareil reste au coffre.
      await _tokens.clear();

      return const Result.success(null);
    } on Object catch (error) {
      return Result.failed(
        CacheFailure(
          message: 'Une partie du contenu n\'a pas pu être effacée : $error',
          code: 'erasure_incomplete',
        ),
      );
    }
  }
}

final accountErasureProvider = Provider<AccountErasure>(
  (ref) => LocalAccountErasure(
    preferences: ref.watch(sharedPreferencesProvider),
    documents: ref.watch(localDocumentsProvider),
    tokens: ref.watch(tokenStoreProvider),
  ),
);
