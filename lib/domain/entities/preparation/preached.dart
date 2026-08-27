import 'package:equatable/equatable.dart';

/// L'archive du prédicateur — **ce qui a été prêché, et ce que le canon a reçu**.
///
/// Cinq routes du serveur portent cette famille et **aucune n'était appelée** :
/// c'est le plus gros bloc de produit servi sans écran. Les entités vivent ici
/// avant les écrans, parce que le contrat existe déjà côté serveur et qu'il n'y
/// a rien à inventer.

/// Une ligne de l'archive : un sermon prêché, un jour, sur un texte.
final class PreachedSermon extends Equatable {
  const PreachedSermon({
    required this.id,
    required this.preachedOn,
    required this.reference,
    this.pericopeLabel,
    this.axisCode,
    this.theme,
    this.captureKind,
    this.preparationId,
    this.churchId,
  });

  final String id;

  /// Le jour où ça a été prêché — pas celui où ça a été consigné.
  final DateTime preachedOn;

  /// « Actes 1:1-14 » — la référence lisible, reconstruite depuis les bornes.
  final String reference;

  /// L'unité curée, quand le passage en recoupait une.
  final String? pericopeLabel;

  /// ⚠️ **Nul = non rangé, et c'est un état normal.** Hors unité curée, il n'y
  /// a aucun axe à retenir. Le serveur le dit explicitement : *« le client doit
  /// le nommer plutôt que de masquer la ligne »* — une ligne cachée ferait
  /// croire à un trou dans l'archive.
  final String? axisCode;

  final String? theme;

  /// Comment la prédication est entrée : saisie, dictée, import.
  final String? captureKind;

  /// La préparation d'où elle vient, si elle en vient d'une. Nulle pour un
  /// sermon consigné à la main — **un pasteur a prêché avant Urim**.
  final String? preparationId;

  final String? churchId;

  /// Ce qu'on affiche en tête de ligne : l'unité si elle existe, la référence
  /// sinon. Jamais le thème — il dit l'angle, pas le texte.
  String get label => pericopeLabel ?? reference;

  @override
  List<Object?> get props => [
        id,
        preachedOn,
        reference,
        pericopeLabel,
        axisCode,
        theme,
        captureKind,
        preparationId,
        churchId,
      ];
}

/// Un livre du canon, et ce que le prédicateur y a fait.
final class BookCoverage extends Equatable {
  const BookCoverage({
    required this.book,
    required this.passages,
    required this.preachings,
    required this.lastPreachedOn,
  });

  final String book;

  /// ⚠️ **Deux nombres, jamais additionnés.** Celui-ci compte des **lieux
  /// distincts** : prêcher deux fois le même texte n'élargit pas un canon.
  final int passages;

  /// Celui-ci compte des **événements**, parce que deux assemblées ont entendu.
  final int preachings;

  final DateTime lastPreachedOn;

  @override
  List<Object?> get props => [book, passages, preachings, lastPreachedOn];
}

/// Un rayon du rangement doctrinal.
final class AxisTally extends Equatable {
  const AxisTally({
    required this.axisCode,
    required this.preachings,
    required this.lastPreachedOn,
  });

  /// Nul = **non rangé**. Il s'affiche comme les autres.
  final String? axisCode;

  final int preachings;
  final DateTime lastPreachedOn;

  @override
  List<Object?> get props => [axisCode, preachings, lastPreachedOn];
}

/// Le parcours d'un prédicateur — **des faits, aucune consigne**.
///
/// ⚠️ **Cet écran ne propose jamais de sermon.** Le serveur l'écrit dans son
/// propre contrat : *un rayon vide se montre, il ne se comble pas ; le signal
/// informe l'homme, l'homme commande la machine.* Aucun score, aucune série,
/// aucun pourcentage de complétude doctrinale — ce serait mesurer la fidélité
/// d'un pasteur, et transformer une aide en performance à tenir.
final class PreachingCoverage extends Equatable {
  const PreachingCoverage({
    required this.books,
    required this.axes,
    required this.booksUntouched,
  });

  final List<BookCoverage> books;
  final List<AxisTally> axes;

  /// ⚠️ **« Aucun sermon rangé ici », pas « il n'a jamais prêché cela ».** Un
  /// texte peut avoir été prêché sous une autre unité, ou sans axe retenu. La
  /// formulation à l'écran doit dire le fait, jamais le reproche.
  final int booksUntouched;

  @override
  List<Object?> get props => [books, axes, booksUntouched];
}
