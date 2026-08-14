import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/bible/bible_book.dart';
import 'package:urim/domain/entities/bible/bible_translation.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';
import 'package:urim/domain/entities/bible/verse.dart';

/// Accès au texte biblique.
///
/// Volontairement muet sur la provenance : texte embarqué dans les assets,
/// API distante ou cache alimenté par téléchargement. Ce choix appartient à
/// la couche data et pourra changer sans toucher au domaine.
abstract interface class BibleRepository {
  /// Traductions disponibles pour la lecture.
  Future<Result<List<BibleTranslation>>> listTranslations();

  /// Livres d'une traduction, dans l'ordre du canon.
  Future<Result<List<BibleBook>>> listBooks(String translationId);

  /// Texte d'un passage. Échoue si la référence sort des bornes du livre.
  Future<Result<Passage>> getPassage({
    required PassageRef ref,
    required String translationId,
  });

  /// Recherche plein texte dans une traduction.
  ///
  /// [limit] borne le nombre de résultats : une recherche sur un mot courant
  /// retourne des milliers de versets, que ni le réseau ni l'affichage ne
  /// doivent avoir à absorber.
  Future<Result<List<Verse>>> search({
    required String query,
    required String translationId,
    int limit = 50,
  });
}
