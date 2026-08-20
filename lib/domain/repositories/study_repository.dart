import 'package:urim/core/result/cached.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/preparation/gesture_outcome.dart';
import 'package:urim/domain/entities/preparation/pending_gesture.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';

/// Le moteur Urim, vu du domaine.
///
/// Quatre gestes seulement, et ils disent le produit. On **ouvre**, on
/// **décide**, on **écarte**, on **parle**. Il n'y a pas de « sauvegarder » :
/// chaque geste est déjà une décision persistée, et le fil se refabrique à
/// partir d'elles.
///
/// Chaque geste rend la préparation entière avec son tour courant — jamais un
/// fragment à recoller. C'est ce qui garantit que l'écran ne peut pas afficher
/// un tour d'un côté et un état de l'autre.
abstract interface class StudyRepository {
  /// Le fil du pasteur : ses préparations, la plus fraîchement touchée en tête.
  ///
  /// Clé sur l'auteur, jamais sur l'église : une préparation ouverte sans
  /// assemblée appartient au même fil que celle ouverte sous une église. C'est
  /// un seul homme qui prépare.
  Future<Result<List<StudySummary>>> listMine();

  /// Ouvrir. Le moteur tourne jusqu'à ce qu'il ait besoin du pasteur.
  ///
  /// Sans église : préparer n'exige rien d'autre que d'être authentifié, et il
  /// n'y a personne à qui demander l'autorisation.
  Future<Result<Study>> open({required String rawInput, DateTime? serviceDate});

  /// Relire. La trace est **rejouée**, jamais relue d'un journal.
  Future<Result<Study>> getById(String studyId);

  /// Ce que l'appareil a gardé de la dernière lecture, ou nul.
  ///
  /// Rendu **immédiatement**, sans réseau. C'est ce qui remplace huit secondes
  /// de blanc par un écran, et un écran vide par un écran quand il n'y a pas de
  /// réseau du tout.
  ///
  /// Le [Cached] porte l'heure de réception, et l'appelant doit la dire : le
  /// moteur rejoue à chaque lecture (D28), donc ce qui a été gardé hier soir
  /// est ce qu'il disait hier soir. Ne pas le dire serait faire passer un
  /// souvenir pour une réponse.
  Future<Cached<Study>?> cachedById(String studyId);

  /// Idem pour le fil.
  Future<Cached<List<StudySummary>>?> cachedFeed();

  /// Répondre à un étage qui rend la main. Le pipeline repart du début.
  ///
  /// [stageCode] n'est pas toujours celui du tour : les pesées portent le leur
  /// (`decideStage`). Le poster au mauvais étage vaut un refus du serveur.
  ///
  /// Trois issues, et la troisième est nouvelle : sans réseau, le geste est
  /// **noté** ([Queued]) au lieu d'être perdu. Un refus du serveur, lui, reste
  /// un échec — le renvoyer plus tard ne le rendrait pas acceptable.
  Future<Result<GestureOutcome>> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
    String label = '',
  });

  /// Écarter une option. Elle reste dans la liste, marquée et reléguée.
  ///
  /// Écarter n'est pas décider : aucun étage n'avance. Cela apprend seulement
  /// au tour suivant de ne pas reproposer ce qu'on vient de repousser — sans
  /// quoi un moteur qui rejoue n'a aucun moyen de s'en souvenir.
  Future<Result<GestureOutcome>> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  });

  /// Parler. Une phrase libre, pas un code d'option.
  ///
  /// Aucun étage dans la demande, et c'est ce qui distingue ce geste d'une
  /// décision : le pasteur parle, il ne remplit pas un formulaire. L'étage, le
  /// serveur le connaît.
  /// Trois issues comme les autres gestes : sans réseau, la parole est notée
  /// avec une **clé d'idempotence** que le serveur reconnaîtra. Sans elle, la
  /// renvoyer coûterait un second passage du répondeur.
  Future<Result<GestureOutcome>> say({
    required String studyId,
    required String rawInput,
  });

  /// Écrire le squelette homilétique — **l'envoi remplace l'ensemble**.
  ///
  /// Le serveur n'a pas de geste « effacer une section » : ce qui n'est pas
  /// envoyé n'existe plus. L'écran envoie donc tout ce qu'il montre.
  ///
  /// Pas de file d'attente ici, contrairement aux trois gestes du fil : écrire
  /// son plan hors réseau et le croire parti serait pire que d'attendre. Le
  /// brouillon local, lui, garde la frappe.
  Future<Result<Study>> setElements({
    required String studyId,
    required List<PlanElement> elements,
  });

  /// Les gestes en attente d'envoi pour cette préparation, dans l'ordre.
  ///
  /// L'écran s'en sert pour dire ce qui n'est pas encore parti. Tous portent sur
  /// le **même tour** — on ne peut pas agir sur un tour qu'on n'a pas reçu.
  Future<List<PendingGesture>> pending(String studyId);

  /// Renvoie ce qui attend, dans l'ordre d'émission.
  ///
  /// Rend la préparation à jour si quelque chose est parti, nul s'il n'y avait
  /// rien à envoyer, et une `Failure` si le réseau manque encore. S'arrête au
  /// premier refus : rejouer la suite d'une décision refusée poserait des
  /// gestes sur un état qui n'est pas celui qu'on croyait.
  Future<Result<Study>?> flush(String studyId);
}
