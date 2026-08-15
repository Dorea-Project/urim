import 'package:equatable/equatable.dart';

/// Un appareil sur lequel la session a été ouverte.
///
/// La politique de confidentialité annonce que ces appareils sont conservés :
/// les montrer, et permettre d'en retirer un, est donc dû.
final class KnownDevice extends Equatable {
  const KnownDevice({
    required this.id,
    required this.label,
    required this.lastActiveAt,
    this.isCurrent = false,
  });

  final String id;

  /// Modèle tel que l'appareil se nomme : « Tecno Spark 8C ».
  final String label;

  final DateTime lastActiveAt;

  /// L'appareil qui affiche l'écran. Il ne peut pas se retirer lui-même : ce
  /// serait une déconnexion déguisée, qui a son propre bouton.
  final bool isCurrent;

  bool get canBeForgotten => !isCurrent;

  @override
  List<Object?> get props => [id, label, lastActiveAt, isCurrent];
}
