# Urim — les sprints

Établi le 20 août 2026, contre l'état réel des deux dépôts.

## Comment ils sont ordonnés

**Par ce qui débloque quoi, pas par difficulté.** Un sprint ne se termine pas
parce que le temps est écoulé : il se termine quand sa **sortie mesurable** est
vraie. Elle est écrite avant de commencer, et elle se vérifie sur un appareil,
pas dans un tableau.

Trois règles tenues d'un sprint à l'autre :

- **Ce que le serveur sert déjà passe avant ce qu'il faut construire.** Vingt et
  une routes servies, six appelées à l'établissement de ce plan : c'est là
  qu'est le produit non livré. Les sprints 1 et 2 en ont branché six de plus —
  **douze sur vingt et une** au 22 août. Les neuf qui restent sont nommées au
  sprint 2-bis et au sprint 6.
- **Un chantier serveur précède l'écran qui en dépend.** Un écran qui promet ce
  que le serveur ne tient pas est une dette déguisée en fonctionnalité.
- **Ce qui attend une décision n'entre pas dans un sprint.** Il attend dans
  [`decisions.md`](decisions.md), nommé, avec ce qu'il bloque.

---

## Sprint 1 — Le pasteur emporte quelque chose — **fait**

**Le manque le plus criant.** Une préparation menée de bout en bout se termine
aujourd'hui sur trois gestes fermés. Le pasteur traverse quatre étages, lit dix
pesées, arrive au bout — et repart les mains vides. La fiche de chaire réclame
« Votre plan : à écrire », et aucun écran ne permet de l'écrire.

| Travail | Où |
|---|---|
| L'écran des points — les dix éléments du squelette, tous facultatifs | `POST /urim/studies/{id}/elements` |
| Soumettre le livrable, lire le dossier de validation, prendre le fichier | `POST …/deliverable`, `GET /deliverables/{id}`, `/fichier` |
| Ouvrir le code du geste dans `_servis` — la ligne cesse d'être fermée | `turn_views.dart` |

**Sortie mesurable :** un pasteur ouvre une préparation, écrit trois points,
soumet, voit le contrôle des citations verset par verset, et récupère un
`.docx` conforme sur son téléphone. — **atteinte**, avec deux réserves écrites
dans les dettes : le fichier est *posé dans un dossier* faute d'un canal de
partage, et rien n'a encore tourné sur un vrai téléphone.

**Ce que ça ferme :** la dernière case vide de la ligne d'arrivée v1 côté
serveur, et la dette « geste servi, écran absent ».

---

## Sprint 2 — Le texte, et pas seulement le raisonnement — **fait, sauf Q21**

**Deux des trois questions qu'un pasteur a posées en séance** n'ont pas d'écran
pour les recevoir, alors que le serveur y répond.

| Travail | Où |
|---|---|
| Lire un passage sans ouvrir de préparation | `GET /urim/passages` |
| La concordance — où ce mot de l'original paraît ailleurs | `GET /urim/lemmes` |
| La chaîne de textes d'appui, avec son contrôle de référence | `POST …/supports` |
| Le geste **questionner** : une parole qui n'est ni décider ni écarter obtient une réponse, pas un refus poli — **Q21** | `conversation.py`, fil |

**Sortie mesurable :** « je peux avoir le sens original de *idole* ? » rend les
onze occurrences d'εἴδωλον dans l'application, sans passer par la base. —
**atteinte par un écran**, pas par le fil : l'écran « Chercher » s'ouvre depuis
l'accueil et depuis la préparation, et il dit ce que le corpus ne porte pas.

**Ce qui reste, et c'est Q21 :** la même question **écrite dans la barre du
fil** part toujours vers l'aiguilleur, qui n'a pas d'issue « questionner ». Le
pasteur a désormais un endroit où obtenir sa réponse ; il doit encore savoir
qu'il faut l'ouvrir. Trancher Q21 est un travail de moteur, pas d'écran.

**Ce que ça ne fera pas :** donner le *sens* du mot. La glose manque pour
14 021 lemmes sur 14 101 — c'est le sprint 5.

---

## Sprint 2-bis — La prose demandée, point par point — **fait**

**Ajouté le 22 août 2026**, après la confrontation du serveur à quatre specs
entrantes (`back-dorea/docs/Urim_Raccord_Specs_2026-08-22.md`). Il passe devant
le sprint 3 pour une seule raison : **la route est servie, testée, et personne
ne l'appelle.**

`POST /urim/studies/{id}/articulations` est *« la seule prose que produise
Urim, et elle est demandée point par point »*. Elle existe côté serveur avec
ses quatre interdits dans l'invite — aucun verset hors du texte fourni, aucun
fait historique, aucun point ajouté, aucune illustration — et sa propre table.

