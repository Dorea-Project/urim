import 'package:equatable/equatable.dart';

/// Numéro de téléphone, séparé en indicatif et numéro national.
///
/// Les deux restent distincts jusqu'au bout : l'écran les saisit dans deux
/// champs, et les recoller trop tôt obligerait à les redécouper pour
/// réafficher.
final class PhoneNumber extends Equatable {
  const PhoneNumber({required this.dialCode, required this.nationalNumber});

  /// Indicatif avec le `+` : `+225`.
  final String dialCode;

  /// Numéro sans indicatif, chiffres uniquement.
  final String nationalNumber;

  /// Indicatif par défaut : Côte d'Ivoire.
  static const String defaultDialCode = '+225';

  /// Longueur d'un numéro national ivoirien depuis la renumérotation de 2021.
  static const int ivorianLength = 10;

  /// Retire espaces, points et tirets — les gens les saisissent, les serveurs
  /// les refusent.
  static String normalize(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '');

  /// Forme attendue par les passerelles SMS : `+2250747769069`.
  String get e164 => '$dialCode$nationalNumber';

  bool get isValid {
    if (!RegExp(r'^\+\d{1,4}$').hasMatch(dialCode)) return false;
    if (!RegExp(r'^\d+$').hasMatch(nationalNumber)) return false;

    // Hors Côte d'Ivoire, on se contente d'une fourchette large : valider
    // finement chaque plan de numérotation national demanderait une
    // bibliothèque dédiée, et ce n'est pas ce qui protège l'inscription —
    // c'est la réception effective du SMS.
    if (dialCode == defaultDialCode) {
      return nationalNumber.length == ivorianLength;
    }
    return nationalNumber.length >= 6 && nationalNumber.length <= 14;
  }

  @override
  List<Object?> get props => [dialCode, nationalNumber];

  @override
  String toString() => e164;
}
