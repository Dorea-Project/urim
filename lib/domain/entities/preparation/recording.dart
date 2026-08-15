import 'package:equatable/equatable.dart';

/// État d'un enregistrement, de la capture au texte.
enum RecordingStatus {
  /// Capture en cours.
  capturing,

  /// Capture interrompue, reprise possible.
  paused,

  /// Capture terminée, transcription pas encore faite.
  captured,

  /// Transcription en cours sur l'appareil.
  transcribing,

  /// Transcrit — le texte est disponible.
  transcribed,

  /// Transcription impossible pour l'instant, en attente.
  awaitingNetwork,

  /// Transcription échouée sur une erreur qui ne se résoudra pas seule.
  failed;

  bool get isFinished => this == transcribed;

  /// L'utilisateur peut-il reprendre l'enregistrement là où il l'a laissé ?
  bool get canResume => this == paused || this == captured;
}

/// Enregistrement audio attaché à une préparation.
///
/// [transcribedOnDevice] n'est pas cosmétique : la politique de
/// confidentialité promet qu'aucun contenu ne part chez un tiers. Le porter
/// dans le modèle permet de l'afficher honnêtement — « transcrit sur
/// l'appareil » — et de refuser un envoi distant quand la promesse a été
/// faite.
final class Recording extends Equatable {
  const Recording({
    required this.id,
    required this.duration,
    required this.status,
    this.transcribedOnDevice = true,
    this.waveform = const [],
    this.filePath,
  });

  final String id;
  final Duration duration;
  final RecordingStatus status;
  final bool transcribedOnDevice;

  /// Amplitudes normalisées entre 0 et 1, échantillonnées pour l'affichage.
  ///
  /// Conservées à part de l'audio : dessiner la forme d'onde ne doit pas
  /// obliger à relire un fichier de plusieurs dizaines de mégaoctets.
  final List<double> waveform;

  /// Chemin local du fichier. Nul si l'audio a été supprimé après
  /// transcription.
  final String? filePath;

  bool get hasAudio => filePath != null;

  @override
  List<Object?> get props =>
      [id, duration, status, transcribedOnDevice, waveform, filePath];

  @override
  String toString() => 'Recording($id, ${duration.inSeconds}s, ${status.name})';
}
