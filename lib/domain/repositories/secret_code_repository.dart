import 'package:urim/core/result/result.dart';

/// Code secret local, demandé à chaque ouverture de l'application.
///
/// Il ne remplace pas l'authentification : le SMS prouve qui vous êtes auprès
/// du serveur, le code secret protège l'appareil entre deux usages. Perdre le
/// code n'est donc pas perdre le compte — on repasse par le SMS.
abstract interface class SecretCodeRepository {
  /// Un code a-t-il déjà été défini sur cet appareil ?
  Future<Result<bool>> hasSecretCode();

  /// Enregistre le code. **Ne stocke jamais le code lui-même.**
  Future<Result<void>> defineSecretCode(String code);

  /// Vrai si le code correspond.
  ///
  /// Échoue avec un code `too_many_attempts` lorsque le nombre d'essais
  /// consécutifs est dépassé : sans ce garde-fou, quatre chiffres se
  /// parcourent en entier en quelques minutes.
  Future<Result<bool>> verifySecretCode(String code);

  /// Efface le code — à la déconnexion, ou après épuisement des essais.
  Future<Result<void>> clearSecretCode();
}
