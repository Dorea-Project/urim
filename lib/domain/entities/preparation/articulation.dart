import 'package:equatable/equatable.dart';

/// Ce qu'Urim propose pour un point que le pasteur a **déjà écrit**.
///
/// C'est la seule prose que le produit fabrique, et elle se demande point par
/// point. Ce qui la rend acceptable n'est pas une promesse mais le chemin des
/// données : le document n'imprime que ce que le pasteur a écrit dans son
/// plan. Cette proposition vit à côté, et n'atteint un fichier que s'il la
/// reprend — c'est-à-dire s'il l'a lue.
///
/// ⚠️ **Elle ne s'insère jamais toute seule.** Un texte qui arrive dans le
/// champ sans qu'on l'ait demandé est un texte que le pasteur n'a pas écrit et
/// qu'il croira sien trois semaines plus tard.
final class Articulation extends Equatable {
  const Articulation({
    required this.body,
    required this.transition,
    required this.model,
    required this.available,
  });

  /// L'atelier sans modèle : aucune clé branchée, plafond atteint, ou point
  /// vide.
  ///
  /// **Ce n'est pas une erreur**, et l'écran ne doit pas la traiter comme
  /// telle : le pasteur écrit son point comme il l'a toujours fait.
  const Articulation.indisponible()
      : body = '',
        transition = '',
        model = '',
        available = false;

  /// Le développement proposé pour ce point.
  final String body;

  /// La phrase qui mène au point suivant, quand le modèle en propose une.
  final String transition;

  /// Le modèle qui l'a écrite. **Il voyage avec le texte** : une proposition
  /// sans son auteur ressemblerait, dans six mois, à quelque chose que
  /// quelqu'un a écrit.
  final String model;

  final bool available;

  /// Disponible, mais sans un mot — le cas ne devrait pas se produire, et
  /// l'écran ne doit pas ouvrir une feuille vide s'il se produit quand même.
  bool get isEmpty => body.trim().isEmpty && transition.trim().isEmpty;

  /// Ce que le pasteur reprend s'il la reprend : le corps, puis la transition.
  String get reprise => [
        if (body.trim().isNotEmpty) body.trim(),
        if (transition.trim().isNotEmpty) transition.trim(),
      ].join('\n\n');

  @override
  List<Object?> get props => [body, transition, model, available];
}
