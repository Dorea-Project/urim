import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/audio/capture_playback.dart';
import 'package:urim/core/audio/piece_cutter.dart';
import 'package:urim/core/audio/piece_store.dart';
import 'package:urim/core/audio/track_player.dart';
import 'package:urim/core/audio/waveform.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/domain/entities/transcription/sermon_piece.dart';

/// Ce que l'éditeur montre, et où il en est.
final class EditeurState extends Equatable {
  const EditeurState({
    required this.onde,
    required this.duree,
    required this.tete,
    required this.selDebut,
    required this.selFin,
    required this.fenetreDebut,
    required this.fenetreEtendue,
    this.joue = false,
    this.prepare = false,
    this.taille = false,
    this.chemin,
    this.refus,
    this.derniere,
  });

  final Waveform onde;

  /// La durée réelle de la matière — celle des octets, pas celle du lecteur.
  ///
  /// ⚠️ **Les deux peuvent différer d'un cheveu**, le temps que le greffon lise
  /// l'en-tête. On borne sur les octets : ils font foi (D53).
  final Duration duree;

  final Duration tete;
  final Duration selDebut;
  final Duration selFin;

  /// La fenêtre zoomée — ce que le détail dessine.
  final Duration fenetreDebut;
  final Duration fenetreEtendue;

  final bool joue;

  /// L'onde se calcule, ou le fichier jouable s'assemble.
  final bool prepare;

  /// Une pièce est en train d'être écrite.
  final bool taille;

  /// Le fichier jouable de la capture entière.
  final String? chemin;

  final PlaybackRefusal? refus;

  /// La dernière pièce taillée, pour la dire à l'écran.
  final SermonPiece? derniere;

  Duration get fenetreFin {
    final fin = fenetreDebut + fenetreEtendue;
    return fin > duree ? duree : fin;
  }

  Duration get selectionDuree =>
      selFin > selDebut ? selFin - selDebut : Duration.zero;

  bool get selectionUtile => selectionDuree >= const Duration(seconds: 1);

  /// Reste-t-il de la matière après la pièce en cours ?
  bool get resteApres => duree - selFin >= const Duration(seconds: 1);

  EditeurState copyWith({
    Waveform? onde,
    Duration? duree,
    Duration? tete,
    Duration? selDebut,
    Duration? selFin,
    Duration? fenetreDebut,
    Duration? fenetreEtendue,
    bool? joue,
    bool? prepare,
    bool? taille,
    String? chemin,
    PlaybackRefusal? refus,
    bool effacerRefus = false,
    SermonPiece? derniere,
    bool effacerDerniere = false,
  }) =>
      EditeurState(
        onde: onde ?? this.onde,
        duree: duree ?? this.duree,
        tete: tete ?? this.tete,
        selDebut: selDebut ?? this.selDebut,
        selFin: selFin ?? this.selFin,
        fenetreDebut: fenetreDebut ?? this.fenetreDebut,
        fenetreEtendue: fenetreEtendue ?? this.fenetreEtendue,
        joue: joue ?? this.joue,
        prepare: prepare ?? this.prepare,
        taille: taille ?? this.taille,
        chemin: chemin ?? this.chemin,
        refus: effacerRefus ? null : (refus ?? this.refus),
        derniere: effacerDerniere ? null : (derniere ?? this.derniere),
      );

  @override
  List<Object?> get props => [
        onde,
        duree,
        tete,
        selDebut,
        selFin,
        fenetreDebut,
        fenetreEtendue,
        joue,
        prepare,
        taille,
        chemin,
        refus,
        derniere,
      ];
}

/// Tailler une pièce dans un culte — **le geste, pas seulement l'outil**.
///
/// 🔴 **Sur un téléphone, on ne place pas une coupe en tirant une poignée.** Une
/// heure et demie sur trois cent soixante points fait huit secondes par pixel :
/// le doigt couvre une minute de prédication. Le geste juste est l'inverse —
/// **on écoute, on entend la frontière, on pose la borne là où on est**. D'où
/// « début ici » et « fin ici », qui lient la sélection à la tête de lecture ;
/// l'onde sert à viser grossièrement et à se repérer, l'oreille tranche.
///
/// ⚠️ **Rien n'est détruit ici.** Tailler écrit une pièce **à côté** ; la
/// matière reste entière jusqu'à sa purge du septième jour. Un pasteur peut se
/// tromper de borne, recommencer, tailler trois pièces d'un même culte — la
/// seule chose irréversible du chantier reste la purge, et elle ne dépend pas
/// de cet écran.
final class PieceEditorViewModel extends AsyncNotifier<EditeurState> {
  PieceEditorViewModel(this.cible);

