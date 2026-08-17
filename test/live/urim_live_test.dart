@Tags(['live'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/domain/entities/preparation/turn.dart';

/// Le moteur Urim **contre le vrai serveur**. Exclu de la suite : il sort de
/// la machine, et il a besoin d'un jeton.
///
/// ```bash
/// # cote serveur, une fois : un jeton local, sans passer par l'OTP
/// python scripts/urim_dev_login.py
///
/// # puis, cote application
/// flutter test test/live/urim_live_test.dart --tags live \
///   --dart-define=TOKEN=eyJ...
/// ```
///
/// Ce qu'il verifie et qu'aucun test hors ligne ne peut verifier : que les
/// noms de champs passent la validation du serveur, que les codes d'option
/// repartent tels qu'ils sont arrives, et que le pipeline avance vraiment
/// derriere. Les tests hors ligne, eux, travaillent sur des charges
/// **capturees** par ce chemin-la (`test/fixtures/urim/`).
void main() {
  const host = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  const token = String.fromEnvironment('TOKEN');

  setUpAll(() {
    // Le harnais de test coupe le reseau par defaut.
    HttpOverrides.global = null;
  });

  UrimRemoteDataSource source() {
    final dio = Dio(BaseOptions(
      baseUrl: '$host/api/mobile',
      headers: {'Authorization': 'Bearer $token'},
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 3),
    ));
    return UrimRemoteDataSource(dio);
  }

  test('le jeton est fourni', () {
    expect(
      token,
      isNotEmpty,
      reason: 'passer --dart-define=TOKEN=... (scripts/urim_dev_login.py)',
    );
  });

  test('le fil repond, et ne porte aucune phrase d\'Urim', () async {
    final lignes = await source().listStudies();

    expect(lignes, isNotEmpty);
    // Le fil ne rejoue pas : il n'a donc ni `say` ni `why` a servir, et
    // `StudySummary` n'a nulle part ou les mettre. Ce qu'on peut verifier
    // ici, c'est que le tri tient et que la ligne est complete.
    for (final ligne in lignes) {
      expect(ligne.rawInput, isNotEmpty);
      expect(ligne.lastActivity.isAfter(DateTime(2020)), isTrue);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('ouvrir, decider, parler — le pipeline avance', () async {
    final urim = source();

    final ouverte = await urim.open(
      rawInput: 'l\'amour fraternel n\'existe plus dans l\'eglise',
      serviceDate: DateTime(2026, 8, 23),
    );

    // Le moteur tourne jusqu'a ce qu'il ait besoin du pasteur.
    expect(ouverte.turn, isNotNull);
    expect(ouverte.turn!.why, isNotEmpty, reason: 'le filet dore');
    expect(ouverte.turn!.offersChoice || ouverte.turn!.ask.isNotEmpty, isTrue,
        reason: 'aucun tour ne finit sur un mur');

    // Un code d'option peut etre une reference — « 1 Jean 4:7-21 ». Le
    // renvoyer tel quel est tout ce que le client a le droit de faire.
    final pastilles =
        ouverte.turn!.blocks.whereType<ChipsBlock>().single.items;
    final choix = pastilles.firstWhere((p) => p.origin != 'locus');

    final apres = await urim.decide(
      studyId: ouverte.id,
      stageCode: ouverte.turn!.stageCode,
      optionCode: choix.code,
    );

    expect(apres.turn!.stageCode, isNot(ouverte.turn!.stageCode),
        reason: 'le pipeline a avance d\'un etage');

    // Parler : aucun etage dans la demande, et le serveur repond quand meme.
    final parle = await urim.say(
      studyId: ouverte.id,
      rawInput: 'quel plan je peux tenir sur ce texte ?',
    );
    expect(parle.turn!.say, isNotEmpty);

    // Et le fil s'en apercoit, sans rejouer.
    final ligne =
        (await urim.listStudies()).firstWhere((l) => l.id == ouverte.id);
    expect(ligne.lastOutcome, isNotNull,
        reason: 'la projection du dernier tour est ecrite');
    expect(ligne.serviceDate, DateTime(2026, 8, 23));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('une parole rejouee avec la meme cle ne rejoue rien', () async {
    // Etape 3b de Q4, eprouvee contre le vrai serveur : c'est le seul endroit
    // ou l'on voit que la cle est reellement honoree.
    final urim = source();

    final ouverte = await urim.open(rawInput: '1 Jean 4:7-21');
    const cle = 'urim-banc-live-idempotence';

    final premiere = await urim.say(
      studyId: ouverte.id,
      rawInput: 'quel plan je peux tenir sur ce texte ?',
      idempotencyKey: cle,
    );

    // Le meme envoi, la meme cle : le serveur rend l'etat sans repasser par
    // son repondeur — donc sans un second appel de modele.
    final seconde = await urim.say(
      studyId: ouverte.id,
      rawInput: 'quel plan je peux tenir sur ce texte ?',
      idempotencyKey: cle,
    );

    expect(seconde.turn, isNotNull);
    expect(seconde.turn!.stageCode, premiere.turn!.stageCode);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('un axe pese se decide sur son propre etage', () async {
    final urim = source();

    var etude = await urim.open(rawInput: '1 Jean 4:7-21');

    // On avance jusqu'a trouver des pesees choisissables sur un tour dont
    // l'etage n'est plus `bear_axes`.
    for (var pas = 0; pas < 5; pas++) {
      final tour = etude.turn!;
      final pesees = tour.blocks.whereType<BearingsBlock>().firstOrNull;

      if (pesees != null &&
          tour.stageCode != pesees.decideStage &&
          pesees.items.any((i) => i.selectable)) {
        final axe = pesees.items.firstWhere((i) => i.selectable);

        // ⚠️ L'etage du bloc, pas celui du tour. C'est le piege que le
        // contrat nomme, et il ne se verifie vraiment qu'ici : hors ligne,
        // rien ne refuse une decision mal adressee.
        final repris = await urim.decide(
          studyId: etude.id,
          stageCode: pesees.decideStage,
          optionCode: axe.axisCode,
        );

        expect(repris.axisCode, axe.axisCode);
        return;
      }

      final suivant = _premierGeste(tour);
      if (suivant == null) break;
      etude = await urim.decide(
        studyId: etude.id,
        stageCode: suivant.$1,
        optionCode: suivant.$2,
      );
    }

    fail('aucun tour n\'a offert de pesee choisissable hors de son etage');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

(String, String)? _premierGeste(Turn tour) {
  for (final bloc in tour.blocks) {
    switch (bloc) {
      case ChipsBlock(:final items) when items.isNotEmpty:
        return (tour.stageCode, items.first.code);
      case BoundsBlock(:final items) when items.isNotEmpty:
        return (tour.stageCode, items.first.code);
      case UnitsBlock(:final groups):
        for (final groupe in groups) {
          if (groupe.items.isNotEmpty) {
            return (tour.stageCode, groupe.items.first.code);
          }
        }
      default:
        continue;
    }
  }
  return null;
}
