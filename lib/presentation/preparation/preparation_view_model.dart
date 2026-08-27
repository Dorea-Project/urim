import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/cached.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/gesture_outcome.dart';
import 'package:urim/domain/entities/preparation/pending_gesture.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/turn.dart';
import 'package:urim/domain/repositories/study_repository.dart';
import 'package:urim/presentation/home/home_view_model.dart';

/// Ce qui s'affiche dans le fil.
///
/// **Le serveur n'a pas d'historique de conversation, et n'en aura pas.** Le
/// moteur rejoue son pipeline à chaque lecture : ce qu'une préparation garde,
/// ce sont les décisions du pasteur, pas les phrases. Il n'existe donc qu'un
/// tour à un instant donné — le tour courant.
///
/// Ce que cette classe ajoute est un **compte rendu de séance** : ce que le
/// pasteur vient de dire, et les tours qu'il a reçus depuis qu'il a ouvert
/// l'écran. Rien de tout cela n'est persisté, et c'est honnête ainsi — rouvrir
/// la préparation demain rendra ce que le moteur en dit demain, pas la
/// conversation d'aujourd'hui.
sealed class ThreadEntry {
  const ThreadEntry();
}

/// Ce que le pasteur a dit — écrit, ou touché.
final class SpokenByPastor extends ThreadEntry {
  const SpokenByPastor(this.text);

  final String text;
}

/// Ce qu'Urim a dit **à un tour passé**, relu en base.
///
/// 🔴 Il n'existait pas, et c'est pourquoi le fil disparaissait : un tour ancien
/// ne peut pas être rejoué — ses pastilles ne mènent plus nulle part, et sa
/// phrase venait d'un modèle à un instant. Seule la phrase survit, et elle
/// suffit à ce que le pasteur relise sa séance.
final class SaidByUrim extends ThreadEntry {
  const SaidByUrim(this.text);

  final String text;
}

/// Un tour rendu par le moteur.
final class ServedTurn extends ThreadEntry {
  const ServedTurn(this.turn, {required this.live});

  final Turn turn;

  /// Seul le dernier tour est vivant. Les précédents restent lisibles, mais
  /// leurs gestes ne mènent plus nulle part : le moteur a avancé, et répondre
  /// à un tour passé enverrait une décision à un étage qui n'attend plus.
  final bool live;
}

/// L'état de l'écran : la préparation, et le compte rendu de la séance.
final class ThreadState {
  const ThreadState({
    required this.study,
    this.entries = const [],
    this.receivedAt,
    this.pending = const [],
    this.thinking = false,
  });

  final Study study;
  final List<ThreadEntry> entries;

  /// Les gestes notés qui n'ont pas encore pu partir.
  ///
  /// **Aucun tour ne les accompagne**, et c'est le point dur de l'étape : le
  /// tour suivant est ce que le pipeline aurait répondu, et le fabriquer ici
  /// serait inventer une phrase d'Urim (D29). L'écran dit donc « noté », garde
  /// le tour précédent sous les yeux, et attend.
  final List<PendingGesture> pending;

  /// L'heure à laquelle ce tour a été reçu, **quand il vient du magasin
  /// local**. Nul veut dire frais.
  ///
  /// L'écran doit le dire. Le moteur rejoue à chaque lecture (D28) : ce qui a
  /// été gardé hier soir est ce qu'il disait hier soir, et le faire passer
  /// pour une réponse d'aujourd'hui serait un mensonge que le pasteur
  /// découvrirait au pire moment.
  final DateTime? receivedAt;

  /// Le moteur travaille — l'écran le dit, au lieu de laisser un blanc.
  ///
  /// ⚠️ **Distinct de [isWaitingToSend]**, et il ne faut pas les confondre :
  /// celui-ci veut dire « c'est parti, on attend la réponse », l'autre veut
  /// dire « ce n'est pas parti du tout ». Le premier rassure, le second
  /// prévient.
  final bool thinking;

  bool get isStale => receivedAt != null;

  bool get isWaitingToSend => pending.isNotEmpty;

  Turn? get turn => study.turn;
}

/// Une préparation ouverte, et ce qui s'est dit depuis.
final class PreparationThread extends AsyncNotifier<ThreadState> {
  PreparationThread(this.studyId);