> **Ce qui la rend acceptable n'est pas une promesse, c'est le chemin des
> données.** Le livrable n'imprime que `preparation_element.body`. La
> proposition n'atteint un document **que si le pasteur la reprend dans son
> plan** — c'est-à-dire s'il l'a lue.

**Pourquoi maintenant, et pas plus tôt.** Les specs entrantes réclamaient un
*proforma rédigé complet*. Le fondateur a tranché le 22/08 : le verrou tient,
le moteur n'écrit jamais une division. Les articulations sont la réponse
**honnête** au besoin que le proforma habillait — le pasteur reçoit de l'aide
sur le point qu'il a écrit, et rien ne s'écrit à sa place.

| Travail | Où |
|---|---|
| L'entité, le port, la source distante | `articulation.dart`, `study_repository.dart`, `urim_remote_data_source.dart` |
| Le geste « faire articuler ce point », par section non vide | `plan_page.dart` |
| **Enregistrer avant d'articuler** — le serveur articule le point *stocké* | `plan_page.dart` |
| La proposition dans une feuille : le corps, la transition, **le modèle qui l'a écrite** | `plan_page.dart` |
| « Reprendre dans mon point » — un geste explicite, jamais une insertion | `plan_page.dart` |
| `disponible: false` dit sobrement, **sans écran d'erreur** | l10n |

**Sortie mesurable :** un pasteur écrit une division, demande à Urim de
l'articuler, lit la proposition **à côté** de son texte, et c'est lui qui
décide de la reprendre. S'il n'y a pas de modèle branché, l'écran le dit en une
phrase et son point reste écrit.

**Trois interdits, et ce sont eux qui font la revue :**

- la proposition n'entre **jamais** seule dans le champ ;
- ~~elle porte **toujours** le nom du modèle~~ — **remplacé le 22/08, le jour
  même.** La signature est gardée en base, pas montrée : *« le pasteur n'a que
  faire de ia-mistral »*. Ce qui la remplace dit **ce que ça change** plutôt que
  qui l'a écrite — « proposé par le modèle, non relu ». La règle est meilleure :
  un nom de modèle ne se juge pas, une absence de relecture si ;
- `disponible: false` n'est **pas** une erreur : c'est un état de production,
  au même rang que le mannequin sans corpus.

⚠️ **Le piège de cet écran.** Le serveur articule le point tel qu'il l'a en
base, et garde son mémo sur une empreinte du texte. Articuler sans enregistrer
d'abord rendrait au pasteur une proposition sur une phrase qu'il vient de
remplacer — le défaut serait invisible et le rendrait fou. L'écran enregistre,
puis demande.

---

## Sprint 3 — Le compte dit vrai

**Serveur d'abord, écran ensuite.** Le profil affiche « 2 sur 2 » devant un
serveur qui en accepterait dix, et des églises qui viennent d'un jeu d'exemple.

| Travail | Où |
|---|---|
| Lister les appareils de confiance, retirer l'un d'eux | route à écrire, `back-dorea` |
| Compter à la liaison, refuser le troisième avec un code nommé — **D45**, **Q23** | `verify-device`, `login` |
| Les églises réelles du profil — **Q9** | `GET /iam/me`, déjà servi |

**Sortie mesurable :** un troisième téléphone reçoit un refus qui dit quoi
faire, et le profil n'affiche plus une seule donnée inventée.

---

## Sprint 4 — La provenance à l'écran

**Première couche de Q24, et la moins chère : rien à curer, tout à afficher.**
Le corpus porte déjà `source_ref`, `reviewed_by`, `reviewed_at` sur chaque
énoncé. L'écran n'en montre aucun, si bien qu'un pasteur ne distingue pas un
énoncé relu par un homme d'un énoncé produit par un modèle et jamais lu — et il
y en a **139 198 contre 11**.

| Travail | Où |
|---|---|
| Servir la provenance dans le tour, puis l'afficher : `◆ relu par …` / `◇ non relu` | `turn.py`, `turn_views.dart` |
| La chaîne du raisonnement dans « comment j'en suis arrivé là » — les étages, ce qui a été pesé, ce qui a été écarté | fil |
| Le thème cesse d'être un gabarit de codes bruts | côté serveur, libellé de l'axe |

**Sortie mesurable :** sur n'importe quel tour, le pasteur peut dire de chaque
phrase qui l'a écrite et qui l'a relue.

**Ce que ça coûte, et qu'il faut assumer :** la première ouverture montrera
`◇ non relu` presque partout. C'est le but.

---

