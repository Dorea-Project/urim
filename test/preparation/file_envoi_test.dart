import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/fragment_outbox.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// La file d'envoi — **ce qui part, et ce qui ne se perd pas quand rien ne part**.
///
/// 🔴 F4 est le cas le plus fréquent en usage réel : le réseau coupe plusieurs
/// fois pendant un culte. Ces tests tiennent la règle qui en découle — un échec
/// n'avance pas la marque, et rien n'est sauté.

/// Un transport piloté à la main.
final class _TransportFeint implements FragmentSender {
  _TransportFeint({this.accepteJusqua});

  /// Au-delà de cet index, le transport refuse. Nul = il accepte tout.
  final int? accepteJusqua;

  final List<({String capture, int index, int octets})> recus = [];

  @override
  Future<bool> send({
    required String captureId,
    required int index,
    required List<int> bytes,
  }) async {
    if (accepteJusqua != null && index >= accepteJusqua!) return false;

    recus.add((capture: captureId, index: index, octets: bytes.length));
    return true;
  }
}

void main() {
  late Directory racine;

  setUp(() {
    racine = Directory.systemTemp.createTempSync('urim_file');
  });

  tearDown(() {
    if (racine.existsSync()) racine.deleteSync(recursive: true);
  });

  Directory poser(String id, DateTime debut, {required int fragments}) {
    final dossier = Directory(
      '${racine.path}/${FragmentOutbox.sousDossier}/'
      '${id}_${debut.millisecondsSinceEpoch}',
    )..createSync(recursive: true);

    for (var index = 0; index < fragments; index++) {
      File('${dossier.path}/${CaptureFormat.fragmentName(index)}')
          .writeAsBytesSync(List<int>.filled(100, index));
    }

    return dossier;
  }

  FragmentOutbox file(FragmentSender transport) =>
      FragmentOutbox(sender: transport, directory: () async => racine);

  int marqueDe(Directory dossier) => int.parse(
        File('${dossier.path}/${FragmentOutbox.marque}').readAsStringSync(),
      );

  group('ce qui attend', () {
    test('un dossier absent n\'est pas une erreur', () async {
      expect(await file(_TransportFeint()).pending(), isEmpty);
    });

    test('tout attend tant que rien n\'est parti', () async {
      poser('culte', DateTime(2026, 8, 23, 10), fragments: 5);

      final attente = await file(_TransportFeint()).pending();

      expect(attente.single.total, 5);
      expect(attente.single.sent, 0);
      expect(attente.single.pending, 5);
    });

    test('la plus ancienne capture passe devant', () async {
      // 🔴 Elle est a un jour de sa purge : si elle ne part pas maintenant,
      // elle ne partira jamais. Celle de ce matin a une semaine devant elle.
      poser('recent', DateTime(2026, 8, 23, 10), fragments: 1);
      poser('vieux', DateTime(2026, 8, 17, 10), fragments: 1);

      final attente = await file(_TransportFeint()).pending();

      expect(attente.map((e) => e.captureId), ['vieux', 'recent']);
    });

    test('une capture entierement partie n\'attend plus', () async {
      final dossier = poser('culte', DateTime(2026, 8, 23, 10), fragments: 3);
      File('${dossier.path}/${FragmentOutbox.marque}').writeAsStringSync('3');

      expect(await file(_TransportFeint()).pending(), isEmpty);
    });
  });

  group('emporter', () {
    test('les fragments partent dans l\'ordre, et la marque suit', () async {
      final dossier = poser('culte', DateTime(2026, 8, 23, 10), fragments: 4);
      final transport = _TransportFeint();

      final accuses = await file(transport).flush();

      expect(accuses, 4);
      expect(transport.recus.map((r) => r.index), [0, 1, 2, 3]);
      expect(transport.recus.first.capture, 'culte');
      expect(marqueDe(dossier), 4);
    });

    test('un refus arrete la file sans sauter le fragment', () async {
      final dossier = poser('culte', DateTime(2026, 8, 23, 10), fragments: 5);
      // Le reseau lache apres le deuxieme.
      final transport = _TransportFeint(accepteJusqua: 2);

      final accuses = await file(transport).flush();

      expect(accuses, 2);
      expect(transport.recus.map((r) => r.index), [0, 1]);
      expect(
        marqueDe(dossier),
        2,
        reason: 'la marque s\'arrete la ou le serveur a accuse',
      );
    });

    test('le passage suivant reprend exactement la', () async {
      final dossier = poser('culte', DateTime(2026, 8, 23, 10), fragments: 5);
      await file(_TransportFeint(accepteJusqua: 2)).flush();

      // Le reseau revient.
      final revenu = _TransportFeint();
      final accuses = await file(revenu).flush();

      expect(accuses, 3);
      expect(
        revenu.recus.map((r) => r.index),
        [2, 3, 4],
        reason: 'ni doublon ni trou : on repart du fragment refuse',
      );
      expect(marqueDe(dossier), 5);
    });

    test('des fragments ajoutes pendant le culte repartent tout seuls',
        () async {
      // F4 : la capture continue pendant que la file se vide.
      final debut = DateTime(2026, 8, 23, 10);
      poser('culte', debut, fragments: 2);

      final premier = _TransportFeint();
      await file(premier).flush();
      expect(premier.recus, hasLength(2));

      // Deux fragments de plus se posent sur le disque.
      poser('culte', debut, fragments: 4);

      final second = _TransportFeint();
      await file(second).flush();

      expect(second.recus.map((r) => r.index), [2, 3]);
    });

    test('deux captures se vident chacune de son cote', () async {
      poser('dimanche', DateTime(2026, 8, 23, 10), fragments: 2);
      poser('mercredi', DateTime(2026, 8, 19, 19), fragments: 3);

      final transport = _TransportFeint();
      await file(transport).flush();

      expect(transport.recus.where((r) => r.capture == 'mercredi'), hasLength(3));
      expect(transport.recus.where((r) => r.capture == 'dimanche'), hasLength(2));
    });

    test('le transport recoit les octets du fragment, pas son nom', () async {
      poser('culte', DateTime(2026, 8, 23, 10), fragments: 1);
      final transport = _TransportFeint();

      await file(transport).flush();

      expect(transport.recus.single.octets, 100);
    });
  });

  group('quand le disque ment', () {
    test('une marque plus haute que le disque est ramenee au reel', () async {
      // 🔴 Sauter des fragments serait pire que les renvoyer : le serveur sait
      // absorber un doublon (I24), il ne sait pas deviner un trou.
      final dossier = poser('culte', DateTime(2026, 8, 23, 10), fragments: 2);
      File('${dossier.path}/${FragmentOutbox.marque}').writeAsStringSync('9');

      final attente = await file(_TransportFeint()).pending();

      expect(attente, isEmpty, reason: 'deux sur deux : plus rien a emporter');
    });

    test('une marque illisible vaut zero, pas une panne', () async {
      final dossier = poser('culte', DateTime(2026, 8, 23, 10), fragments: 3);
      File('${dossier.path}/${FragmentOutbox.marque}').writeAsStringSync('oups');

      final transport = _TransportFeint();
      await file(transport).flush();

      expect(transport.recus, hasLength(3));
    });

    test('un dossier sans fragment n\'entre pas dans la file', () async {
      Directory('${racine.path}/${FragmentOutbox.sousDossier}/vide_1755000000000')
          .createSync(recursive: true);

      expect(await file(_TransportFeint()).pending(), isEmpty);
    });
  });
}
