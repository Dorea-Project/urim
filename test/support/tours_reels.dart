import 'dart:convert';
import 'dart:io';

import 'package:urim/core/result/cached.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/domain/entities/preparation/gesture_outcome.dart';
import 'package:urim/domain/entities/preparation/pending_gesture.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/repositories/study_repository.dart';

/// Les vraies reponses du moteur, capturees contre le corpus reel.
///
/// Ce que des donnees ecrites a la main ne peuvent pas reproduire : un tour
/// d'ouverture a seize pastilles melant axes et passages, un motif de 1 423
/// caracteres, dix pesees et dix-huit couples plan x matiere qui reviennent a
/// **chaque** tour suivant parce que ce sont du decor ambiant.
///
/// C'est contre ces formes-la que l'ecran doit tenir, pas contre les trois
/// pastilles des maquettes.
abstract final class ToursReels {
  const ToursReels._();

  static const String ouverture = '01_ouverture';
  static const String bornes = '02_bornes';
  static const String pesees = '03_pesees';
  static const String miseEnForme = '04_mise_en_forme';
  static const String theme = '05_theme';
  static const String parole = '06_parole';
  static const String horsChamp = '07_hors_champ';
  static const String fil = '08_fil';

  /// La preparation de Marc 10:46-52 — la seule capture dont le corpus
  /// porte une note de contexte. Toutes les unites n'en ont pas.
  static const String bartimee = '09_bartimee';

  /// Tous les tours, dans l'ordre du parcours.
  static const List<String> tous = [
    ouverture,
    bornes,
    pesees,
    miseEnForme,
    theme,
    parole,
    horsChamp,
  ];

  static String json(String nom) =>
      File('test/fixtures/urim/$nom.json').readAsStringSync();

  /// Passe la charge par le **vrai** chemin d'analyse — pas par un
  /// constructeur de test. Ce qui casserait en production casse ici.
  ///
  /// Synchrone, et ce n'est pas un detail : un test de widget controle le
  /// temps, et y attendre une requete — meme simulee — ne se termine jamais.
  static Study etude(String nom) =>
      studyFromWire(jsonDecode(json(nom)) as Map<String, dynamic>);

  static List<StudySummary> lignes() =>
      feedFromWire(jsonDecode(json(fil)) as List<dynamic>);
}

/// Un depot qui sert une preparation capturee, et note les gestes recus.
///
/// `base` plutot que `final` : les tests du brouillon en derivent un depot qui
/// **refuse**, et c'est le seul etat ou un brouillon a un role.
base class DepotFige implements StudyRepository {
  DepotFige(this.etude);

  Study etude;

  final List<(String, String)> decisions = [];
  final List<(String, String)> rejets = [];
  final List<String> paroles = [];

  /// Le squelette envoye pendant le test, s'il l'a ete.
  List<PlanElement>? elementsEnvoyes;

  @override
  Future<Result<Study>> setElements({
    required String studyId,
    required List<PlanElement> elements,
  }) async {
    elementsEnvoyes = elements;
    return Result.success(etude);
  }

  @override
  Future<Result<List<StudySummary>>> listMine() async =>
      const Result.success([]);

  /// Rien de garde : les tests d'ecran passent par le chemin normal, qui est
  /// instantane puisque la doublure ne touche pas au reseau.
  @override
  Future<Cached<Study>?> cachedById(String studyId) async => null;

  @override
  Future<Cached<List<StudySummary>>?> cachedFeed() async => null;

  @override
  Future<Result<Study>> open({
    required String rawInput,
    DateTime? serviceDate,
  }) async =>
      Result.success(etude);

  @override
  Future<Result<Study>> getById(String studyId) async => Result.success(etude);

  @override
  Future<Result<GestureOutcome>> decide({
    required String studyId,
    required String stageCode,
    required String optionCode,
    String label = '',
  }) async {
    decisions.add((stageCode, optionCode));
    return Result.success(Served(etude));
  }

  @override
  Future<Result<GestureOutcome>> dismiss({
    required String studyId,
    required String stageCode,
    required String optionCode,
  }) async {
    rejets.add((stageCode, optionCode));
    return Result.success(Served(etude));
  }

  /// La doublure repond toujours : rien n'attend jamais.
  @override
  Future<List<PendingGesture>> pending(String studyId) async => const [];

  @override
  Future<Result<Study>?> flush(String studyId) async => null;

  @override
  Future<Result<GestureOutcome>> say({
    required String studyId,
    required String rawInput,
  }) async {
    paroles.add(rawInput);
    return Result.success(Served(etude));
  }
}

/// Le corps brut, decode — pour affirmer sur ce que le serveur a **vraiment**
/// envoye, sans passer par nos propres types.
Map<String, dynamic> charge(String nom) =>
    jsonDecode(ToursReels.json(nom)) as Map<String, dynamic>;
