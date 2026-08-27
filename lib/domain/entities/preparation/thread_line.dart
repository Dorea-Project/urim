import 'package:equatable/equatable.dart';

/// Une ligne du fil — **ce qui s'est dit, et qui ne se rejoue pas**.
///
/// 🔴 **Le défaut qu'elle répare, signalé le 23/08/2026 :** *« le fil de
/// discussion disparaît lorsqu'on revient dans la discussion »*. L'écran n'y
/// était pour rien — il affichait tout ce qu'il avait. Le serveur ne gardait
/// que la saisie d'ouverture ; le reste vivait en mémoire et mourait avec elle.
///
/// Tout le reste de la préparation se **rejoue** : les pesées, les couples, les
/// options se recalculent à chaque lecture, et c'est ce qui rend la trace
/// fiable. Ces paroles-là, non — elles ont été dites une fois, par un modèle,
/// à un instant. Elles sont donc lues, pas reconstruites.
final class ThreadLine extends Equatable {
  const ThreadLine({
    required this.id,
    required this.speaker,
    required this.body,
    this.elementCode,
    this.elementOrdinal,
    this.promue = false,
  });

  final String id;

  /// `pasteur` ou `urim`. Fermé côté serveur : un troisième locuteur se décide.
  final String speaker;
  final String body;

  /// Sous quel point le pasteur l'a posée, s'il l'a désigné — « le deuxième »,
  /// « point 3 », ou les mots du point.
  ///
  /// ⚠️ Nul est un **état normal**, pas un manque. Le fondateur l'a dit :
  /// *« ça peut être point ou pas, il peut mettre une pause et revenir
  /// changer »*. Une phrase sans adresse attend ; elle se rangera plus tard.
  final String? elementCode;
  final int? elementOrdinal;

  /// A-t-elle été reprise comme point du plan ?
  ///
  /// ⚠️ **C'est ce qui décide de ce que le document imprime.** Tant que c'est
  /// faux, cette phrase n'atteint aucun fichier — le `.docx` n'imprime que le
  /// plan du pasteur.
  final bool promue;

  bool get estDuPasteur => speaker == 'pasteur';

  /// Une note posée sous un point, que le pasteur n'a pas encore reprise.
  bool get attendSaPromotion => estDuPasteur && elementCode != null && !promue;

  @override
  List<Object?> get props => [id, speaker, body, elementCode, elementOrdinal, promue];
}
