/// Accès à l'heure courante.
///
/// Les cas d'usage qui horodatent (ouverture d'une question, consignation
/// d'une décision) dépendent de cette abstraction plutôt que de
/// `DateTime.now()` : sans elle, leurs tests ne sont pas déterministes.
///
/// Sans import de framework : le domaine en dépend, il doit rester compilable
/// en Dart pur.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
