/// Une valeur, et **quand elle a été reçue**.
///
/// Sert à ne pas mentir. Le moteur rejoue son pipeline à chaque lecture
/// (D28) : ce qu'on a gardé hier soir est ce qu'il disait hier soir, pas ce
/// qu'il dirait maintenant. Afficher l'un pour l'autre sans le dire ferait
/// croire à une réponse fraîche là où il n'y a qu'un souvenir.
///
/// [receivedAt] nul veut dire **frais** : ça vient du serveur, à l'instant.
final class Cached<T> {
  const Cached.fresh(this.value) : receivedAt = null;

  const Cached.at(this.value, this.receivedAt);

  final T value;

  /// L'heure de réception, quand la valeur vient du magasin local.
  final DateTime? receivedAt;

  bool get isStale => receivedAt != null;

  Cached<R> map<R>(R Function(T value) transform) => receivedAt == null
      ? Cached.fresh(transform(value))
      : Cached.at(transform(value), receivedAt);
}
