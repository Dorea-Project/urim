# Urim — les sprints

Établi le 20 août 2026, contre l'état réel des deux dépôts.

## Comment ils sont ordonnés

**Par ce qui débloque quoi, pas par difficulté.** Un sprint ne se termine pas
parce que le temps est écoulé : il se termine quand sa **sortie mesurable** est
vraie. Elle est écrite avant de commencer, et elle se vérifie sur un appareil,
pas dans un tableau.

Trois règles tenues d'un sprint à l'autre :

- **Ce que le serveur sert déjà passe avant ce qu'il faut construire.** Vingt et
  une routes servies, six appelées : c'est là qu'est le produit non livré.
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

## Ce qui n'entre dans aucun sprint tant que rien n'est tranché

| Question | Ce qu'elle bloque |
|---|---|
| **Q2** — quel moteur de transcription, et où tourne-t-il | M3 entier, la capture, l'espace utilisé. La file serveur prévoit `transcrire` pendant que la maquette promet « sur l'appareil » : les deux ne peuvent pas être vrais |
| **Q3** — où tourne le modèle de synthèse | Les capsules de M4 |
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
