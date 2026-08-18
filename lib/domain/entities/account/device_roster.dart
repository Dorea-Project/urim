import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/account/known_device.dart';

/// Les appareils liés au compte, et la place qui reste.
///
/// **Deux au maximum.** Un pasteur a son téléphone, parfois une tablette ; au
/// troisième, ce n'est plus un compte personnel mais un compte prêté — et les
/// préparations sont ce qu'Urim promet de garder à leur auteur.
///
/// La limite est tenue par le serveur, qui seul connaît la liste complète.
/// Ce que le domaine en fait ici, c'est la **rendre lisible avant qu'elle ne
/// se manifeste** : voir « 2 sur 2 » sur son profil vaut mieux que découvrir
/// un refus en pleine connexion sur un téléphone neuf.
final class DeviceRoster extends Equatable {
  const DeviceRoster(this.devices);

  /// Nombre d'appareils qu'un compte peut lier.
  static const int maxDevices = 2;

  final List<KnownDevice> devices;

  int get count => devices.length;

  bool get isFull => count >= maxDevices;

  /// Places restantes. Jamais négatif : le serveur peut en avoir accordé plus
  /// que la règle actuelle, et l'écran ne doit pas afficher « -1 ».
  int get freeSlots => (maxDevices - count).clamp(0, maxDevices);

  /// L'appareil qui affiche l'écran.
  KnownDevice? get current =>
      devices.where((device) => device.isCurrent).firstOrNull;

  /// Ceux qu'on peut libérer. L'appareil courant n'en fait pas partie : le
  /// retirer serait une déconnexion déguisée, qui a son propre bouton.
  List<KnownDevice> get removable =>
      devices.where((device) => device.canBeForgotten).toList();

  /// Peut-on lier un appareil de plus sans rien libérer ?
  bool get acceptsAnother => !isFull;

  @override
  List<Object?> get props => [devices];
}
