import 'package:equatable/equatable.dart';

/// Une église qui reconnaît le numéro de l'utilisateur.
///
/// Le rattachement ne vient pas d'Urim : c'est un annuaire tenu ailleurs qui
/// reconnaît un numéro (Q9). D'où l'absence de tout verbe d'action ici — on ne
/// rejoint pas une église depuis cet écran, on constate qu'on y est reconnu.
///
/// **Une adhésion ne donne accès à rien.** Les préparations ne traversent
/// jamais vers l'église ; cette entité ne porte donc ni rôle, ni permission,
/// et il faudra une décision explicite pour lui en ajouter.
final class ChurchMembership extends Equatable {
  const ChurchMembership({
    required this.id,
    required this.name,
    required this.locality,
  });

  final String id;

  /// « Église Béthel ».
  final String name;

  /// Commune ou quartier : « Yopougon ». Deux assemblées portent souvent le
  /// même nom dans deux communes.
  final String locality;

  /// « Église Béthel — Yopougon ».
  String get label => '$name — $locality';

  @override
  List<Object?> get props => [id, name, locality];
}
