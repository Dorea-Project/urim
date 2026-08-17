import 'package:urim/core/result/result.dart';
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

  /// Répondre à un étage qui rend la main. Le pipeline repart du début.
  ///
  /// [stageCode] n'est pas toujours celui du tour : les pesées portent le leur
  /// (`decideStage`). Le poster au mauvais étage vaut un refus du serveur.
  Future<Result<Study>> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
  });

  /// Écarter une option. Elle reste dans la liste, marquée et reléguée.
  ///
  /// Écarter n'est pas décider : aucun étage n'avance. Cela apprend seulement
  /// au tour suivant de ne pas reproposer ce qu'on vient de repousser — sans
  /// quoi un moteur qui rejoue n'a aucun moyen de s'en souvenir.
  Future<Result<Study>> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  });

  /// Parler. Une phrase libre, pas un code d'option.
  ///
  /// Aucun étage dans la demande, et c'est ce qui distingue ce geste d'une
  /// décision : le pasteur parle, il ne remplit pas un formulaire. L'étage, le
  /// serveur le connaît.
  Future<Result<Study>> say({
    required String studyId,
    required String rawInput,
  });
}