## Sprint 5 — Remplir les étagères

**Seconde couche de Q24, et la seule qui demande du temps humain.** Les deux
catégories vides ont leur emplacement dans le schéma ; ce qui manque est une
source citable et un relecteur qui signe.

| Travail | Périmètre |
|---|---|
| Contexte historique | les livres réellement prêchés, pas les 66 |
| Gloses des lemmes | les mots les plus servis par la concordance |
| Un relecteur nommé, et une règle d'entrée | *rien n'entre sans source citable* |

**Sortie mesurable :** la première note historique signée par un homme, et la
première glose relue — sur Colossiens, puisque c'est le texte qu'on a joué.

---

## Sprint 6 — Ce qui a été prêché

**Les routes restantes, et elles forment une famille.** Quatre routes servies,
zéro ligne côté application : `POST /studies/{id}/preached`, `POST /preached`,
`GET /preached`, `GET /preached/couverture`. C'est l'archive — ce qui a été
prêché, et ce que le canon a déjà reçu.

| Travail | Où |
|---|---|
| Marquer une préparation comme prêchée, avec sa date | `POST …/preached` |
| Consigner une prédication qui n'est pas passée par Urim | `POST /preached` |
| L'archive, et la **couverture** — quels livres ont déjà été prêchés | `GET /preached`, `/couverture` |
| Relire un dossier de validation déjà soumis | `GET /deliverables/{id}` — aujourd'hui lisible **seulement** en réponse au POST |

**Sortie mesurable :** un pasteur voit ce qu'il a prêché cette année, et sur
quels livres il n'est jamais monté.

**Ce qui n'y est pas :** les routes sous `/tenants/{id}` — l'application ne
prépare qu'en personnel, et l'ouvrir à l'église est un chantier de compte
(sprint 3), pas d'archive.

---

## Sprint 7 — Ce qui n'est pas capté est perdu

**L'étage 1, des deux côtés.** Le module de domaine du serveur tient déjà la
règle — *« la capture n'est jamais refusée ; ce qui n'est pas capté dimanche est
perdu pour toujours »* — et n'a ni route, ni travailleur. Côté application, le
micro écrit désormais des fragments de trente secondes qui se purgent au
septième jour. Entre les deux, **rien**.

| Travail | Où |
|---|---|
| ~~La file d'envoi~~ — **écrite le 26 août** (`FragmentOutbox`, D54). Elle se remplit, elle ne se vide nulle part : le `FragmentSender` branché refuse tout, faute de route. ⚠️ **12 tests sur 13 vus verts** ; le treizième — l'ordre de la file — a révélé un vrai défaut, corrigé, **non rejoué** : la session a perdu le droit d'exécuter avant de le revoir passer | `lib/core/audio/fragment_outbox.dart` |
| La route de capture — recevoir un fragment, jamais le refuser | `capture/domain.py` l'attend |
| Le travailleur qui consomme `CaptureJob`, avec son retry et son backoff | le domaine le modélise, personne ne l'exécute |
| Rattacher une capture à une préparation — le geste que la règle avait repoussé | l'écran de relecture s'ouvre alors sur du vide honnête |

| **Dire que la capture ne suit pas l'appareil** — la promesse manquante | écran, avant le pilote |

🔴 **La capture est le premier objet d'Urim qui ne se synchronise pas**, et rien
ne le dit au pasteur. Tout le reste vit sur le serveur : il ouvre Urim sur sa
tablette et retrouve son travail. Une capture, non — elle vit sur un téléphone,
sept jours, et nulle part ailleurs. C'est la conséquence de *« la capture n'est
jamais refusée »*, qui interdit d'attendre le réseau : ce n'est donc pas un
défaut à corriger, mais **une promesse à formuler avant le premier pilote**. Le
jour où un pasteur enregistre son culte sur son téléphone et cherche la
relecture sur sa tablette, il ne doit pas découvrir le vide.

**Sortie mesurable :** un culte de quarante minutes capté **sans réseau du début
à la fin**, retrouvé entier sur le serveur le lendemain, et effacé de l'appareil
au septième jour sans que personne n'ait rien fait.

**Ce qui n'y est pas :** le transcript. Cet étage transporte de l'audio, il n'en
tire rien — c'est exactement ce que le serveur s'autorise.

---

## Sprint 8 — Le transcript, et rien de plus

**Q2 est tranchée : le modèle tourne sur l'appareil** (voir `decisions.md`).
F3 de la spec T-Rec exige un sermon entier sans connexion, et I23 que la première
détection ne dépende pas du réseau : aucun service distant ne peut les tenir.

