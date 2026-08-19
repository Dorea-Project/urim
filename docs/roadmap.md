# Urim — feuille de route

## Ce qu'est Urim

Un outil de préparation de messages et d'enseignements. On y pose une idée en
l'écrivant ou en la dictant, ou l'on y verse un enregistrement à transcrire.
Urim convoque les textes, propose une synthèse, et laisse la décision à celui
qui prêche.

## Méthode de travail

**Un dépôt, une branche par module.** Le module vit sur `feat/<module>`,
fusionné dans `main` une fois validé. Pas de branches parallèles à
resynchroniser.

**Un module n'est fini que si les quatre questions ont une réponse.** C'est ce
qui restait de valable dans le découpage en quatre pistes — la couverture, pas
les dossiers.

| | Question |
|---|---|
| Métier | Le domaine et la persistance tiennent-ils sans l'interface ? |
| Interface | L'écran gère-t-il le vide, le chargement et l'erreur ? |
| Tests | Les règles sont-elles verrouillées par des tests ? |
| Décisions | Qu'a-t-on tranché, et qu'est-ce qui reste ouvert ? |

Les arbitrages et les questions en attente vivent dans
[`decisions.md`](decisions.md), pas dans le fil d'une conversation.

## État

| Module | État |
|---|---|
| Socle Clean Architecture / MVVM | Fait |
| Charte graphique, jetons, Nova Cut | Fait |
| Lancement et présentation animée | Fait |
| Inscription, connexion, code oublié | Câblés sur le **vrai contrat** du backend |
| Socle sécurité : jetons au coffre, rotation, identifiant d'appareil | Fait |
| Politique de confidentialité | Fait |
| Domaine des préparations | Fait |
| Persistance des préparations | Sur le **serveur** ; l'appareil garde ce qu'il faut pour continuer hors réseau — **Q4 tranchée** |
| Profil et réglages | Fait — églises et appareils **simulés** |
| Accueil | Branché sur le **vrai fil** du serveur (`GET /urim/studies`) |
| Création, fil guidé | Bâtis sur le **contrat du serveur** (`TurnView`) — le moteur, lui, reste dû |
| Relecture d'une prédication, synthèse à valider | Écrans faits — transcription et capsules **scriptées** |

Le domaine du discernement pastoral (`PastoralQuestion`, `ScriptureAnchor`,
`Decision`) reste sur `feat/core-architecture`, non fusionné. Il ne correspond
pas à ce que fait Urim ; il attend une réponse à Q7.

## Modules à venir

### M1 — Accueil et création

**Branché sur le serveur.** `GET /api/mobile/urim/studies` rend une ligne par
préparation, la plus fraîchement touchée en tête, **sans rejouer le moteur** —
rejouer est le mode normal de lecture d'*une* préparation, pas de vingt.

Ce que cela a changé : les quatre états inventés côté application ont laissé la
place au vocabulaire du moteur. `await_decision` **est** « Rend la main » ; la
traduction en français vit à un seul endroit (D26). Ce que le fil ne porte pas,
et ne portera pas : la phrase d'Urim. Elle naît du rejeu, et arrive en ouvrant
la préparation.

Un build de démonstration garde son fil : le magasin en mémoire est projeté sur
le même contrat, sur la même bascule que le parcours d'entrée simulé.

**Q4, étapes 1 et 2 faites.** Ce que le pasteur écrit ne se perd plus : la
barre de saisie et le formulaire d'ouverture posent leur texte sur l'appareil
avant tout appel, et un envoi refusé garde la phrase (D32). Et l'accueil comme
le fil s'ouvrent sur ce qu'ils savent déjà, en disant d'où ça vient, puis se
rafraîchissent (D34) — huit secondes de blanc deviennent zéro, et un accueil
vide devient le travail en cours.

**Étape 3a : décider et écarter sans réseau.** Le geste est noté et rejoué
dans l'ordre au retour de la connexion — la cascade du serveur fait le reste,
sans un mot de code de fusion. Ce qu'il ne fait pas, et ne fera pas : montrer
le tour suivant. Seul le moteur le sait (D36).