  final String studyId;

  /// **Ce qu'on sait d'abord, ce que le serveur dit ensuite.**
  ///
  /// Chaque lecture rejoue les huit étages du pipeline : huit secondes mesurées
  /// en local, et un écran vide sans réseau. Le tour gardé s'affiche donc tout
  /// de suite, marqué de son heure, et le rafraîchissement le remplace quand il
  /// arrive. Sans réseau, il ne le remplace pas — et c'est encore lisible.
  @override
  Future<ThreadState> build() async {
    final repository = ref.watch(studyRepositoryProvider);

    // Ce qui attendait d'être envoyé part avant toute lecture : sinon on
    // afficherait un tour antérieur aux gestes que le pasteur a déjà faits.
    if (await repository.flush(studyId) case Success(:final value)) {
      return _depuis(value);
    }

    if (await repository.cachedById(studyId) case final Cached<Study> garde) {
      // Le rafraîchissement part sans qu'on l'attende : l'écran est déjà
      // utilisable, et un échec de réseau ne doit pas l'effacer.
      Future.microtask(_rafraichir);
      return ThreadState(
        study: garde.value,
        receivedAt: garde.receivedAt,
        pending: await repository.pending(studyId),
        entries: _entrees(garde.value),
      );
    }

    final result = await repository.getById(studyId);

    return result.fold(
      onSuccess: (study) => _depuis(study),
      onFailure: (failure) => throw failure,
    );
  }

  ThreadState _depuis(Study study, {DateTime? receivedAt}) => ThreadState(
        study: study,
        receivedAt: receivedAt,
        entries: _entrees(study),
      );

  /// Le compte rendu de la séance — **relu, et non plus perdu**.
  ///
  /// 🔴 *« Le fil de discussion disparaît lorsqu'on revient dans la
  /// discussion. »* L'écran n'y était pour rien : le serveur ne gardait que la
  /// saisie d'ouverture, et tout le reste vivait ici, en mémoire, jusqu'à ce
  /// qu'on quitte.
  ///
  /// Il vient maintenant de `study.fil`, écrit tour après tour. Le dernier tour
  /// reste vivant — ses pastilles mènent quelque part ; les précédents sont des
  /// paroles, lisibles et inertes.
  List<ThreadEntry> _entrees(Study study) => [
        if (study.fil.isEmpty && study.rawInput.isNotEmpty)
          // Une préparation d'avant le fil gardé : il ne reste que ce qu'elle
          // porte en propre. Mieux que rien, et honnête sur ce qui manque.
          SpokenByPastor(study.rawInput),
        for (final ligne in study.fil)
          if (ligne.estDuPasteur)
            SpokenByPastor(ligne.body)
          else
            SaidByUrim(ligne.body),
        if (study.turn case final Turn turn) ServedTurn(turn, live: true),
      ];

  /// Relit au serveur et remplace le tour gardé — **sans jamais effacer**.
  ///
  /// Un échec laisse l'écran tel quel : le pasteur garde ce qu'il avait sous
  /// les yeux. Bascule en erreur ferait payer la panne de réseau deux fois.
  Future<void> _rafraichir() async {
    final repository = ref.read(studyRepositoryProvider);

    // Le réseau est peut-être revenu : ce qui attendait part maintenant, et
    // c'est plus juste qu'une simple relecture.
    if (await repository.flush(studyId) case Success(:final value)) {
      state = AsyncData(_depuis(value));
      ref.invalidate(studyFeedProvider);
      return;
    }

    final result = await repository.getById(studyId);

    result.fold(
      onSuccess: (study) {
        // Si le pasteur a déjà touché quelque chose entre-temps, on ne revient
        // pas en arrière : sa séance a avancé.
        if (state.value?.entries.whereType<SpokenByPastor>().length case
            final int dits when dits > 1) {
          return;
        }
        state = AsyncData(_depuis(study));
      },
      onFailure: (_) {},
    );
  }

