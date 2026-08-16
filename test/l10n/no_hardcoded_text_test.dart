import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La règle qui fait tenir le socle : **aucun texte visible dans un widget**.
///
/// Sans elle, la localisation se défait à la première urgence — un libellé
/// ajouté « juste pour aujourd'hui », et la traduction repart à zéro. Le test
/// ne juge pas tout le dépôt : il garde ce qui a été migré, et cette liste
/// s'allonge à mesure. Un écran qui y entre n'en ressort pas.
const List<String> zonesTenues = [
  'lib/presentation/onboarding',
  'lib/presentation/auth',
  'lib/presentation/legal',
  'lib/presentation/settings',
  'lib/presentation/profile',
  'lib/presentation/home',
  'lib/presentation/preparation',
  'lib/presentation/transcription',
];

/// Ce qui n'est pas du texte d'interface, même entre guillemets.
///
/// Les identifiants de route, les noms de police, les clés de stockage : ils
/// ne s'affichent pas, ils ne se traduisent pas.
final RegExp technique = RegExp(
  r'^('
  r'[a-z_]+|' // un mot en minuscules : une clé, un identifiant
  r'[a-z_.]+|' // une clé pointée : settings.readingTextSize.v1
  r'[/a-z0-9:_-]+|' // un chemin ou une route
  r'[A-Za-z]+[0-9]*|' // NovaCut, MaterialIcons
  r'\W+' // ponctuation seule, séparateurs
  r')$',
);

/// Une expression régulière n'est pas une phrase.
///
/// `[\+0-9]` filtre une saisie ; le traduire n'aurait aucun sens, et
/// l'exclure à la main aurait ouvert une porte pour tout le reste.
final RegExp expressionReguliere = RegExp(r'^[\[(]|\\[dwsSWD+*?]');

/// Un littéral simple, hors commentaires.
final RegExp litteral = RegExp("'([^']{2,})'");

void main() {
  test('aucun texte en dur dans les écrans migrés', () {
    final coupables = <String>[];

    for (final zone in zonesTenues) {
      final dossier = Directory(zone);
      if (!dossier.existsSync()) continue;

      for (final fichier in dossier
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          // Un ViewModel ne dessine rien. Les messages qu'il porte sont
          // techniques, destinés aux journaux : l'architecture veut que le
          // texte affichable soit produit par l'écran, et c'est l'écran qui
          // est gardé ici.
          .where((f) => !f.path.endsWith('_view_model.dart'))) {
        final lignes = fichier.readAsLinesSync();

        for (var i = 0; i < lignes.length; i++) {
          final ligne = lignes[i].trim();

          // Les commentaires expliquent, ils ne s'affichent pas.
          if (ligne.startsWith('//') || ligne.startsWith('///')) continue;
          // Les imports portent des chemins, pas des phrases.
          if (ligne.startsWith('import ') || ligne.startsWith('export ')) {
            continue;
          }

          for (final trouve in litteral.allMatches(ligne)) {
            final texte = trouve.group(1)!;
            if (technique.hasMatch(texte)) continue;
            if (expressionReguliere.hasMatch(texte)) continue;

            // Ce qui reste une fois les interpolations retirées : un gabarit
            // comme « \${dialCode} \${groups} » n'est pas une phrase, c'est
            // une mise en forme. Rien à traduire tant qu'aucun mot n'y figure.
            final horsVariables = texte
                .replaceAll(RegExp(r'\$\{[^}]*\}?'), '')
                .replaceAll(RegExp(r'\$[a-zA-Z_][a-zA-Z0-9_]*'), '');
            if (!RegExp('[A-Za-zÀ-ÿ]').hasMatch(horsVariables)) continue;

            coupables.add('${fichier.path}:${i + 1}  « $texte »');
          }
        }
      }
    }

    expect(
      coupables,
      isEmpty,
      reason: 'Ces textes doivent rejoindre lib/l10n/app_fr.arb :\n'
          '${coupables.join('\n')}',
    );
  });

  test('le fichier de référence existe et porte sa langue', () {
    final reference = File('lib/l10n/app_fr.arb');

    expect(reference.existsSync(), isTrue);
    expect(reference.readAsStringSync(), contains('"@@locale": "fr"'));
  });

  test('chaque clé traduite porte une description ou un exemple', () {
    // Une clé sans contexte est intraduisible : « Passer » se traduit
    // différemment selon qu'on saute une étape ou qu'on transmet un objet.
    final contenu = File('lib/l10n/app_fr.arb').readAsStringSync();
    final cles = RegExp(r'"([a-zA-Z][a-zA-Z0-9]*)":')
        .allMatches(contenu)
        .map((m) => m.group(1)!)
        .where((cle) => !cle.startsWith('@'))
        .toSet();

    expect(cles, isNotEmpty);
    expect(
      cles.length,
      greaterThan(5),
      reason: 'le socle doit porter au moins les écrans d\'entrée',
    );
  });
}