**Étapes 3b et 4.** Une parole aussi attend le réseau, avec une clé
d'idempotence que le serveur reconnaît — sans quoi la renvoyer coûterait un
appel de modèle et peut-être une autre phrase que celle déjà lue (D38). Et quand
le corpus a été relu depuis l'ouverture, l'écran le dit : le tour n'est pas
faux, il n'est plus mot pour mot celui qu'on avait sous les yeux.

**Q4 est close.** Sa dernière question est tranchée : on n'ouvre pas hors
réseau, parce qu'ouvrir n'est pas enregistrer une phrase mais **la faire lire**,
et le corpus n'est pas sur l'appareil (D41). La frontière tient en une ligne :
*on continue sans réseau, on n'ouvre pas* — et le refus dit sa raison plutôt que
de laisser croire à une phrase perdue.

Restent dus : la recherche. Une carte transcrite ne porte plus de pastille : le
moteur ne connaît que les préparations écrites.

### M2 — Préparation écrite

**Bâti sur le contrat du serveur.** Le fil rend un `TurnView` : trois phrases
qui ne viennent pas du même endroit — ce qu'Urim vient de faire, **son motif
tel quel**, et sa question — puis les sept natures de bloc, dans l'ordre où le
serveur les donne.

Quatre gestes, et ils disent le produit : ouvrir, **décider**, **écarter**,
**parler**. Écarter n'avance aucun étage ; il apprend seulement au tour suivant
de ne pas reproposer — sans quoi un moteur qui rejoue n'a aucun moyen de s'en
souvenir. Les pesées postent sur **leur** étage, pas sur celui du tour.

Ce qui a disparu : l'historique. Le moteur rejoue à chaque lecture (D28), donc
il n'y a qu'un tour, et ce qui est au-dessus est le compte rendu de la séance.
Ce qui a été gagné : la barre ne se ferme jamais, et écrire « L'Église » vaut
la toucher — le serveur résout d'abord ce qui désigne l'écran.

**Éprouvé contre le vrai moteur.** Les tests d'écran sont nourris par les
réponses exactes du serveur, capturées contre le corpus réel (D31), et un test
tagué `live` traverse la couche de données jusqu'au serveur qui tourne.

Ce que cette confrontation a appris, et qu'aucune donnée écrite à la main
n'aurait dit : le tour d'ouverture sert **seize** pastilles mêlant les dix loci
et des passages, un motif peut faire **1 423 caractères**, et dix pesées plus
dix-huit couples plan × matière reviennent à **chaque** tour comme décor
ambiant. Rien ne débordait — mais un tour faisait jusqu'à **onze écrans**.

**Réparé** : le tour dit désormais de quoi il parle (`speaks`), l'écran déplie
ce bloc-là et replie le reste sous son intitulé et son nombre. 11,1 → 3,4
écrans à l'étage des mises en forme, 9,0 → 1,3 au thème (D42, D43).

**Offert aussi** : le texte et le contexte. Ils étaient dans la charge depuis le
premier jour — les versets qu'aucun bloc ne portait, la note de contexte
calculée à l'ouverture, écrite dans la trace, stockée, et jamais montrée. Ils se
nomment maintenant sous le tour, repliés, et une touche les ouvre : 0,1 écran de
plus, et une question que le pasteur n'a plus à poser (D44).

Restent dans la même charge et toujours sans écran : les **variantes de
version** et les mots de l'original.

Le moteur, lui, n'est plus le trou qu'on croyait : **Q14 et Q15 sont
répondues**, et 4 561 unités relues couvrent les 66 livres. Un build de
démonstration garde un mannequin qui imite la forme du contrat, pas le
raisonnement.

### M3 — Enregistrement et transcription

**Écran de relecture fait.** Forme d'onde, durée, fragments acquittés, textes
convoqués — annoncés ou reconnus, prévus ou non — constats, et la réserve sur
la séparation des locuteurs.

