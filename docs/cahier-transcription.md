# Le versant transcription — cahier des charges

**Récrit le 29 août 2026**, sur le schéma du fondateur et sur l'état vérifié du
code. Il remplace la version du 28 et **absorbe** `sprints-back-transcription.md`,
supprimé le même jour : trois documents décrivaient le même chantier avec trois
vocabulaires — lots `A1…B3`, sprints `7…11`, sprints `S0…S5` — et se
contredisaient sur l'ordre.

**Un seul document, un seul vocabulaire : celui du schéma.**

---

## 1. Les deux branches, telles que le fondateur les a dessinées

```
                         ┌─────────┐
                         │  URIM   │
                         └────┬────┘
                  ┌───────────┴───────────┐
                  ▼                       ▼
         ①  PRÉPARER                ②  PRÊCHER
    une IA pour préparer         une IA pour enregistrer
        le sermon                 la voix, la prédication

    · pose des questions          · transcription
    · oriente le pasteur            speech-to-text
    · tranche le thème            · synthèse en texte
      avec le pasteur             · conversion en audio
```

🔴 **Le code ne suit plus ce dessin sur un point, et c'est la source de toute la
confusion.**

Dans le schéma, la **synthèse** vit dans la branche ② : on enregistre, on
transcrit, puis on synthétise. C'était vrai jusqu'au 28 août. **Ce ne l'est
plus.**

---

## 2. Ce qui a bougé, et pourquoi

**La synthèse a changé de branche.** Elle est passée de ② à ①.

| | Avant | Depuis D59 |
|---|---|---|
| D'où vient la synthèse | du transcript d'un culte | de la **préparation** — péricope, axe, plan écrit |
| Ce qu'elle exige | qu'on ait prêché **et** que la transcription soit mesurée dans trois églises | qu'on ait **écrit son plan** |
| Quand elle sort | après des mois de campagne | **aujourd'hui** |

**La raison tient en une phrase du domaine :** *une synthèse bâtie sur une
transcription non mesurée est une invention présentée comme un souvenir.* Le
verrou ne porte donc pas sur la synthèse — il porte sur **la flèche
`transcription → synthèse`** de la branche ②.

⚠️ **Ce déplacement n'appauvrit rien, il débloque.** Une préparation faite dans
Urim porte déjà toute la matière : le modèle n'a pas besoin d'avoir entendu le
culte pour le résumer. Et la dernière flèche du schéma — *convertir en audio* —
existe aussi, rattachée à ① : lecture à voix haute, et enregistrement de la voix
du pasteur.

**Le schéma reste juste comme intention.** Ce qui a changé est le chemin, pas la
destination.

---

## 3. L'état vérifié au 29 août

Relevé sur l'arbre et **éprouvé sur un téléphone réel** ce jour-là, pas déduit
des documents.

### Branche ① — préparer, puis faire entendre

| Étape | État |
|---|---|
| La conversation qui pose les questions et oriente | ✅ livré |
| L'écran où le pasteur écrit son plan | ✅ `plan_page.dart` |
| La synthèse, fabriquée depuis la préparation | ✅ route serveur + dépôt client |
| La validation — **une signature, pas un réglage** | ✅ tenue par une contrainte de base |
| La lecture à voix haute, français et anglais | ✅ sur l'appareil, rien ne sort |
| L'enregistrement de la voix du pasteur | ✅ enregistrer, réécouter, refaire |

🔴 **La branche ① est complète.** Un pasteur peut aller de sa première phrase à
une piste audio dans la langue de son assemblée, sans interprète et sans que
personne d'autre ne bouge.

### Branche ② — enregistrer, transcrire

| Étape | État |
|---|---|
| Le micro, les fragments de 30 s, la purge à sept jours | ✅ livré |
| La montée des fragments au serveur | ✅ **éprouvée le 29/08** — un culte réel est arrivé entier |
| La purge côté serveur | ✅ livrée |
| **La transcription speech-to-text** | ❌ **n'existe pas** |
| La synthèse depuis un transcript | 🔒 **verrouillée** — attend la mesure |

⚠️ **La branche ② s'arrête au serveur.** Les captures y arrivent, y vivent sept
jours, et personne ne les lit. C'est exactement ce que l'écran annonce déjà :
*« Le moteur de transcription n'est pas encore retenu. »*