  /// Répondre à un étage qui rend la main.
  ///
  /// [stageCode] n'est pas toujours celui du tour : les pesées portent le leur.
  /// C'est le bloc qui le dit, pas l'écran — l'envoyer au mauvais étage vaut un
  /// refus du serveur.
  Future<Failure?> decide({
    required String stageCode,
    required String optionCode,
    required String label,
  }) =>
      _geste(
        said: label,
        action: (repository, studyId) => repository.decide(
          studyId: studyId,
          stageCode: stageCode,
          optionCode: optionCode,
          label: label,
        ),
      );

  /// Écarter une option. Aucun étage n'avance ; le tour suivant ne la
  /// reproposera pas.
  Future<Failure?> dismiss({
    required String stageCode,
    required String optionCode,
  }) =>
      _geste(
        action: (repository, studyId) => repository.dismiss(
          studyId: studyId,
          stageCode: stageCode,
          optionCode: optionCode,
        ),
      );

  /// Parler. Une phrase libre, à n'importe quel moment.
  ///
  /// Parler attend le réseau comme les autres gestes, avec une **clé
  /// d'idempotence** : le serveur qui l'a déjà vue rend l'état courant sans
  /// repasser par son répondeur, donc sans un second appel de modèle et sans
  /// risquer une autre phrase que celle que le pasteur a déjà lue.
  Future<Failure?> say(String text) {
    final dit = text.trim();
    if (dit.isEmpty) return Future.value();

    return _geste(
      said: dit,
      action: (repository, studyId) =>
          repository.say(studyId: studyId, rawInput: dit),
    );
  }

  /// Le même chemin pour les trois gestes : on note ce que le pasteur a fait,
  /// on appelle, on remplace le tour vivant.
  ///
  /// L'écran ne bascule pas en chargement : ce qui est déjà lu doit rester lu
  /// pendant que le moteur travaille. Un fil qui disparaît à chaque réponse
  /// ferait perdre le fil de la conversation, au sens propre.
  Future<Failure?> _geste({
    String? said,
    required Future<Result<GestureOutcome>> Function(
      StudyRepository repository,
      String studyId,
    ) action,
  }) async {
    final courant = state.value;
    if (courant == null) return null;

    final entries = [
      // Les tours passés perdent leurs gestes : le moteur a avancé.
      for (final entry in courant.entries)
        switch (entry) {
          ServedTurn(:final turn) => ServedTurn(turn, live: false),
          final ThreadEntry autre => autre,
        },
      if (said != null) SpokenByPastor(said),
    ];

    state = AsyncData(
      ThreadState(study: courant.study, entries: entries, thinking: true),
    );

    final result = await action(ref.read(studyRepositoryProvider), studyId);

    return await result.fold(
      onSuccess: (issue) async {
        switch (issue) {
          case Served(:final study):
            state = AsyncData(ThreadState(
              study: study,
              entries: [
                ...entries,
                if (study.turn case final Turn turn)
                  ServedTurn(turn, live: true),
              ],
            ));
            // Le fil d'accueil vient de vieillir : l'étage a changé.
            ref.invalidate(studyFeedProvider);

          case Queued():
            // Pas de tour à montrer, et il ne faut surtout pas en inventer un.
            // Ce que le pasteur a touché reste à l'écran, marqué comme non
            // parti : c'est tout ce qu'on peut dire honnêtement.
            state = AsyncData(ThreadState(
              study: courant.study,
              entries: entries,
              receivedAt: courant.receivedAt,
              pending: await ref.read(studyRepositoryProvider).pending(studyId),
            ));
        }
        return null;
      },
      onFailure: (failure) async {
        // ⚠️ **Une bulle qui s'allume doit avoir quelqu'un pour l'éteindre sur
        // *chaque* chemin.** Sans ceci, un envoi refusé laissait les trois
        // points tourner indéfiniment sous une phrase qui n'était jamais
        // partie — l'écran promettait une réponse qui ne viendrait pas.
        //
        // 🔴 Trouvé par `brouillon_test`, pas par une relecture : c'est le
        // même défaut que la roue de l'articulation, deux heures plus tôt.
        state = AsyncData(ThreadState(
          study: courant.study,
          entries: entries,
          receivedAt: courant.receivedAt,
          pending: courant.pending,
        ));
        return failure;
      },
    );
  }
}

final preparationThreadProvider = AsyncNotifierProvider.family<
    PreparationThread, ThreadState, String>(PreparationThread.new);
