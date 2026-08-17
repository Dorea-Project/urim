import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';

/// Le fil du pasteur : ses préparations, la plus fraîchement touchée en tête.
///
/// Une seule opération, et c'est voulu. Ouvrir, répondre, décider passent par
/// la préparation elle-même — ici on ne fait que **regarder où l'on en est**.
abstract interface class StudyRepository {
  /// Clé sur l'auteur, jamais sur l'église : une préparation ouverte sans
  /// assemblée appartient au même fil que celle ouverte sous une église. C'est
  /// un seul homme qui prépare.
  ///
  /// Les abandonnées ne remontent pas ; les closes, si.
  Future<Result<List<StudySummary>>> listMine();
}
