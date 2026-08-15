import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/repositories/secret_code_repository.dart';

/// Vérifie le code secret saisi à l'ouverture.
///
/// Renvoie `false` pour un code erroné — ce n'est pas une panne, c'est une
/// réponse. Une `Failure` n'apparaît que si la vérification elle-même est
/// impossible, ou si les essais sont épuisés.
final class VerifySecretCode implements UseCase<bool, String> {
  const VerifySecretCode(this._repository);

  final SecretCodeRepository _repository;

  @override
  Future<Result<bool>> call(String code) =>
      _repository.verifySecretCode(code.trim());
}
