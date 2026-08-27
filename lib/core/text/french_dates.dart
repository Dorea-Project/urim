/// Noms des mois, en minuscules.
///
/// Réunis ici parce que plusieurs écrans les emploient — l'un en capitales sur
/// les étiquettes du fil, l'autre en toutes lettres sur les appareils. Deux
/// listes finiraient par diverger.
///
/// **Dans `core/` et non plus sous `presentation/`** : le jeu d'exemple en
/// mémoire date lui aussi une prédication, et une couche de données n'a pas à
/// remonter vers la présentation pour nommer un mois.
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

/// Jours de la semaine, abrégés. Index 0 = lundi, comme [DateTime.weekday] — 1.
const List<String> frenchWeekdaysShort = [
  'lun.',
  'mar.',
  'mer.',
  'jeu.',
  'ven.',
  'sam.',
  'dim.',
];

/// « 28 juillet ». Sans l'année : ces dates sont récentes par nature.
String frenchDayMonth(DateTime date) =>
    '${date.day} ${frenchMonths[date.month - 1]}';

/// « sam. 29 août ».
///
/// 🔴 **Le jour était écrit en dur.** La puce du composeur affichait « dim. »
/// quelle que soit la date choisie, et la carte d'accueil « dimanche {date} » :
/// un pasteur qui prêche le mercredi soir lisait « dim. 26 août » sur un
/// mercredi. Le jour se lit dans la date, il ne se suppose pas.
String frenchShortDate(DateTime date) =>
    '${frenchWeekdaysShort[date.weekday - 1]} ${frenchDayMonth(date)}';
