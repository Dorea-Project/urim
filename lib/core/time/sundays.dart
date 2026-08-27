/// Les dimanches autour d'une date.
///
/// ⚠️ **Ce fichier ne sert plus qu'au jeu d'exemple**, et c'est délibéré.
/// L'application, elle, ne suppose plus de jour de culte : la date proposée à
/// l'ouverture d'une préparation vient de `nextService`, qui déduit le jour de
/// l'assemblée de ses prédications déjà captées — un pasteur ne prêche pas que
/// le dimanche. Il y avait ici un `nextSunday` qui servait de proposition par
/// défaut ; il imposait un dimanche à qui se réunit le mercredi soir.
///
/// Ce qui reste est le besoin du jeu de démonstration : dater sa prédication
/// d'exemple du dimanche précédent, pour que les deux branches de la règle
/// d'ouverture (D50) se rejouent à leur tour dans la semaine.
library;

/// Le dimanche précédent, **strictement** : aujourd'hui n'en est jamais un.
///
/// C'est ce que veut dire « dimanche dernier » quand on est dimanche : le culte
/// d'aujourd'hui n'a pas encore eu lieu.
DateTime lastSunday(DateTime from) {
  final day = DateTime(from.year, from.month, from.day);
  final since = day.weekday % DateTime.daysPerWeek;

  return day.subtract(
    Duration(days: since == 0 ? DateTime.daysPerWeek : since),
  );
}