Dépend de **Q2**, et de la contradiction sur les fragments qui « attendent le
réseau » alors que la transcription est promise sur l'appareil. La capture
elle-même n'existe pas : « Reprendre l'enregistrement » est inactif.

**Ce que le serveur en porte, lu le 19/08.** Cinq tables — capture, file de
travaux, segments, versets cités, retour — et un module de domaine **pur de
175 lignes** qui tient deux règles : *la capture n'est jamais refusée* (ce qui
n'est pas capté dimanche est perdu pour toujours ; c'est la transcription qui
est différée), et *un travail abandonné laisse le transcript en `partielle`,
jamais un silence*. À côté de cela, **rien** : aucune route de capture, aucun
travailleur qui consomme `urim_capture_job`, aucun port de fournisseur de
transcription, aucune extraction de versets, aucun alignement.

**Et le séquencement est verrouillé volontairement.** `capture/domain.py`
l'écrit : capture, transport, transcript brut **non exploité**, jusqu'à mesure
du taux d'erreur *dans trois églises réelles*. Les étapes 2, 3 et 4 —
extraire les versets, aligner, synthétiser — n'ouvrent pas avant cette mesure.
Écrire tout le code n'y changerait rien : ce qui manque ensuite est du terrain,
et le terrain ne s'accélère pas.

**Ce qui est donc faisable dès maintenant, et honnête :** l'étape 1 seule —
capter, conserver l'audio sept jours, afficher le transcript brut sans rien en
tirer. C'est exactement ce que le serveur s'autorise, et c'est ce qui permet
d'aller mesurer.

### M4 — Synthèse d'Urim

**Écran de validation fait.** Capsules horodatées, verset non réécrit, réserve
sur ce qui vient du modèle, et la règle qui tient tout : rien ne sort avant
validation (D17).

Dépend de **Q3** pour les capsules, de **Q17** pour la lecture à voix haute —
voix de synthèse, dioula, baoulé, et la voix de celui qui a prêché.

### M5 — Lecture biblique

Affichage d'un passage, contexte, comparaison de versions, reconnaissance des
citations dans une transcription.

**Le corpus est déjà servi** : `GET /urim/passages` rend un passage sans ouvrir
de préparation, `GET /urim/lemmes` rend la concordance. Ce que Q1 bloque encore
n'est donc pas la lecture, c'est ce que l'appareil embarque pour lire **hors
connexion**. Le premier écran peut se faire sans attendre ; la reconnaissance
des citations, elle, reste derrière Q2.

### M6 — Compte

**Fait en partie.** Le profil affiche le nom, le monogramme, le numéro, les
églises rattachées et les appareils ; les réglages tiennent la lecture,
l'Écriture, le hors connexion, les rappels et le contenu.

Ce qui marche vraiment : le nom affiché, la taille du texte de lecture,
l'affichage systématique de la référence. Tout le reste est montré **inactif**
avec ce qu'il attend (D13).

La suppression du compte, promise par la politique de confidentialité, est
**tenue des deux côtés** : le serveur efface le contenu et ferme le compte
(`/account/delete`, confirmé par SMS), l'appareil se vide ensuite (**D47**).
Le numéro redevient libre — se réinscrire crée un compte neuf, qui ne retrouve
rien. Le changement de code secret passe par le profil, sur la route que le
serveur avait prévue pour lui — `/account/change-password` (**D46**) ; le
changement de numéro aussi, avec le code envoyé sur le nouveau numéro
(**D48**).

Restent dus :

- les églises — `GET /iam/me` rend le profil **et** les appartenances en un
  appel : plus rien à trancher, seulement à brancher (**Q9**) ;
- les appareils — et d'abord côté serveur : il ne compte rien, ne refuse pas le
  troisième et ne sait pas les lister. L'écran affiche « 2 sur 2 » devant un
  serveur qui en accepterait dix (**Q11**, **Q23**) ;
