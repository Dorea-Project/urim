/// Noms des mois, en minuscules.
///
/// Réunis ici parce que deux écrans les emploient — l'un en capitales sur les
/// étiquettes du fil, l'autre en toutes lettres sur les appareils. Deux listes
/// finiraient par diverger.
const List<String> frenchMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « 28 juillet ». Sans l'année : ces dates sont récentes par nature.
String frenchDayMonth(DateTime date) =>
    '${date.day} ${frenchMonths[date.month - 1]}';
