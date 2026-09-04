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

⚠️ **Trois corrections au 06/09, relevées dans le code plutôt que dans les
notes.** La première version de cette étape en portait autant d'erreurs.

**Les fragments ne montent pas pendant le culte.** Rien ne sort tant qu'il
prêche. L'envoi part **à l'arrêt du micro** — le pasteur a encore le téléphone en
main, c'est le meilleur moment — puis retente à chaque ouverture de
l'application et à chaque retour au premier plan. Conséquence : **couper la
montée ne change rien au test de 1 h 30**, contrairement à ce que cette étape
affirmait. Ce n'est donc pas une urgence, et l'ordre 1-puis-0 n'a pas lieu
d'être.

**Le stockage objet de D65 est construit** : `S3FragmentStore` existe, avec sa
bascule sur `s3_endpoint_url` et le même interrupteur que les médias. La note de
D65 dit encore le contraire — elle date d'avant.

**Et l'audio ne va pas dans `media_uploads`** mais dans `capture_audio_dir`, un
réglage dédié.

✅ **Le risque de cette étape est levé, et par le code.** Le port `FragmentStore`
n'a que `put` et `purge` : **aucune lecture, nulle part**. Rien ne consomme les
fragments montés — ni transcription, ni mesure, ni écran. Ils partent, ils
dorment sept jours, ils sont effacés.

🔴 **Ce qui reste, et qui suffit :** l'application transporte 173 Mo d'une vraie
salle d'église — **avec les voix qui s'y trouvaient** — vers un serveur qui ne
les ouvrira jamais. D71 a retiré la dernière raison de le faire.

**Le geste :** l'envoi automatique s'arrête ; `FragmentOutbox` reste, sa file et
son rejeu serviront la pièce. `attacherEglise()` et `sansEglise()` ne bougent
pas.

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

## 2. Se déplacer dans la réécoute — ✅ **fait, et plus petit qu'annoncé**

⚠️ **Correction du 06/09 : j'avais écrit que rien ne savait chercher. C'est
faux.** `CapturePlayback` est un assembleur de fichier, pas un lecteur — il ne
cherche pas parce que ce n'est pas son travail. Le port `TrackPlayer`, lui,
porte déjà `seek`, `pause`, `resume`, `onPosition` et `onDuration`, avec des
commentaires qui expliquent pourquoi. **L'étage manquant n'était pas le lecteur,
c'était l'écran qui s'en sert.**

Livré avec l'éditeur (§3) : tête de lecture, ±10 s, pause qui garde l'endroit,
appui sur l'onde pour se déplacer, et suivi automatique quand la lecture sort du
cadre.

---

## 3. Couper — ✅ **livré le 06/09**

L'éditeur existe : `PieceCutter`, l'onde (`Waveform`), les deux vues et l'écran
`PieceEditorPage`, sur la route `/capture/:id/tailler`. Trente-cinq tests.

🔴 **Le choix d'interface qui gouverne l'écran, et qui n'était pas évident.**
Sur un téléphone, une heure et demie fait huit secondes par pixel : une poignée
qu'on traîne au doigt couvre une minute de prédication. **On ne tire donc pas
les bornes, on les pose** — le pasteur écoute, s'arrête à la frontière, appuie
sur « début ici ». L'onde sert à viser grossièrement et à se repérer ; l'oreille
tranche. Et deux ondes plutôt qu'une : l'aperçu du culte entier dit *où l'on
est*, le détail zoomé permet de viser.

**Ce que l'onde a coûté, et pourquoi elle en valait la peine.** 173 Mo ne se
relisent pas à chaque image : on calcule **dix crêtes par seconde, une fois**,
dans un isolat, et on les garde à côté des fragments — 54 000 octets pour
quatre-vingt-dix minutes, trois mille fois plus léger que la matière. Le
condensé vit **dans** le dossier de la capture : il décrit la matière brute, il
doit mourir avec elle au septième jour.

