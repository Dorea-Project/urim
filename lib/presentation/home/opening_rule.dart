import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';

/// Les deux moitiés de l'accueil.
///
/// Ce ne sont pas deux modes ni deux façons de saisir : ce sont **deux
/// travaux**. Préparer part d'une intention et remonte vers un texte ;
/// prêcher part de ce qui a été dit et le conserve. Ils ne partagent ni leur
/// fil, ni leur geste du bas — d'où deux pages plutôt qu'une liste mêlée.
enum HomeTab {
  /// Les préparations en cours. Six jours sur sept, c'est ici qu'on arrive.
  prepare,

  /// Les prédications captées. La seule brique qui marche sans modèle ni
  /// traduction : la voix du pasteur, telle quelle.
  preach,
}

/// Sur quelle page l'application s'ouvre.
///
/// **Rien n'est demandé, rien n'est stocké.** Poser la question à l'inscription
/// reviendrait à faire choisir entre deux écrans que personne n'a encore vus, et
/// une préférence enregistrée pour rien devient une préférence oubliée le jour
/// où la fonction arrive (D13). C'est le calendrier qui décide.
///
/// La règle tient en une phrase : **Urim ouvre sur [HomeTab.prepare] ; sauf le
/// jour du culte, tant que rien n'a été capté ce jour-là.**
///
/// ⚠️ **Le coût des deux erreurs n'est pas le même**, et c'est tout le
/// raisonnement. Se tromper de page coûte une tape — l'autre est à une icône.
/// Rater la capture coûte la prédication, définitivement : le module de domaine
/// du serveur l'écrit, *« la capture n'est jamais refusée ; ce qui n'est pas
/// capté dimanche est perdu pour toujours »*. On conçoit pour l'échec cher.
///
/// [now] vient de l'horloge injectée, jamais de `DateTime.now()` : un écran qui
/// lit l'heure du système pendant que son jeu d'exemple se construit sur une
/// horloge figée passe pour la mauvaise raison, puis tombe tout seul une semaine
/// plus tard.
HomeTab openingTab({
  required DateTime now,
  required List<StudySummary> summaries,
}) {
  if (!isServiceDay(now: now, summaries: summaries)) return HomeTab.prepare;

  // La dérogation se referme d'elle-même : une fois le culte capté, la raison
  // d'ouvrir ailleurs a disparu, et l'après-midi redevient un jour ordinaire.
  if (capturedOn(now, summaries: summaries)) return HomeTab.prepare;

  return HomeTab.preach;
}

/// Aujourd'hui est-il un jour de culte ?
///
/// Trois sources, dans cet ordre, et aucune n'est une question posée à
/// l'utilisateur :
///
/// 1. **une préparation datée d'aujourd'hui** — `serviceDate` est déjà renseigné
///    par celui qui prépare, c'est la source la plus sûre et la plus précise ;
/// 2. **le jour le plus fréquent des prédications déjà captées** — le corpus se
///    renseigne tout seul au bout de quelques semaines, et vaut pour une
///    assemblée qui se réunit le mercredi soir aussi bien que le dimanche ;
/// 3. **dimanche**, faute de mieux.
///
/// ⚠️ **La source 2 est muette les premières semaines.** Un pasteur qui prêche
/// mercredi *et* dimanche n'aura la bonne ouverture au milieu de semaine qu'une
/// fois deux ou trois mercredis captés. C'est le prix de ne rien demander ; il
/// se paie d'une tape, et la source 1 le couvre dès qu'une préparation est
/// datée.
bool isServiceDay({
  required DateTime now,
  required List<StudySummary> summaries,
}) {
  final datedToday = summaries.any(
    (summary) => switch (summary.serviceDate) {
      final DateTime service => _sameDay(service, now),
      null => false,
    },
  );

  if (datedToday) return true;

  return now.weekday == (usualServiceWeekday(summaries) ?? DateTime.sunday);
}

/// Une prédication a-t-elle déjà été captée ce jour-là ?
///
/// On regarde l'origine, pas le libellé : une préparation écrite le matin du
/// culte ne dit rien de ce qui a été prêché.
bool capturedOn(DateTime day, {required List<StudySummary> summaries}) =>
    summaries.any(
      (summary) =>
          summary.origin == PreparationOrigin.transcribed &&
          _sameDay(summary.lastActivity, day),
    );