  /// Le culte visé — **son identifiant autant que son dossier**. La pièce doit
  /// dire de quel culte elle vient, et elle le dira encore quand le dossier
  /// aura été purgé.
  final CibleEditeur cible;

  StreamSubscription<Duration>? _position;
  StreamSubscription<void>? _fin;

  /// La fenêtre la plus serrée qu'on autorise.
  ///
  /// Quatre secondes en travers de l'écran : chaque point vaut une centaine de
  /// millisecondes, plus fin que ce qu'un doigt vise et plus fin que le pas de
  /// l'onde. Descendre en dessous ne donnerait pas de précision, seulement du
  /// vertige.
  static const Duration _zoomMax = Duration(seconds: 4);

  @override
  Future<EditeurState> build() async {
    // ⚠️ **Le lecteur est saisi avant, pas dans le rappel.** Riverpod interdit
    // de toucher à `ref` depuis un cycle de vie ; l'écran quitté, la lecture
    // continuerait dans le vide et le prochain culte se jouerait par-dessus.
    final lecteur = ref.read(trackPlayerProvider);

    ref.onDispose(() {
      _position?.cancel();
      _fin?.cancel();
      lecteur.stop();
    });

    final onde =
        await ref.read(waveformDigestProvider).preparer(cible.chemin) ??
            Waveform.vide;
    final chemin =
        await ref.read(capturePlaybackProvider).preparer(cible.chemin);

    _position?.cancel();
    _position = lecteur.onPosition.listen((position) {
      final courant = state.value;
      if (courant == null || !courant.joue) return;
      state = AsyncData(_suivre(courant.copyWith(tete: position)));
    });

    _fin?.cancel();
    _fin = lecteur.onComplete.listen((_) {
      final courant = state.value;
      if (courant != null) state = AsyncData(courant.copyWith(joue: false));
    });

    return EditeurState(
      onde: onde,
      duree: onde.duree,
      tete: Duration.zero,
      selDebut: Duration.zero,
      selFin: onde.duree,
      fenetreDebut: Duration.zero,
      fenetreEtendue: onde.duree,
      chemin: chemin,
    );
  }

  /// La fenêtre suit la tête quand elle sort du cadre — **sans la recentrer à
  /// chaque image**, ce qui ferait défiler l'onde sous les yeux en permanence.
  /// On la déplace d'un cadre entier, comme une page qui tourne.
  EditeurState _suivre(EditeurState etat) {
    if (etat.tete >= etat.fenetreDebut && etat.tete <= etat.fenetreFin) {
      return etat;
    }
    return etat.copyWith(
      fenetreDebut: _bornerFenetre(
        etat.tete - Duration(microseconds: etat.fenetreEtendue.inMicroseconds ~/ 8),
        etat.fenetreEtendue,
        etat.duree,
      ),
    );
  }

  static Duration _bornerFenetre(
      Duration debut, Duration etendue, Duration duree) {
    final max = duree - etendue;
    if (debut < Duration.zero) return Duration.zero;
    if (max <= Duration.zero) return Duration.zero;
    return debut > max ? max : debut;
  }

  Future<void> lireOuPause() async {
    final courant = state.value;
    if (courant == null || courant.chemin == null) return;
    final lecteur = ref.read(trackPlayerProvider);

    if (courant.joue) {
      await lecteur.pause();
      state = AsyncData(courant.copyWith(joue: false));
      return;
    }

    final refus = await lecteur.play(courant.chemin!);
    if (refus != null) {
      state = AsyncData(courant.copyWith(refus: refus, joue: false));
      return;
    }
    await lecteur.seek(courant.tete);
    state = AsyncData(courant.copyWith(joue: true, effacerRefus: true));
  }

  Future<void> allerA(Duration position) async {
    final courant = state.value;
    if (courant == null) return;

    final borne = position < Duration.zero
        ? Duration.zero
        : (position > courant.duree ? courant.duree : position);

    await ref.read(trackPlayerProvider).seek(borne);
    state = AsyncData(_suivre(courant.copyWith(tete: borne)));
  }

  Future<void> deplacer(Duration pas) async {
    final courant = state.value;
    if (courant == null) return;
    await allerA(courant.tete + pas);
  }

  /// Pose la borne de gauche là où l'oreille est.
  void poserDebut() {
    final courant = state.value;
    if (courant == null) return;
    final debut = courant.tete;
    state = AsyncData(courant.copyWith(
      selDebut: debut,
      selFin: courant.selFin <= debut ? courant.duree : courant.selFin,
    ));
  }

  void poserFin() {
    final courant = state.value;
    if (courant == null) return;
    final fin = courant.tete;
    state = AsyncData(courant.copyWith(
      selFin: fin,
      selDebut: courant.selDebut >= fin ? Duration.zero : courant.selDebut,
    ));
  }

