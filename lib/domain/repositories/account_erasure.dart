import 'package:urim/core/result/result.dart';

/// Supprimer son compte et tout son contenu.
///
/// La politique de confidentialité l'écrit noir sur blanc, sous une mention de
/// la loi ivoirienne n° 2013-450 : « Tu peux supprimer ton compte et tout son
/// contenu à tout moment. » Une promesse écrite que le code ne tient pas est un
/// mensonge que l'utilisateur découvre au pire moment.
///
/// Le contrat est sans nuance : **tout**, et non « les données principales ».
/// Une suppression partielle serait plus difficile à expliquer qu'une
/// suppression complète.
abstract interface class AccountErasure {
  /// Efface tout ce que l'application a écrit sur cet appareil.
  ///
  /// Idempotent : supprimer deux fois n'est pas une erreur.
  Future<Result<void>> eraseEverything();
}
