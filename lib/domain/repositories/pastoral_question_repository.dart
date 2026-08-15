import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/pastoral/decision.dart';
import 'package:urim/domain/entities/pastoral/pastoral_question.dart';
import 'package:urim/domain/entities/pastoral/scripture_anchor.dart';

/// Persistance du module décisionnel.
///
/// La question est la racine : les passages rattachés et les décisions n'ont
/// pas d'existence hors d'elle, et sont donc adressés par `questionId`.
abstract interface class PastoralQuestionRepository {
  /// Questions filtrées par étape, triées de la plus récente à la plus
  /// ancienne. Un flux plutôt qu'une lecture ponctuelle : la liste doit
  /// refléter immédiatement une modification faite depuis un autre écran.
  ///
  /// [statuses] vide signifie « toutes les étapes ».
  Stream<Result<List<PastoralQuestion>>> watchQuestions({
    Set<DiscernmentStatus> statuses,
  });

  Future<Result<PastoralQuestion>> getById(String questionId);

  /// Crée ou met à jour, selon que l'identifiant est déjà connu.
  Future<Result<PastoralQuestion>> save(PastoralQuestion question);

  /// Supprime la question et tout ce qui s'y rattache.
  Future<Result<void>> delete(String questionId);

  Future<Result<List<ScriptureAnchor>>> listAnchors(String questionId);

  Future<Result<ScriptureAnchor>> addAnchor(ScriptureAnchor anchor);

  Future<Result<void>> removeAnchor(String anchorId);

  /// Décisions successives, de la plus ancienne à la plus récente. Une
  /// question rouverte puis redécidée en compte plusieurs : c'est
  /// l'historique du discernement, il ne s'écrase pas.
  Future<Result<List<Decision>>> listDecisions(String questionId);

  Future<Result<Decision>> addDecision(Decision decision);
}
