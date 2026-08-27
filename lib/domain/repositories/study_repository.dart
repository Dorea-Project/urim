import 'package:urim/core/result/cached.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/preparation/gesture_outcome.dart';
import 'package:urim/domain/entities/preparation/pending_gesture.dart';
import 'package:urim/domain/entities/bible/passage_detail.dart';
import 'package:urim/domain/entities/preparation/articulation.dart';
import 'package:urim/domain/entities/preparation/preached.dart';
import 'package:urim/domain/entities/preparation/deliverable.dart';
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

  /// Faire articuler **un** point — dans l'atelier, jamais dans le document.
  ///
  /// La seule prose qu'Urim produise, et elle se demande point par point. Elle
  /// vit à côté du plan : elle n'atteint un fichier que si le pasteur la
  /// reprend dans son texte, c'est-à-dire s'il l'a lue.
  ///
  /// ⚠️ **Le point doit être enregistré avant.** Le serveur articule ce qu'il a
  /// en base, désigné par [elementCode] et [ordinal] ; demander sans avoir
  /// envoyé rendrait une proposition sur une phrase déjà remplacée — un défaut
  /// que rien à l'écran ne trahirait.
  ///
  /// Un succès peut porter `available: false` — aucun modèle branché, plafond
  /// atteint, ou point vide. **Ce n'est pas un échec** : l'atelier fonctionne
  /// sans, et le pasteur écrit son point comme il l'a toujours fait.
  /// Faire d'une note **un point du plan** — le seul chemin du fil vers le
  /// document.
  ///
  /// 🔴 **C'est ici que le verrou se tient.** Tout ce qui s'écrit dans le fil
  /// est gardé, rangé, relisible — et n'atteint aucun fichier. Le `.docx`
  /// n'imprime que le plan. Une note ne devient imprimable qu'en passant par ce
  /// geste, que le pasteur seul déclenche.
  ///
  /// ⚠️ **On ajoute, on ne remplace pas.** Sa note est le plus souvent une
  /// remarque *sur* le point — « le deuxième, il faut parler de la loi » — pas
  /// le texte du point.
  ///
  /// [elementCode] et [ordinal] ne servent que si la note n'a pas d'adresse :
  /// elle en a une dès qu'il a désigné un point en écrivant.
  Future<Result<Study>> promote({
    required String studyId,
    required String entryId,
    String? elementCode,
    int? ordinal,
  });

  Future<Result<Articulation>> articulate({
    required String studyId,
    required String elementCode,
    required int ordinal,
  });

  /// « J'ai prêché celle-ci. »
  ///
  /// ⚠️ **Rien ne s'archive parce qu'une date est passée.** C'est un geste du
  /// pasteur, jamais une déduction du calendrier : une préparation datée du
  /// dimanche prochain n'a pas été prêchée pour autant. Le jour par défaut est
  /// **aujourd'hui**, pas la date de culte.
  Future<Result<PreachedSermon>> markPreached({
    required String studyId,
    DateTime? preachedOn,
  });

  /// Consigner une prédication qui n'est pas passée par Urim.
  ///
  /// Sans elle, l'archive ne mesurerait que ce qui est passé par l'outil — et
  /// ce n'est pas la même chose que le ministère de quelqu'un. La [reference]
  /// s'écrit **dans la notation du pasteur** ; c'est le serveur qui la lit.
  Future<Result<PreachedSermon>> recordPreached({
    required String reference,
    required DateTime preachedOn,
    String? axisCode,
    String? theme,
  });

  /// L'archive du prédicateur, la plus récente d'abord.
  Future<Result<List<PreachedSermon>>> listPreached();

  /// Où il est allé dans l'Écriture, et sous quels axes.
  ///
  /// ⚠️ **Des faits, aucune consigne.** Cet écran ne propose jamais de sermon :
  /// un rayon vide se montre, il ne se comble pas.
  Future<Result<PreachingCoverage>> preachingCoverage();

  /// Soumettre ce qui sortira — **et le faire juger avant qu'un fichier
  /// existe**.
  ///
  /// Ce n'est pas un export : c'est une soumission au contrôle. Le serveur
  /// compare chaque citation projetée au corpus, sur toutes les versions
  /// détenues, et rend un dossier de validation. Un rejet n'est pas une erreur,
  /// c'est le seul écran où un verset abîmé se voit **avant** le dimanche.
  Future<Result<Deliverable>> submitDeliverable({
    required String studyId,
    required String kind,
    List<Slide> slides = const [],
  });

  /// Les octets d'un document déjà déclaré conforme.
  Future<Result<DeliverableFile>> downloadDeliverable(String deliverableId);

  /// **En savoir plus sur un passage**, sans ouvrir de préparation.
  ///
  /// Lecture pure. C'est ce qui permet de regarder six textes avant d'en
  /// choisir un, au lieu de s'engager sur chacun pour le lire.
  Future<Result<PassageDetail>> explorePassage(String reference);

  /// Où ce mot de l'original paraît ailleurs.
  ///
  /// Elle montre le texte et ne dit rien du monde : c'est la seule pierre du
  /// module de recherche qui ne puisse rien inventer.
  Future<Result<Concordance>> concordance(String lemma);

  /// Écrire la chaîne de textes d'appui — **les saisies brutes**.
  ///
  /// Le contrôle de référence vit côté serveur, avec le corpus : `Hb 2v29`
  /// revient avec « Hébreux 2 compte 18 versets » plutôt que d'être corrigé en
  /// silence.
  Future<Result<Study>> setSupports({
    required String studyId,
    required List<String> supports,
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
