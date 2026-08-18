import 'package:flutter_test/flutter_test.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/preparation/study_export.dart';

/// Mettre une préparation en texte brut.
///
/// Ce que ces tests protègent n'est pas la mise en forme : c'est le fait que
/// **rien ne soit inventé ni perdu**. Un export qui reformule serait une
/// seconde voix, et Urim en a déjà une.
void main() {
  /// Les intitulés viennent de la même source que l'écran.
  final libelles = AppTextFr();

  Study study({
    String rawInput = 'l\'amour fraternel n\'existe plus dans l\'église',
    String? pericopeLabel,
    String? theme,
    List<ServedVerse> verses = const [],
    List<ContextNote> context = const [],
  }) =>
      Study(
        id: 'etude-1',
        status: 'served',
        rawInput: rawInput,
        turn: null,
        pericopeLabel: pericopeLabel,
        theme: theme,
        verses: verses,
        context: context,
      );

  String exporter(Study etude) => exportStudyAsText(etude, libelles);

  group('ce que l\'export reprend', () {
    test('sans unité bornée, le titre est ce que le pasteur a écrit', () {
      expect(exporter(study()), startsWith('l\'amour fraternel'));
    });

    test('l\'unité bornée prend le titre, et la demande reste dessous', () {
      final texte = exporter(study(pericopeLabel: 'Hébreux 13:1-6'));

      expect(texte, startsWith('Hébreux 13:1-6'));
      expect(
        texte,
        contains(libelles.exportStartingPoint),
        reason: 'c\'est de là que tout est parti : le perdre effacerait la '
            'raison de la préparation',
      );
      expect(texte, contains('amour fraternel'));
    });

    test('les versets sortent avec leur référence', () {
      final texte = exporter(
        study(
          verses: const [
            ServedVerse(
              reference: 'Hébreux 13:1',
              text: 'Que l\'amour fraternel continue.',
            ),
          ],
        ),
      );

      expect(texte, contains(libelles.exportVerses));
      expect(texte, contains('Hébreux 13:1'));
      expect(texte, contains('Que l\'amour fraternel continue.'));
    });

    test('le contexte sort avec sa source', () {
      final texte = exporter(
        study(
          context: const [
            ContextNote(
              kind: 'litteraire',
              body: 'La péroraison de la lettre.',
              sourceRef: 'Hébreux 13',
            ),
          ],
        ),
      );

      expect(texte, contains(libelles.exportContext));
      expect(texte, contains('La péroraison de la lettre.'));
      expect(
        texte,
        contains('Hébreux 13'),
        reason: 'une note sans sa source serait une affirmation invérifiable',
      );
    });

    test('le thème sort quand il existe', () {
      expect(
        exporter(study(theme: 'La persévérance de l\'assemblée')),
        contains('La persévérance de l\'assemblée'),
      );
    });
  });

  group('ce que l\'export ne fait pas', () {
    test('une section absente ne laisse pas d\'intitulé vide', () {
      final texte = exporter(study());

      expect(texte, isNot(contains(libelles.exportVerses)));
      expect(texte, isNot(contains(libelles.exportContext)));
      expect(texte, isNot(contains(libelles.exportTheme)));
    });

    test('le tour courant n\'est pas exporté', () {
      expect(
        exporter(study(pericopeLabel: 'Hébreux 13:1-6')),
        isNot(contains('URIM')),
        reason: 'le tour est rejoué à chaque lecture : l\'exporter donnerait à '
            'un texte collé l\'apparence d\'un acquis',
      );
    });

    test('rien ne finit par des lignes vides', () {
      final texte = exporter(
        study(
          verses: const [
            ServedVerse(reference: 'Hébreux 13:1', text: 'Que l\'amour…'),
          ],
        ),
      );

      expect(texte, equals(texte.trimRight()));
    });
  });
}
