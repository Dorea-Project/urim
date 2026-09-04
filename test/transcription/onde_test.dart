import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/audio/waveform.dart';

/// L'onde d'un culte — **et les faux creux qu'elle ne doit pas inventer**.
///
/// 🔴 **La panne qu'on redoute ici est visuelle, donc silencieuse.** Une onde
/// qui porte un creux toutes les trente secondes ferait croire à quatre-vingts
/// silences par culte, et le pasteur placerait sa coupe sur une frontière de
/// fragment en croyant y entendre la fin de sa prédication. Rien ne planterait ;
/// il couperait au mauvais endroit.
void main() {
  /// Le PCM que la capture écrit : 16 bits signé, petit-boutiste.
  Uint8List pcm(List<int> echantillons) {
    final octets = Uint8List(echantillons.length * 2);
    final vue = ByteData.view(octets.buffer);
    for (var i = 0; i < echantillons.length; i++) {
      vue.setInt16(i * 2, echantillons[i], Endian.little);
    }
    return octets;
  }

  /// Un pas d'onde vaut un dixième de seconde.
  const echantillonsParPas =
      CaptureFormat.sampleRate ~/ Waveform.pasParSeconde; // 1600

  Uint8List plat(int valeur, int echantillons) =>
      pcm(List<int>.filled(echantillons, valeur));

  group('les crêtes', () {
    test('un pas vaut un dixième de seconde', () {
      final cretes = Waveform.calculer([plat(0, echantillonsParPas * 30)]);

      expect(cretes, hasLength(30));
      expect(Waveform(cretes).duree, const Duration(seconds: 3));
    });

    test('c\'est la crête qui est gardée, jamais la moyenne', () {
      // Un « Amen » lancé sur un fond calme : un seul échantillon fort au
      // milieu de mille six cents. Une moyenne l'effacerait ; c'est pourtant
      // exactement le repère que le pasteur cherche.
      final echantillons = List<int>.filled(echantillonsParPas, 10)
        ..[800] = 0x7FFF;

      final cretes = Waveform.calculer([pcm(echantillons)]);

      expect(cretes, hasLength(1));
      expect(cretes.first, 255);
    });

    test('l\'amplitude est absolue — un creux compte comme une crête', () {
      final positif = Waveform.calculer([plat(20000, echantillonsParPas)]);
      final negatif = Waveform.calculer([plat(-20000, echantillonsParPas)]);

      expect(negatif.first, positif.first);
      expect(positif.first, greaterThan(0));
    });

    test('l\'échantillon le plus bas ne déborde pas', () {
      // -32768 n'a pas d'opposé représentable sur seize bits : sans borne, la
      // valeur absolue repasserait négative et l'octet sortirait faux.
      final cretes = Waveform.calculer([plat(-32768, echantillonsParPas)]);

      expect(cretes.first, 255);
    });

    test('le silence rend zéro, et reste lisible', () {
      final cretes = Waveform.calculer([plat(0, echantillonsParPas * 5)]);

      expect(cretes, everyElement(0));
      expect(cretes, hasLength(5));
    });
  });

  group('la frontière des fragments', () {
    test('une tranche à cheval sur deux fragments ne fait pas de faux creux',
        () {
      // Le cas réel : un fragment de trente secondes finit au milieu d'un pas.
      // Ici, un pas et demi de son fort, puis un demi-pas de son fort dans le
      // fragment suivant — la tranche du milieu doit rester forte.
      final premier = plat(30000, echantillonsParPas + echantillonsParPas ~/ 2);
      final second = plat(30000, echantillonsParPas ~/ 2);

      final cretes = Waveform.calculer([premier, second]);

      expect(cretes, hasLength(2));
      expect(cretes, everyElement(greaterThan(200)),
          reason: 'aucune tranche ne doit s\'effondrer sur une frontière');
    });

    test('un fragment de longueur impaire ne décale pas la suite', () {
      // Une application tuée au mauvais moment peut laisser un octet orphelin.
      // Sans report, tous les échantillons suivants seraient lus à cheval — et
      // l'onde deviendrait du bruit, sans que rien ne plante.
      final tronque = Uint8List.fromList([...plat(0, echantillonsParPas), 0x00]);
      final suite = Uint8List.fromList([0x7F, ...plat(0, echantillonsParPas)]);

      final cretes = Waveform.calculer([tronque, suite]);

      // Le seul échantillon fort est celui recollé de part et d'autre : 0x7F00.
      expect(cretes.where((c) => c > 200), hasLength(1));
    });

    test('la dernière tranche incomplète est gardée', () {
      // C'est la fin du culte. Une onde plus courte que l'audio ferait croire à
      // une capture tronquée.
      final cretes =
          Waveform.calculer([plat(9000, echantillonsParPas * 2 + 400)]);

      expect(cretes, hasLength(3));
      expect(cretes.last, greaterThan(0));
    });

    test('quatre-vingts fragments d\'affilée donnent une onde continue', () {
      // Un culte de quarante minutes, en son continu : aucune des quatre-vingts
      // frontières ne doit se voir.
      final fragments = List<Uint8List>.generate(
        80,
        (_) => plat(25000, CaptureFormat.sampleRate * 30),
      );

      final cretes = Waveform.calculer(fragments);

      expect(cretes, hasLength(80 * 300));
      expect(cretes, everyElement(greaterThan(150)));
    });
  });

  group('la fenêtre d\'affichage', () {
    Waveform onde(List<int> valeurs) =>
        Waveform(Uint8List.fromList(valeurs));

    test('rend autant de colonnes que demandé', () {
      final vue = onde(List<int>.filled(600, 40))
          .fenetre(Duration.zero, const Duration(seconds: 60), 120);

      expect(vue, hasLength(120));
    });

    test('garde le maximum de chaque colonne, jamais la première valeur', () {
      // Dézoomer en échantillonnant ferait clignoter l'onde : un pixel prendrait
      // tantôt la crête, tantôt le creux, selon l'arrondi. Le maximum ne bouge
      // pas quand on traverse.
      final valeurs = List<int>.generate(100, (i) => i.isEven ? 0 : 200);

      final vue = onde(valeurs)
          .fenetre(Duration.zero, const Duration(seconds: 10), 10);

      expect(vue, everyElement(200));
    });

    test('une fenêtre hors des bornes ne rend que du silence', () {
      final vue = onde(List<int>.filled(50, 90)).fenetre(
        const Duration(minutes: 5),
        const Duration(minutes: 6),
        20,
      );

      expect(vue, everyElement(0));
    });

    test('une fenêtre vide ou inversée ne rend rien de faux', () {
      final o = onde(List<int>.filled(50, 90));

      expect(o.fenetre(Duration.zero, Duration.zero, 10), everyElement(0));
      expect(
        o.fenetre(const Duration(seconds: 3), const Duration(seconds: 1), 10),
        everyElement(0),
      );
      expect(o.fenetre(Duration.zero, const Duration(seconds: 1), 0), isEmpty);
    });

    test('zoomer plus fin que le pas ne casse pas', () {
      // Une colonne par milliseconde : plusieurs colonnes tombent dans le même
      // pas, et aucune ne doit sortir vide par arrondi.
      final vue = onde(List<int>.filled(20, 77)).fenetre(
        Duration.zero,
        const Duration(milliseconds: 200),
        200,
      );

      expect(vue, everyElement(77));
    });
  });

  group('lire une crête à un instant', () {
    test('rend la valeur du pas, et zéro hors des bornes', () {
      final o = Waveform(Uint8List.fromList([10, 20, 30]));

      expect(o.a(Duration.zero), 10);
      expect(o.a(const Duration(milliseconds: 150)), 20);
      expect(o.a(const Duration(seconds: 9)), 0);
      expect(o.a(const Duration(milliseconds: -100)), 0);
    });

    test('une onde vide se lit sans exploser', () {
      final vide = Waveform.vide;

      expect(vide.estVide, isTrue);
      expect(vide.duree, Duration.zero);
      expect(vide.a(const Duration(seconds: 1)), 0);
    });
  });
}