- les trois réglages hors connexion — **Q1**, **Q2**, **Q10** ;
- le rappel du samedi — **Q12** ;
- l'espace utilisé, qui ne veut plus dire grand-chose depuis que les
  préparations vivent sur le serveur : reste l'audio des transcriptions — **Q2**.

## Deux chantiers, deux ordres de grandeur

Ce n'est pas la même nature de travail, et les mettre côte à côte évite de les
arbitrer au ressenti.

| | Préparation | Transcription |
|---|---|---|
| Contrat serveur | **complet et testé** — 21 routes, le client en appelle 6 | 5 tables et 175 lignes de domaine pur ; aucune route, aucun travailleur |
| Moteur | réel et déterministe — 4 561 unités relues, 66 livres | aucun fournisseur choisi (**Q2**) |
| Données à l'écran | vraies, sauf le mannequin de démonstration | **scriptées** (`InMemoryTranscriptionRepository`) |
| Décisions en attente | aucune | Q2, Q3, et la promesse « sur l'appareil » à trancher |
| Ce qui reste | brancher des écrans sur un contrat qui répond | bâtir la chaîne, puis **mesurer dans trois églises** |

Autrement dit : préparer, c'est **assembler ce qui répond déjà** ; transcrire,
c'est construire la chaîne entière, prendre une décision produit, et attendre
des dimanches réels.

Ce que le serveur sert et que l'application ignore encore :

| Route | Ce que ça ouvre |
|---|---|
| `POST /urim/studies/{id}/deliverable` + `GET /urim/deliverables/{id}` + `/fichier` | Le deck et la note, soumis au contrôle des citations |
| `POST /urim/studies/{id}/elements` | Le squelette homilétique — dix champs, aucun imposé |
| `POST /urim/studies/{id}/supports` | La chaîne de textes, avec son contrôle de référence |
| `POST /urim/studies/{id}/articulations` | Faire articuler un point, dans l'atelier |
| `GET /urim/passages`, `GET /urim/lemmes` | Lire un passage, chercher un mot de l'original |
| `POST /urim/studies/{id}/preached`, `GET /urim/preached`, `/couverture` | L'archive, et où l'on est allé dans l'Écriture |
| `GET /iam/me` | Les églises réelles du profil |

## Les trois briques lourdes

Elles ne bloquent pas M1 et M2, mais il ne faut pas les promettre à la légère.

**Reconnaissance vocale sur l'appareil.** La maquette annonce « transcrit sur
l'appareil » et la politique promet qu'aucun contenu ne part chez un tiers.
Cela suppose un moteur embarqué, francophone, capable de tenir un message de
trente-huit minutes.

**Détection des citations bibliques** dans un texte parlé, avec les
approximations d'un orateur et les variantes de traduction. « Actes 2.42 —
reconnu dans l'enregistrement » n'est pas une recherche de chaîne.

**Le modèle de synthèse.** « Aucun entraînement de modèle sur ton contenu »
contraint fortement l'endroit où il tourne et le fournisseur retenu.

**La lecture à voix haute en dioula et en baoulé.** Une quatrième brique, née
de la maquette de synthèse : deux langues très peu dotées, une synthèse vocale,
et une relecture humaine annoncée avant diffusion. La seule lecture qui ne
demande aucun modèle — s'enregistrer soi-même — pourrait sortir la première.

## Chantiers transverses

- **Hors ligne** — **tranché** (D41) : *on continue sans réseau, on n'ouvre
  pas*. Les mots ne se perdent plus, le dernier tour se relit, décider, écarter
  et parler attendent le réseau. Ouvrir refuse, en disant pourquoi.
- **Livrable** — le serveur sait déjà écrire les deux documents : le `.pptx`
  que l'assemblée voit, le `.docx` qui porte ce qui ne monte pas à l'écran.
  C'est la **dernière case vide** de la ligne d'arrivée v1 côté serveur, et
  aucun écran mobile ne la sert. Voir **D24** : ce n'est pas un export, c'est
  une soumission au contrôle.
- **Recherche** — sur les titres, les résumés et le contenu des blocs.
- **Intégration continue** — analyse et tests à chaque poussée.
