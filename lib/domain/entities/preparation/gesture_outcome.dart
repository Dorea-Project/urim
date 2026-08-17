import 'package:urim/domain/entities/preparation/study.dart';

/// Ce qu'un geste a donné.
///
/// Trois issues et non deux, parce qu'il y en a vraiment trois. Le serveur a
/// répondu ; le serveur a **refusé** — et c'est un échec, porté par la
/// `Failure` ; ou personne n'a répondu, et le geste est **noté pour plus tard**.
///
/// La troisième ne peut pas être un succès déguisé : l'écran doit dire que le
/// moteur n'a pas encore parlé. Ni un échec : rien n'est perdu.
sealed class GestureOutcome {
  const GestureOutcome();
}

/// Le moteur a répondu, et voici où en est la préparation.
final class Served extends GestureOutcome {
  const Served(this.study);

  final Study study;
}

/// Pas de réseau : le geste est gardé, dans l'ordre.
///
/// **Aucun tour ne l'accompagne, et c'est le point dur de l'étape.** Le tour
/// suivant est ce que le pipeline aurait répondu ; le fabriquer côté client
/// serait inventer une phrase d'Urim. L'écran dit donc « noté, en attente » et
/// garde le tour précédent sous les yeux.
final class Queued extends GestureOutcome {
  const Queued();
}
