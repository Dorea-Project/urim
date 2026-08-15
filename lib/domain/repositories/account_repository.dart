import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/account/church_membership.dart';
import 'package:urim/domain/entities/account/known_device.dart';

/// Ce qui entoure l'identité : le nom affiché, les églises, les appareils.
///
/// Le numéro n'est pas ici : il appartient à la session
/// (`AuthRepository.currentSession`). Le dupliquer donnerait deux vérités pour
/// une seule donnée.
abstract interface class AccountRepository {
  /// Nom affiché, chaîne vide s'il n'y en a pas encore.
  Future<Result<String>> displayName();

  Future<Result<void>> setDisplayName(String name);

  /// Églises qui reconnaissent le numéro — jamais choisies depuis Urim (Q9).
  Future<Result<List<ChurchMembership>>> churches();

  Future<Result<List<KnownDevice>>> devices();

  /// Révoque l'accès d'un appareil. Sans effet sur l'appareil courant.
  Future<Result<void>> forgetDevice(String deviceId);
}