⚠️ **Deux ports sont devenus des interfaces au passage** — `WaveformDigest` et
`CapturePlayback` — pour la raison que le dépôt donne déjà à propos de
`TrackPlayer` : un isolat et une écriture disque ne répondent pas sous
`flutter_test`, et les brancher en dur rendait l'éditeur intestable.

### Le partage — ✅ **livré le 06/09, et le mur n'existait plus**

⚠️ **`share_plus` n'était plus bloqué depuis un moment, et personne ne l'avait
regardé.** Le conflit était `win32 ^5` contre un coffre à secrets en `^4` ; le
coffre est passé en `^11` entre-temps. Vérifié en résolvant les dépendances,
pas en relisant la note — qui disait encore le contraire dans `decisions.md`.

Une pièce s'envoie donc par la feuille de partage du téléphone. 🔴 **C'est le
seul débouché qui existe aujourd'hui, et il compte plus que la publication sur
Dorea app** : le canal réel d'une assemblée est WhatsApp, pas une plateforme qui
n'existe pas encore.

**Livré avec** : renommer une pièce, et la supprimer — le magasin savait déjà le
faire, il manquait les gestes. La suppression se confirme, et la confirmation ne
demande pas « êtes-vous sûr » : elle dit que si le culte a passé ses sept jours,
la matière n'existe plus et rien ne se retaille.

⚠️ **La même dette reste ouverte pour les documents.** La fiche de chaire et les
diapositives sont toujours posées dans un dossier que le pasteur doit aller
ouvrir. Le mur est tombé pour elles aussi ; le bouton n'est pas posé.

**L'arithmétique, pour mémoire :**

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

## 4. La pièce comme objet de premier rang — ✅ **côté application, le 06/09**

**Livré** : `SermonPiece`, `PieceStore`, le titre saisi dans l'éditeur, et la
liste des pièces dans l'onglet « sortie » d'un culte — qui n'attendait jusque-là
qu'une synthèse validée qui ne viendra pas.

Le magasin suit le patron de `voice_track_store` : un compagnon JSON à côté de
l'audio, et **l'audio fait juge** — un compagnon orphelin ne rend pas de pièce,
parce que l'offrir à l'écoute promettrait un son qui n'existe plus.

🔴 **Un index tenu à côté du disque est assumé ici**, alors que `CaptureStore` le
refuse. Sa règle protège une promesse de suppression : une application qui croit
avoir effacé un audio encore présent ment sur quelque chose de grave. **Cette
promesse n'existe pas pour une pièce** — rien n'y expire, le seul effacement est
demandé. Ce n'est pas une entorse, c'est une règle qui ne s'applique pas.

**Un choix d'interface** : le titre n'est pas obligatoire. Imposer un nom avant
de couper mettrait une question entre le pasteur et son geste ; à défaut on
prend les bornes, deux pièces restent distinguables, et il renomme quand il
veut. Le champ se vide après chaque coupe — « prière » collé à la prédication
serait une erreur qu'on ne verrait qu'après publication.

### Ce qui reste de l'étape 4 — **côté serveur**

Une table `urim_piece` : la capture d'origine, les bornes, le titre, l'état, la
date de publication. Elle ne devient nécessaire qu'à l'étape 6, quand une pièce
doit exister ailleurs que sur le téléphone.

⚠️ **Et une contrainte à desserrer** : `urim_reflection.capture_id` est **unique
et non nul** — un Retour par culte. Un dimanche donne maintenant plusieurs
pièces. C'est une migration, pas un réglage.

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

~~**Le stockage objet** (D65) n'est pas construit~~ — **faux, corrigé le 06/09** :
`S3FragmentStore` existe et bascule sur `s3_endpoint_url`. Ce qui reste ouvert
est plus étroit : **une pièce publiée devra vivre quelque part**, et ce n'est ni
`capture_audio_dir` — que la purge visite — ni le téléphone.

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