---

## 4. Ce qui manque, et ce qui bloque quoi

Trois manques, de nature différente. **Aucun ne se résout en écrivant du code.**

### 🔴 Q9 — qui rattache un pasteur à son assemblée

**Le plus urgent, et le moins visible.** Une capture ne peut pas monter sans son
église : la route l'exige, et l'application refuse de la deviner — un culte
attribué à la mauvaise assemblée fausserait la mesure, dont le seuil compte
**trois églises distinctes**.

Or le rattachement n'existe nulle part : ni en base, ni dans un écran. Celui du
pilote a été fabriqué à la main le 29/08, par un script qui dit lui-même qu'il
tient une place vacante.

**Sans réponse, chaque pasteur du pilote vivra ceci :** il capte, le compteur
monte, et rien ne part. Aucun écran ne le lui dira.

Trois réponses possibles, et elles ne coûtent pas la même chose :

- **Dorea inscrit** — le plus sûr pour dix pasteurs, ne s'étend pas au-delà ;
- **le pasteur se déclare, quelqu'un confirme** — ce que la base suppose déjà
  (`is_confirmed_member`), donc le moins de code ;
- **un code d'invitation par assemblée** — le plus autonome, le plus de travail.

### ⛔ Le banc d'essai — avant toute ligne du moteur

D52 a tranché la **famille** — Whisper, sur l'appareil — jamais le gabarit.
`tiny` ou `base`, quantisé ou non, se décide en mesurant : vingt minutes de
prédication réelle sur le Galaxy A07, temps, chauffe, mémoire, taux d'erreur à
l'oreille.

⚠️ **Trois contreparties connues, à budgéter au banc :** Whisper invente du texte
sur les silences — un culte en est plein, il faut une détection d'activité
vocale en amont ; il ne sépare pas les locuteurs ; et l'accent ivoirien avec
passages en dioula fera monter le taux d'erreur.

🔴 **La première contrepartie a été mesurée le 03/09, et la parade écrite
ci-dessus n'est pas la bonne.** Whisper `tiny` invente bien sur trente secondes
de silence — *« de la fin de la fin de la fin de la fin… »* — mais le filtre
d'activité vocale était **éteint** quand le banc n'a rien tiré de lui. Ce qui
jette le texte est en aval, côté décodeur : `no_speech_threshold`, un scalaire
à 0,6. Le désarmer seul ramène l'invention ; désarmer les deux autres seuils ne
change rien.

**Le modèle sait qu'il n'entend rien** — il émet une probabilité de « pas de
parole » élevée — et son décodeur parle quand même, parce que c'est tout ce
qu'un décodeur autorégressif sait faire. La sûreté vient de **lire le drapeau et
de jeter le texte**, pas de filtrer l'entrée.

**Ce que ça ajoute au banc, et ce n'est pas un détail de réglage :** le portage
retenu — `whisper.cpp`, ONNX, autre — doit **exposer `no_speech_prob`**, et le
code Flutter doit l'appliquer. Un portage qui ne le rend pas est disqualifié,
quelle que soit sa vitesse. Sans ce seuil, le pasteur aura des boucles au milieu
de son sermon et personne ne le verra avant un dimanche.

⚠️ **Et le gabarit se mesure sur deux chiffres, pas un** (D69) : le taux
d'erreur sur la parole, et ce qui sort sur le silence. Sur le même vide,
`gemini-3.6-flash` ne bégaie pas — il écrit de la prose impeccable, indistincte
d'une vraie transcription. Plus le décodeur autorégressif est bon, plus sa panne
est invisible : monter de `tiny` à `base` achèterait de la qualité en payant en
invisibilité, et seule la moitié de l'échange se lirait dans la mesure.

Le banc qui a produit ces chiffres est `scripts/urim_mesure_transcription.py`,
côté back-dorea.

### ⏳ La mesure — trois églises, plusieurs dimanches

Quinze avis venus de **trois assemblées distinctes**, un relecteur par culte qui
**ne soit pas celui qui a prêché**. Le module qui rend le verdict est écrit ; ce
qui manque est le terrain, et le terrain ne s'accélère pas.

---

## 5. Ce que le 29 août a trouvé sur un vrai téléphone