| Travail | Où |
|---|---|
| Le banc d'essai — `tiny` contre `base`, vingt minutes réelles sur un A07 | **avant** de choisir, pas après |
| Le port de transcription, et son modèle embarqué | `adapters/` ne porte que Mistral |
| La détection d'activité vocale — Whisper **invente du texte sur le silence**, et un culte en est plein | sans elle, le transcript ment |
| `JobKind.TRANSCRIRE` change de sens : *recevoir* un transcript, non le produire | il perd sa raison d'être serveur |

**Sortie mesurable :** une prédication captée dimanche porte lundi son transcript
brut, fabriqué sur le téléphone, **sans qu'un octet d'audio soit sorti**.

**Ce qui n'y est pas :** l'extraction des versets et l'alignement. Ils restent
verrouillés — c'est le sprint suivant qui ouvre la porte, s'il le peut.

---

## Sprint 9 — Mesurer avant d'ouvrir

**Le verrou dit d'aller mesurer ; la mesure n'existe nulle part.** La spec
*T-Rec v1.1* décrit le module qui la porte — double seuil d'échantillon, deux
métriques séparées, avis humain jamais calculé — et se déclare « implémenté et
testé, 12 tests verts ». ⚠️ **Vérifié le 26 août : `capture/quality.py` n'est ni
dans l'arbre de travail, ni dans un commit, ni sur aucune des trente branches.**
L'en-tête est à corriger avant que quelqu'un ne construise dessus.

| Travail | Où |
|---|---|
| `capture/quality.py` — `QualityReview`, `decider()`, fonction pure et rejouable | à écrire, la spec le décrit entièrement |
| Le port de persistance des avis, et son rattachement à `Capture` et `church_id` | n'existe pas |
| La saisie du relecteur — un formulaire minimal suffit à ce stade | aucun endpoint, aucun écran |
| L'appel de `decider()` — manuel, revu par le fondateur, tant que le pilote tourne | rien à automatiser |

**Sortie mesurable :** quinze avis venus de **trois églises distinctes** rendent
un verdict, et ce verdict — pas une opinion — décide si les étapes 2 et 3
s'ouvrent.

**Deux choses à ajouter à la spec avant de coder :** le relecteur **ne peut pas
être celui qui a prêché** — il sait ce qu'il a dit, donc il lit à travers les
erreurs ; et l'avis doit s'ancrer sur **des fragments identifiés**, sinon il ne
se rejoue sur rien de plus fin qu'un culte entier, alors que I33 l'exige.

---

## Ce qui n'entre dans aucun sprint tant que rien n'est tranché

| Question | Ce qu'elle bloque |
|---|---|
| ~~**Q2**~~ — **tranchée le 25 août** : le modèle tourne sur l'appareil (D52). La contradiction qui la tenait ouverte est levée dans le bon sens — c'est `JobKind.TRANSCRIRE` côté serveur qui change de sens, pas la promesse faite au pasteur | Débloque les sprints 7 à 9 |
| **Q3** — où tourne le modèle de synthèse | Les capsules de M4 |
| ~~**Le plan rédigé**~~ — **tranché le 27 août (D55)** : Urim rédige et dit pourquoi, au lieu de faire choisir. Un sprint reste à écrire pour le porter — il touche l'étage 6, la rédaction déplacée en amont, et le motif obligatoire sur chaque plan retenu | Débloque l'écran que le fondateur a jugé « du boulot en supplément » |
| ~~**L'audio qui monte**~~ — **tranché le 27 août (D56)** : mode campagne, daté, qui s'éteint après la mesure | Sprint 7, la route de capture |
| **Q17** — quelles langues pour la lecture à voix haute | Le dioula et le baoulé. La porte de sortie sans modèle — s'enregistrer soi-même — peut sortir seule |
| **Q12** — par quel mécanisme rappeler | Le rappel du samedi ; demande d'abord une définition de « pas terminé » que le domaine n'a pas |

Et le verrou qui n'est pas le nôtre : l'étape 1 de la transcription est la seule
ouverte tant que le taux d'erreur n'a pas été mesuré **dans trois églises
réelles**. Écrire le code n'y change rien.

---

## Avant de mettre l'application entre les mains de quelqu'un

Ces lignes ne se voient à aucun écran, et toutes se voient le jour de la
première installation réelle. Une demi-journée, à placer avant le premier
pilote — pas après.

- viser le serveur par défaut ; la démonstration devient l'exception ;
- signer l'APK avec un vrai keystore — **il t'appartient, je ne peux pas le
  détenir** ;
- déplacer la dérivation locale du code secret vers le coffre matériel ;
- la recherche, et le cache de séance qui évite de perdre le compte rendu en
  quittant l'écran.
