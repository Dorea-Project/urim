# Plan de correction — la branche ② après D70 et D71

**Écrit le 4 septembre 2026**, le jour où le tronc a été renversé. Les décisions
disent maintenant *la pièce*, *l'éditeur*, *jamais le brut* ; le code ne connaît
que la capture. Ce document dit comment on rattrape l'écart, dans quel ordre, et
pourquoi cet ordre-là.

Il couvre les **deux dépôts**, comme `back-dorea-a-faire.md`.

---

## La règle d'ordre

Trois principes, et ils se contredisent parfois — quand c'est le cas, le premier
gagne.

1. **Ce qui ne demande aucune ligne passe avant tout.** Un test qui invalide le
   plan doit être fait avant qu'on écrive le plan dans le code.
2. **Ce qui retire du code passe avant ce qui en ajoute.** Une soustraction ne se
   débogue pas.
3. **Ce qui débloque le plus par ligne écrite ensuite.** Ce qui coûte cher et ne
   débloque rien va en dernier, même si c'est ce dont on parle depuis le début.

---

## 0. Éprouver 1 h 30 sur le Galaxy A07 — **aucune ligne de code**

⛔ **Rien d'autre ne commence avant.**

La plus longue capture jamais éprouvée fait **41,76 secondes**, le 29 août, sur
un téléphone réel. Le pasteur en veut **5 400** — cent vingt-neuf fois plus long.
Tout le reste de ce plan suppose que la capture tient ; personne ne l'a vu.

**Ce qu'il faut relever, dimanche, avec le code d'aujourd'hui :**

| Ce qu'on regarde | Pourquoi ça peut casser |
|---|---|
| La durée réellement tenue | c'est la seule question |
| Fragments écrits vs durée affichée | 180 attendus ; un écart dit qu'on perd de l'audio |
| Espace disque | ~173 Mo, plus l'application |
| Survie écran éteint, une heure et demie | Android tue les services qu'il croit oisifs |
| Un appel entrant au milieu | le micro est pris par le système |
| Chauffe et batterie | un A07 n'a pas de marge |
| Montée des 180 fragments | sur la connexion d'une église |

**Sortie mesurable :** un relevé écrit, et une réponse binaire. Si la capture ne
tient pas 1 h 30, **ce plan s'arrête ici** et devient un chantier de fiabilité de
capture.

---

## 1. Couper la montée automatique du brut — **une soustraction**

D71 dit que rien ne transcrit la matière brute. Or les fragments montent
aujourd'hui **automatiquement**, pendant le culte. 🔴 **Il ne reste donc aucune
raison de les envoyer** — et ils partent vers un dossier serveur nommé
`media_uploads`, commenté *« dev »*, alors que D65 exige un stockage objet qui
n'est pas construit.

⚠️ **À vérifier avant de couper, et c'est le seul risque de cette étape :** est-ce
que quelque chose se sert des fragments montés ? Le pilote, la mesure des trois
églises, un écran d'administration. Si oui, le nommer et le rattacher à la pièce
plutôt que de le supprimer.

**Le geste :** l'envoi automatique s'arrête ; `fragment_outbox` reste, sa file et
son rejeu servent la pièce quand elle existera. `attacherEglise()` et
`sansEglise()` ne bougent pas.

**Sortie mesurable :** un culte se capte de bout en bout et **rien ne quitte le
téléphone** sans un geste du pasteur.

---

## 1bis. Éteindre la synthèse fabriquée depuis le plan — **la seconde soustraction**

D72 renverse D59 : la préparation ne porte ni transcription ni synthèse.

