import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Ce que l'application sait de son utilisateur.
///
/// Un numéro, et un nom que l'utilisateur se donne. Rien d'autre : Urim ne
/// collecte ni adresse, ni fonction, ni église choisie — le rattachement à une
/// église vient d'ailleurs (Q9).
///
/// Le nom peut être vide : l'inscription ne le demande pas encore (Q6). Les
/// écrans doivent donc tenir sans lui, et non l'inventer.
final class UserProfile extends Equatable {
  const UserProfile({required this.phone, this.displayName = ''});

  final PhoneNumber phone;

  /// Nom que l'utilisateur a choisi d'afficher. Vide tant qu'il n'en a pas
  /// donné.
  final String displayName;

  bool get hasDisplayName => displayName.trim().isNotEmpty;

  /// Ce que l'écran met en titre : le nom s'il existe, le numéro sinon.
  String get title => hasDisplayName ? displayName.trim() : phone.e164;

  /// Monogramme, deux lettres au plus : « Kouadio Aristide » donne « KA ».
  ///
  /// Vide si le nom l'est — l'écran affiche alors une silhouette plutôt que
  /// deux initiales tirées d'un numéro.
  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    final letters = words.take(2).map((word) => word[0].toUpperCase());

    return letters.join();
  }

  UserProfile copyWith({PhoneNumber? phone, String? displayName}) =>
      UserProfile(
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
      );

  @override
  List<Object?> get props => [phone, displayName];
}