**La journée n'a pas produit de code neuf : elle a produit des preuves, et trois
défauts que les tests unitaires ne pouvaient pas voir.**

| Défaut | Ce qu'il produisait à l'écran |
|---|---|
| `android.permission.INTERNET` absente du manifeste distribuable | « Pas de connexion » |
| Le rattachement à une assemblée inexistant | rien ne part, et rien ne le dit |
| Le trafic en clair refusé depuis Android 9 | « Pas de connexion » |
| La liste des voix jamais composée hors démonstration | **aucun bouton d'enregistrement** |

🔴 **Les trois premiers donnaient le même symptôme, et il était faux.** Le réseau
marchait, le serveur répondait. Dix pasteurs auraient cherché du signal un
dimanche matin.

🔴 **Le quatrième aurait tué le test de la voix.** L'onglet « sortie » n'offrait
aucune lecture face au serveur — tout fonctionnait en démonstration, où le jeu
d'essai fournissait les voix, et rien ne fonctionnait ailleurs. Personne ne
l'aurait vu avant de vouloir s'enregistrer.

**Ce que la chaîne a transporté, une fois réparée :** 1 336 320 octets, soit
41,76 secondes — la durée exacte affichée par l'écran. Capture créée, assemblée
rattachée, purge posée à sept jours.

---

## 6. Le parcours du pasteur, en gestes

C'est la seule séquence qui compte, et elle vit **entièrement dans la branche ①**.

| | Ce qu'il fait | Ce qui le bloque s'il saute l'étape |
|---|---|---|
| **1** | Il écrit ce sur quoi il veut prêcher | — |
| **2** | Il répond à Urim jusqu'à ce qu'un passage soit borné et un axe retenu | *« Il faut un passage servi et un axe retenu avant de porter quoi que ce soit à la voix. »* |
| **3** | **Il écrit son plan** — c'est le contenu de sa prédication, pas un formulaire | *« Écrivez votre plan : la synthèse résume ce que vous avez préparé, elle ne l'invente pas. »* |
| **4** | Il lit la synthèse et **la valide** | Rien ne se lit ni ne s'enregistre avant la signature |
| **5** | Il l'écoute en français, ou **enregistre sa propre voix** | — |

⚠️ **L'étape 3 est celle qu'on oublie.** Au 29/08, **aucune** des sept
préparations en base n'avait un seul point écrit — c'est pourquoi la synthèse
refusait partout. Le pas qui manque n'est pas technique : c'est que quelqu'un
écrive un sermon.

---

## 7. Ce qui reste dehors

- **L'interprétation par l'équipe Dorea** — attend des interprètes recrutés, un
  délai annonçable et un prix. *Un état « soumise » qui ne bouge jamais est pire
  que pas de bouton.*
- **Le clonage de voix** — attend ses trois gardes : consentement par pièce,
  écoute avant diffusion, provenance toujours lisible.
- **La publication vers la plateforme Dorea** — bloquée par Q9, comme la capture.
- 🔴 **Une dette part avec la première paire collectée, jamais après** : le texte
  des réglages promet aujourd'hui *« aucun entraînement de modèle sur votre
  contenu »*. Collecter en le laissant serait le seul défaut de ce chantier qui
  ne se rattrape pas.

---

## 8. Bornes à ne pas oublier

**`CAPTURE_AUDIO_UPLOAD_ENABLED=true`** est ouvert dans le `.env` local depuis le
29/08. C'est une borne **datée** (D56) : le transcript se fabrique sur
l'appareil, donc l'audio ne monte que pour se comparer à une référence humaine,
le temps de la campagne. **Elle se referme au verdict** — sinon la route se
gardera par inertie et coûtera des mégaoctets sur chaque forfait à Abidjan.

**La politique réseau** ouvre le trafic en clair pour **un seul nom**, celui du
tailnet, dont le trafic est déjà chiffré par WireGuard. Elle se supprime
entièrement le jour où le tailnet délivre un certificat — l'interrupteur est
dans la console d'administration Tailscale.

---

## Où vit le reste

- **Les décisions** — `decisions.md`, la seule source des `D…`.
- **Le raisonnement produit des sprints 7 à 11** — `sprints-7-11-la-voix.md`.
- **Le découpage serveur** — `back-dorea/docs/Chantier_Transcription_Serveur_2026-08-28.md`.