/// Le prochain culte, d'après ce que le corpus a appris.
///
/// 🔴 **La date proposée à l'ouverture était « dimanche prochain », en dur.**
/// Un pasteur qui prêche le mercredi soir se voyait proposer un dimanche à
/// chaque préparation, et devait corriger à la main chaque fois. La même
/// déduction qui décide de l'écran d'ouverture (D50) sait déjà quel jour cette
/// assemblée se réunit : elle sert ici aussi.
///
/// **Strictement à venir** : le culte d'aujourd'hui se prêche dans quelques
/// heures, il ne se prépare plus.
DateTime nextService({
  required DateTime from,
  required List<StudySummary> summaries,
}) {
  final weekday = usualServiceWeekday(summaries) ?? DateTime.sunday;
  final day = DateTime(from.year, from.month, from.day);
  final ahead = (weekday - day.weekday + DateTime.daysPerWeek) %
      DateTime.daysPerWeek;

  return day.add(
    Duration(days: ahead == 0 ? DateTime.daysPerWeek : ahead),
  );
}

/// Le jour de semaine où l'on prêche, lu dans le corpus. Nul tant qu'il est
/// vide.
///
/// En cas d'égalité — deux cultes par semaine, autant de captures de chaque
/// côté — c'est le jour de la **prédication la plus récente** qui l'emporte :
/// à défaut de savoir lequel des deux est aujourd'hui, autant suivre l'habitude
/// la plus fraîche.
int? usualServiceWeekday(List<StudySummary> summaries) {
  final preached = summaries
      .where((summary) => summary.origin == PreparationOrigin.transcribed)
      .toList()
    ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

  if (preached.isEmpty) return null;

  final counts = <int, int>{};
  for (final summary in preached) {
    final weekday = summary.lastActivity.weekday;
    counts[weekday] = (counts[weekday] ?? 0) + 1;
  }

  // `preached` est trié du plus récent au plus ancien : à égalité de compte, le
  // premier rencontré est le plus frais.
  var best = preached.first.lastActivity.weekday;
  for (final summary in preached) {
    final weekday = summary.lastActivity.weekday;
    if (counts[weekday]! > counts[best]!) best = weekday;
  }

  return best;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// La conversation que l'accueil reprend.
///
/// L'accueil **est** la conversation depuis qu'il a cessé d'être une liste : il
/// lui faut donc savoir laquelle ouvrir. C'est la même question que « Reprendre »
/// posait en tête de fil, et elle se répond dans cet ordre :
///
/// 1. **ce qui attend une réponse** — Urim a rendu la main, personne d'autre ne
///    peut avancer à la place du pasteur ;
/// 2. **le culte le plus proche** — c'est la seule échéance qui existe vraiment ;
/// 3. **ce qui a été touché en dernier**, faute d'échéance.
///
/// Les préparations closes sont écartées : « j'ai prêché celle-ci » n'est pas un
/// travail en cours. Elles restent dans le tiroir, où on va les rechercher.
///
/// Nul quand il n'y a rien à reprendre — l'accueil montre alors le champ vide,
/// qui est le seul geste qui fasse avancer ce jour-là.
String? resumeId(List<StudySummary> summaries, {required DateTime now}) {
  final ouvertes = summaries
      .where((s) => s.origin != PreparationOrigin.transcribed && !s.isClosed)
      .toList();

  if (ouvertes.isEmpty) return null;

  ouvertes.sort((a, b) {
    if (a.waitsForUser != b.waitsForUser) return a.waitsForUser ? -1 : 1;

    final serviceA = a.serviceDate;
    final serviceB = b.serviceDate;

    // Une date passée n'est plus une échéance : elle ne doit pas passer devant
    // un culte à venir sous prétexte qu'elle est « plus proche ».
    final aVenirA = serviceA != null && !serviceA.isBefore(_jour(now));
    final aVenirB = serviceB != null && !serviceB.isBefore(_jour(now));

    if (aVenirA != aVenirB) return aVenirA ? -1 : 1;
    if (aVenirA && aVenirB) return serviceA.compareTo(serviceB);

    return b.lastActivity.compareTo(a.lastActivity);
  });

  return ouvertes.first.id;
}

DateTime _jour(DateTime at) => DateTime(at.year, at.month, at.day);
