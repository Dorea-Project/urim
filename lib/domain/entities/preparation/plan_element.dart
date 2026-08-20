import 'package:equatable/equatable.dart';

/// Une section du plan, écrite par le pasteur.
///
/// Le squelette propose un ordre ; il n'impose aucun texte. Une section vide
/// est un état normal — le document le dit lui-même : « le document met en page
/// ce que vous aurez écrit, il ne l'écrit pas à votre place ».
final class PlanElement extends Equatable {
  const PlanElement({
    required this.code,
    required this.ordinal,
    this.body,
  });

  /// Le code de section, dans la liste fermée du serveur — [PlanSkeleton].
  final String code;

  /// L'ordre dans lequel la section paraît. Plusieurs sections peuvent porter
  /// le même code : trois divisions, c'est trois lignes.
  final int ordinal;

  final String? body;

  bool get isEmpty => (body ?? '').trim().isEmpty;

  PlanElement copyWith({String? body}) =>
      PlanElement(code: code, ordinal: ordinal, body: body ?? this.body);

  @override
  List<Object?> get props => [code, ordinal, body];
}

/// Les sections que le serveur accepte, dans l'ordre où l'écran les propose.
///
/// ⚠️ **La liste est fermée côté serveur**, et cette copie doit lui rester
/// fidèle : un code hors liste ne s'enregistre pas, et le refus nomme la liste.
/// Elle s'élargira — c'est prévu — mais jamais par accident.
abstract final class PlanSkeleton {
  const PlanSkeleton._();

  /// Les dix de Braga, dans l'ordre canonique.
  static const List<String> braga = [
    'titre',
    'introduction',
    'proposition',
    'phrase_interrogative',
    'phrase_de_transition',
    'divisions',
    'subdivisions',
    'illustrations',
    'application',
    'conclusion',
  ];

  /// Ce que les prédications réelles portent en plus, et que Braga ne nomme
  /// pas. Elles ne s'affichent pas d'office : le pasteur les ajoute s'il les
  /// tient.
  static const List<String> observees = [
    'objectif',
    'contexte',
    'definitions',
    'nb',
    'temoignage',
  ];

  static const List<String> toutes = [...braga, ...observees];

  /// La section que le livrable exige avant de produire un document : un point
  /// du plan, écrit par le pasteur.
  static const String pointCentral = 'divisions';
}
