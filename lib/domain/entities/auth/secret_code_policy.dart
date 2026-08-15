/// Règles auxquelles un code secret doit satisfaire.
///
/// Rassemblées dans le domaine, et non dans l'écran de saisie : le même code
/// est vérifié à la définition et à la modification, et deux implémentations
/// finiraient par diverger.
abstract final class SecretCodePolicy {
  const SecretCodePolicy._();

  /// Longueur imposée. Un seul endroit à changer pour passer à 6 chiffres.
  static const int length = 4;

  /// Rejette les suites et les répétitions.
  ///
  /// Ce ne sont que quelques combinaisons sur dix mille, mais ce sont celles
  /// qu'un inconnu essaie en premier — et de loin les plus choisies.
  static bool isTrivial(String code) {
    if (code.isEmpty) return true;

    final digits = code.split('').map(int.tryParse).toList();
    if (digits.any((d) => d == null)) return true;

    final allSame = code.split('').toSet().length == 1;
    if (allSame) return true;

    var ascending = true;
    var descending = true;
    for (var i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i - 1]! + 1) ascending = false;
      if (digits[i] != digits[i - 1]! - 1) descending = false;
    }

    return ascending || descending;
  }

  static bool hasValidShape(String code) =>
      code.length == length && RegExp(r'^\d+$').hasMatch(code);

  /// Nombre d'essais consécutifs avant blocage.
  static const int maxAttempts = 5;
}
