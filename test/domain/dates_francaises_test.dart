import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/text/french_dates.dart';

/// Le jour se lit dans la date, il ne se suppose pas.
///
/// 🔴 **Deux endroits l'écrivaient en dur.** La puce du composeur affichait
/// « dim. » quelle que soit la date choisie, et la ligne de la carte d'accueil
/// « dimanche {date} » : un pasteur qui prêche le mercredi soir lisait
/// « dim. 26 août » sur un mercredi. Rien n'échouait — le libellé mentait,
/// simplement.
void main() {
  group('frenchShortDate', () {
    test('rend le vrai jour de la semaine, pas un jour supposé', () {
      // Août 2026 : le 26 est un mercredi, le 29 un samedi, le 30 un dimanche.
      expect(frenchShortDate(DateTime(2026, 8, 26)), 'mer. 26 août');
      expect(frenchShortDate(DateTime(2026, 8, 29)), 'sam. 29 août');
      expect(frenchShortDate(DateTime(2026, 8, 30)), 'dim. 30 août');
    });

    test('les sept jours ont chacun leur abrégé, et un seul', () {
      // Du lundi 24 au dimanche 30 août 2026.
      final abreges = [
        for (var jour = 24; jour <= 30; jour++)
          frenchWeekdaysShort[DateTime(2026, 8, jour).weekday - 1],
      ];

      expect(abreges, ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.']);
      expect(abreges.toSet(), hasLength(DateTime.daysPerWeek));
    });

    test('l\'heure de la journée ne change pas le jour rendu', () {
      // Un culte à 6h50 et une préparation à 23h30 tombent le même jour.
      expect(
        frenchShortDate(DateTime(2026, 8, 30, 6, 50)),
        frenchShortDate(DateTime(2026, 8, 30, 23, 30)),
      );
    });
  });
}