  /// Écouter une coupe — **deux secondes avant, et on laisse courir**.
  ///
  /// C'est la vérification qui compte : une borne posée à l'œil tombe souvent
  /// au milieu d'un mot, et on ne s'en aperçoit qu'en l'entendant.
  Future<void> ecouterLaCoupe(Duration borne) async {
    await allerA(borne - const Duration(seconds: 2));
    final courant = state.value;
    if (courant != null && !courant.joue) await lireOuPause();
  }

  void zoomer(double facteur) {
    final courant = state.value;
    if (courant == null || courant.duree == Duration.zero) return;

    var etendue = Duration(
      microseconds: (courant.fenetreEtendue.inMicroseconds * facteur).round(),
    );
    if (etendue < _zoomMax) etendue = _zoomMax;
    if (etendue > courant.duree) etendue = courant.duree;

    // On zoome **autour de la tête**, pas autour du bord gauche : c'est
    // l'endroit que le pasteur regarde, et le voir s'échapper à chaque zoom
    // rendrait le geste inutilisable.
    final part = courant.fenetreEtendue.inMicroseconds == 0
        ? 0.0
        : (courant.tete - courant.fenetreDebut).inMicroseconds /
            courant.fenetreEtendue.inMicroseconds;

    final debut = courant.tete -
        Duration(microseconds: (etendue.inMicroseconds * part.clamp(0.0, 1.0)).round());

    state = AsyncData(courant.copyWith(
      fenetreEtendue: etendue,
      fenetreDebut: _bornerFenetre(debut, etendue, courant.duree),
    ));
  }

  /// Déplace la fenêtre pour montrer [instant] — l'aperçu s'en sert.
  void cadrerSur(Duration instant) {
    final courant = state.value;
    if (courant == null) return;
    state = AsyncData(courant.copyWith(
      fenetreDebut: _bornerFenetre(
        instant -
            Duration(microseconds: courant.fenetreEtendue.inMicroseconds ~/ 2),
        courant.fenetreEtendue,
        courant.duree,
      ),
    ));
  }

  /// Écrit la pièce, puis la range. Rend `null` si rien n'a été taillé.
  ///
  /// ⚠️ **Deux gestes, dans cet ordre, et l'ordre compte.** Le tailleur écrit
  /// les octets ; le magasin écrit le compagnon qui leur donne un nom. Si le
  /// second échoue, il reste un `.wav` orphelin que `PieceStore` ignore — une
  /// pièce invisible plutôt qu'une pièce sans nom. L'inverse aurait laissé un
  /// nom qui promet un son absent.
  Future<SermonPiece?> tailler({required String titre}) async {
    final courant = state.value;
    if (courant == null || !courant.selectionUtile || courant.taille) {
      return null;
    }

    state = AsyncData(courant.copyWith(taille: true, effacerDerniere: true));

    final id = ref.read(idGeneratorProvider).newId();
    final chemin = await ref.read(pieceCutterProvider).decouper(
          cible.chemin,
          debut: courant.selDebut,
          fin: courant.selFin,
          id: id,
        );

    SermonPiece? piece;
    if (chemin != null) {
      piece = SermonPiece(
        id: id,
        captureId: cible.captureId,
        title: titre.trim(),
        start: courant.selDebut,
        end: courant.selFin,
        path: chemin,
        cutAt: ref.read(clockProvider).now(),
      );
      await ref.read(pieceStoreProvider).save(piece);
      ref.invalidate(piecesDeLaCaptureProvider(cible.captureId));
    }

    final apres = state.value ?? courant;
    state = AsyncData(apres.copyWith(taille: false, derniere: piece));
    return piece;
  }

  /// Après une pièce, enchaîner sur la suivante — **le geste de son dimanche**.
  ///
  /// Le pasteur taille sa prédication, puis sa prière. La seconde commence là
  /// où la première finit ; lui faire replacer la borne à la main serait lui
  /// demander de retrouver un endroit qu'il vient de désigner.
  void enchainer() {
    final courant = state.value;
    if (courant == null) return;
    state = AsyncData(courant.copyWith(
      selDebut: courant.selFin,
      selFin: courant.duree,
      tete: courant.selFin,
      effacerDerniere: true,
    ));
  }
}

/// Ce qu'il faut pour ouvrir l'éditeur : l'identifiant du culte et son dossier.
typedef CibleEditeur = ({String captureId, String chemin});

final pieceEditorProvider = AsyncNotifierProvider.autoDispose
    .family<PieceEditorViewModel, EditeurState, CibleEditeur>(
  PieceEditorViewModel.new,
);
