import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/l10n/generated/app_text.dart';

/// Met une préparation en texte brut, prête à être collée ailleurs.
///
/// **Rien n'est inventé, rien n'est interprété.** L'export reprend ce que la
/// préparation porte — l'unité, la demande d'origine, le thème, les versets,
/// le contexte — dans l'ordre où l'écran les montre. Un export qui reformule
/// serait une seconde voix, et Urim en a déjà une.
///
/// Le tour courant n'y figure pas : il est rejoué à chaque lecture (D28), donc
/// il n'appartient pas à la préparation mais à l'instant. L'exporter donnerait
/// à un texte collé dans un carnet l'apparence d'un acquis, alors qu'il aurait
/// pu changer entre deux ouvertures.
String exportStudyAsText(Study study, AppText text) {
  final lines = <String>[];

  final title = study.pericopeLabel ?? study.rawInput;
  if (title.trim().isNotEmpty) {
    lines
      ..add(title.trim())
      ..add('=' * title.trim().length)
      ..add('');
  }

  // Ce que le pasteur avait écrit reste en tête quand une unité l'a remplacé
  // dans le titre : c'est de là que tout est parti.
  if (study.pericopeLabel != null && study.rawInput.trim().isNotEmpty) {
    lines
      ..add(text.exportStartingPoint)
      ..add(study.rawInput.trim())
      ..add('');
  }

  if (study.theme case final String theme when theme.trim().isNotEmpty) {
    lines
      ..add(text.exportTheme)
      ..add(theme.trim())
      ..add('');
  }

  if (study.verses.isNotEmpty) {
    lines.add(text.exportVerses);
    for (final verse in study.verses) {
      lines.add('${verse.reference}  ${verse.text}');
    }
    lines.add('');
  }

  if (study.context.isNotEmpty) {
    lines.add(text.exportContext);
    for (final note in study.context) {
      lines
        ..add('— ${note.body}')
        ..add('  ${note.sourceRef}');
    }
    lines.add('');
  }

  return lines.join('\n').trimRight();
}
