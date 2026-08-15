import 'dart:math';

/// Fabrique d'identifiants pour les entités créées côté client.
///
/// Abstraite pour la même raison que `Clock` : un test qui vérifie une entité
/// créée a besoin d'un identifiant prévisible. Sans import de framework — le
/// domaine en dépend.
abstract interface class IdGenerator {
  String newId();
}

/// Implémentation par défaut : horodatage en microsecondes suffixé d'un
/// tirage aléatoire.
///
/// Suffisant tant que les identifiants sont produits et consommés localement.
/// Le jour où deux appareils créeront des entités hors ligne avant de se
/// synchroniser, passer à un UUID v4 — ce fichier est le seul à changer.
final class LocalIdGenerator implements IdGenerator {
  LocalIdGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  String newId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$stamp-$salt';
  }
}
