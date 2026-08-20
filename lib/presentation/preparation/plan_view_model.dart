import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
import 'package:urim/domain/entities/preparation/study.dart';

/// Ce que l'écran du plan tient : les sections montrées, et ce qui est écrit
/// dedans.
///
/// **Les sections montrées ne sont pas les sections écrites.** Les dix de Braga
/// s'affichent toujours, vides ou non — c'est le squelette, il propose un
/// ordre. Les cinq autres n'apparaissent que si le pasteur les ajoute, ou si
/// son plan en porte déjà.
final class PlanState {
  const PlanState({
    required this.sections,
    required this.bodies,
    this.saving = false,
  });

  /// Les codes affichés, dans l'ordre.
  final List<String> sections;

  /// Ce qui est écrit, par code de section.
  final Map<String, String> bodies;

  final bool saving;

  /// Les sections que le pasteur peut encore ajouter.
  List<String> get addable =>
      PlanSkeleton.observees.where((c) => !sections.contains(c)).toList();

  /// Ce qui partira au serveur : **tout ce qui est montré**, vide compris.
  ///
  /// Une section montrée puis effacée doit s'effacer côté serveur, et le seul
  /// moyen de le dire est de l'envoyer vide — l'envoi remplace l'ensemble.
  List<PlanElement> get elements => [
        for (final (index, code) in sections.indexed)
          PlanElement(code: code, ordinal: index, body: bodies[code]),
      ];

  PlanState copyWith({
    List<String>? sections,
    Map<String, String>? bodies,
    bool? saving,
  }) =>
      PlanState(
        sections: sections ?? this.sections,
        bodies: bodies ?? this.bodies,
        saving: saving ?? this.saving,
      );
}

/// Le squelette d'une préparation, écrit par le pasteur.
final class PlanViewModel extends Notifier<PlanState> {
  PlanViewModel(this.study);

  final Study study;

  @override
  PlanState build() {
    final ecrites = {
      for (final element in study.elements) element.code: element.body ?? '',
    };

    return PlanState(
      // Les dix de Braga, plus les sections déjà écrites qui n'en font pas
      // partie — un plan venu d'ailleurs ne perd rien en s'ouvrant ici.
      sections: [
        ...PlanSkeleton.braga,
        ...ecrites.keys.where((c) => !PlanSkeleton.braga.contains(c)),
      ],
      bodies: ecrites,
    );
  }

  void write(String code, String body) => state = state.copyWith(
        bodies: {...state.bodies, code: body},
      );

  void addSection(String code) {
    if (state.sections.contains(code)) return;
    state = state.copyWith(sections: [...state.sections, code]);
  }

  /// Envoie le plan. Renvoie la `Failure` en cas d'échec, `null` si c'est parti.
  Future<Failure?> save() async {
    state = state.copyWith(saving: true);

    final result = await ref.read(studyRepositoryProvider).setElements(
          studyId: study.id,
          elements: state.elements,
        );

    state = state.copyWith(saving: false);

    return result.fold(onSuccess: (_) => null, onFailure: (failure) => failure);
  }
}

/// Clé par la **préparation entière** et non par son identifiant : l'état de
/// départ se lit dans ses éléments, et le relire depuis le serveur pour ouvrir
/// un écran de saisie serait payer un rejeu du pipeline pour rien.
final planViewModelProvider =
    NotifierProvider.family<PlanViewModel, PlanState, Study>(
  PlanViewModel.new,
);