**Ce qui s'éteint** — `GET /studies/{id}/synthese`, `POST
/studies/{id}/synthese/validation`, `synthese_service.py` et son dépôt. Avec eux
tombe la raison d'être de D66 : la table reste, sa clé change — elle pendra d'une
**pièce**, plus d'une étude.

**Ce qui change d'attache sans être détruit** — la validation par signature,
`aloud_reader`, `voice_track_*`. Les outils restent entiers. Et **les écrans ne
bougent pas** : `synthesis_page.dart`, `capture_shell.dart`,
`aloud_view_model.dart` et `voice_track_view_model.dart` vivent déjà sous
`presentation/transcription/`.

🔴 **Le prix, écrit ici pour qu'il ne surprenne personne.** La synthèse qui
remplace celle-ci naît du transcript, et le transcript attend les quinze avis
dans trois églises. **La synthèse, sa signature, sa lecture à voix haute et la
piste de voix sont donc éteintes pour des mois, pas pour des jours.** La branche
① ne va plus « de la première phrase à une voix que l'assemblée entend » : elle
rend la conversation, le plan, la fiche de chaire et les diapositives.

⚠️ **Et cette étape met D22 de côté délibérément** — *on ne démolit pas avant
d'avoir remplacé*. C'est la seule du plan qui le fasse, le fondateur l'a tranché
en connaissant le prix, et la raison est écrite dans D72 : un résumé d'intention
qui passe pour un résumé de sermon est la même erreur qu'une invention de modèle
— *rien plutôt qu'une vraisemblance*.

**Sortie mesurable :** plus aucune route ne fabrique de synthèse à partir d'une
étude.

---

## 2. Se déplacer dans la réécoute — **petit, et le plus bloquant**

`capture_playback` sait rejouer et ne sait rien d'autre : ni chercher, ni mettre
en pause, ni donner une position. Sur 1 h 30, retrouver la fin de la prédication
en lecture linéaire prendrait **une heure**.

`audioplayers` (déjà au dépôt, `^6.7.1`) le fait. L'application ne l'expose pas.

**À écrire :** position courante, durée totale, `seek()`, pause et reprise, et
une barre qu'on tire. Rien de neuf en dépendances.

**Sortie mesurable :** le pasteur trouve la frontière prédication / prière en
quelques secondes, et l'écoute des deux côtés pour la placer juste.

---

## 3. Couper — **de l'arithmétique, pas du traitement du signal**

Le PCM est à débit constant : **32 000 octets valent une seconde**. Une coupe à
la 62ᵉ minute est un décalage de 119 040 000 octets. Pas de décodage, pas de
ré-encodage, pas de bibliothèque.

La seule subtilité est la fragmentation : une borne tombe *à l'intérieur* d'un
fragment de trente secondes, donc on lit depuis le fragment `i` à l'octet `o`.
C'est de l'indexation, pas de l'audio.

**À écrire :** `decouper(capture, debut, fin) → fichier`, et l'en-tête WAV de
quarante-quatre octets que `capture_playback` sait déjà poser.

🔴 **Ne pas ré-encoder à cette étape.** Une pièce sort en WAV — ~86 Mo pour
quarante-cinq minutes. C'est gros, et c'est volontaire : aucun codec, aucun canal
natif, aucune bibliothèque neuve, trois choses qui feraient dérailler un MVP. Si
le partage bute sur la taille, **on paiera l'AAC en sachant pourquoi**, après
l'avoir vu échouer.

**Sortie mesurable :** deux fichiers écoutables tirés d'une capture de 1 h 30,
sans les chants ni le bruit du début.

---

## 4. La pièce comme objet de premier rang

C'est l'étape qui coûte le plus, et tout ce qui suit en dépend.

**Côté application** — un modèle et un magasin, sur le patron de
`voice_track_store` : un index tenu à côté du disque est **assumé** ici, parce
qu'aucune promesse de purge ne pèse sur la pièce (c'est la règle de
`CaptureStore` qui ne s'applique pas, pas une entorse).

**Côté serveur** — une table `urim_piece` : la capture d'origine, les bornes,
le titre, l'état, la date de publication.

⚠️ **Et une contrainte à desserrer** : `urim_reflection.capture_id` est **unique
et non nul** — un Retour par culte. Un dimanche donne maintenant plusieurs
pièces. C'est une migration, pas un réglage.

**Sortie mesurable :** un dimanche produit deux pièces nommées, qui survivent à
la purge du brut au septième jour.

---

## 5. La purge s'annonce

Les sept jours deviennent un **délai de découpage**, pas un délai de publication.
Ils ne changent pas de durée : la matière brute est ce que le micro a pris sans
intention, et le risque ne décroît pas.

**Ce qui change, c'est qu'on le dit :**

- **avant d'enregistrer** — ce qu'il perdra s'il ne découpe pas ;
- **pendant la semaine** — *« il vous reste deux jours pour découper votre culte
  du 1er septembre »* ;
- **jamais au septième jour**, où il serait trop tard pour agir.

Un pasteur qui perd sa prédication en découvrant la règle le jour où elle
s'applique est un pasteur qu'on a trahi, même si la règle était juste.

---

## 6. Publier une pièce sur Dorea app

**N'existe nulle part dans le code** — vérifié le 4 septembre, aucun module de
sortie, aucune route.

**D61 est à réécrire** : *« ne porte que la synthèse validée »* devient *porte
l'audio retravaillé, et la synthèse si elle existe*. Le reste de D61 tient sans
changement — un geste consenti, **une fois par pièce** — et convient d'ailleurs
mieux au parcours réel qu'à celui pour lequel il a été écrit : trois pièces,
trois consentements, trois jours.

**Sortie mesurable :** le pasteur publie la prière le mardi et la prédication le
vendredi, depuis son téléphone.

---

## 7. L'interprétation — **rien ne la bloque, et c'est nouveau**

L'interprète de l'équipe Dorea **écoute la pièce**. Ni Whisper, ni `decider()`,
ni synthèse. Cette branche attendait un verrou qui ne l'a jamais concernée.

**À écrire :** une file avec un état — soumise, prise, rendue, refusée — une
langue, et **un délai annoncé**.

⚠️ **Le délai est une contrainte de service, pas de code, et il est serré :** le
pasteur demande le samedi et publie le samedi soir. Si l'équipe ne tient pas la
journée, le parcours ne tient pas — et il vaut mieux le savoir avant de
construire la file que de l'apprendre par un pasteur qui attend.

⚠️ **D63 change de paire au passage.** Le corpus d'apprentissage devait s'appuyer
sur *synthèse validée ↔ interprétation*, segmentées et alignées. Si l'interprète
part de l'audio, la paire devient *audio ↔ interprétation* : un alignement plus
dur, et **un consentement à reformuler** — ce qui est écrit dans les réglages
doit être corrigé en même temps que la collecte commence, jamais après.

---

## 8. La transcription — derrière le verrou, et sur une pièce

Le verrou n'a pas bougé de sévérité : **15 avis et 3 églises distinctes**, seuils
0,70 de lisibilité et 0,80 de citations, `decider()` qui tranche. Il ne garde
plus que la flèche `transcription → synthèse`.

**Ce que les mesures des 2 et 3 septembre imposent en plus :**

- le portage natif doit **exposer `no_speech_prob`** — critère de
  disqualification, à vérifier *avant* de choisir le runtime, pas après ;
- le gabarit se mesure sur **deux chiffres** : le taux d'erreur sur la parole, et
  ce qui sort sur le silence (D69) ;
- le port `Transcriber` prend **une pièce**, pas les fragments d'une capture
  (D71).

Puis la synthèse née du transcript, puis l'epub — **et le transcript s'affiche à
côté d'elle, jamais la synthèse seule** (D71). C'est la seule parade du produit
contre l'invention.

⚠️ **L'epub n'existe pas.** Les livrables savent écrire `.pptx`, `.docx` et
`.pdf` ; il faudra un écrivain de plus.

---

## Ce qui ne bouge pas

- Le verrou de la mesure — 15 avis, 3 églises, les deux seuils.
- La purge de la matière brute au septième jour. *Un micro capte la salle.*
- **D6 — la capture ne refuse jamais.** *Ce qui n'est pas capté dimanche est
  perdu pour toujours.*
- D53 et le PCM 16 kHz — jusqu'à ce que publier exige mieux, et pas avant de
  l'avoir mesuré.

---

## Ce qui reste ouvert, et qui ne se code pas

🔴 **Le rattachement pasteur ↔ assemblée** (Q9). Il ne bloque plus la capture
depuis D68, mais il bloque toujours la mesure — dont le seuil compte trois
églises *distinctes*. Celui du pilote a été fabriqué à la main par un script qui
dit lui-même qu'il tient une place vacante.

**Le stockage objet** (D65) n'est pas construit ; l'audio du pilote est sur le
disque du serveur, dans `media_uploads`. L'étape 1 réduit l'urgence sans la
supprimer — les pièces publiées devront bien vivre quelque part.

**Le délai de l'équipe d'interprétation**, qui décide si le parcours du samedi
tient.

---

## Ce que ça donne comme ordre, en une ligne

**0 → 1 → 2 → 3** rendent le dimanche du pasteur utile **sans toucher à un seul
modèle** — et sans qu'une ligne de `back-dorea` bouge, sauf la soustraction de
l'étape 1.

**4 → 5 → 6 → 7** font le produit : la pièce, l'annonce, la publication,
l'interprétation.

**8** vient en dernier parce qu'il coûte le plus, qu'il est le seul à traverser
le verrou, et qu'il est **le seul dont le pasteur a dit qu'il pouvait s'en
passer**.
