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
ambiant. Rien ne déborde — mais un tour fait jusqu'à **onze écrans**. C'est la
prochaine décision d'écran.

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

### M4 — Synthèse d'Urim

**Écran de validation fait.** Capsules horodatées, verset non réécrit, réserve
sur ce qui vient du modèle, et la règle qui tient tout : rien ne sort avant
validation (D17).

Dépend de **Q3** pour les capsules, de **Q17** pour la lecture à voix haute —
voix de synthèse, dioula, baoulé, et la voix de celui qui a prêché.

### M5 — Lecture biblique

Affichage d'un passage, contexte, comparaison de versions, reconnaissance des
citations dans une transcription.

Dépend de **Q1**.

### M6 — Compte

**Fait en partie.** Le profil affiche le nom, le monogramme, le numéro, les
églises rattachées et les appareils ; les réglages tiennent la lecture,
l'Écriture, le hors connexion, les rappels et le contenu.

Ce qui marche vraiment : le nom affiché, la taille du texte de lecture,
l'affichage systématique de la référence. Tout le reste est montré **inactif**
avec ce qu'il attend (D13).

Restent dus :

- la suppression du compte et de son contenu, promise par la politique de
  confidentialité ;
- le changement de numéro et de code secret, aujourd'hui réservés au parcours
  d'entrée ;
- les églises et les appareils réels — **Q9** et **Q11** ;
- les trois réglages hors connexion — **Q1**, **Q2**, **Q10** ;
- le rappel du samedi — **Q12** ;
- l'espace utilisé, qui ne veut plus dire grand-chose depuis que les
  préparations vivent sur le serveur : reste l'audio des transcriptions — **Q2**.

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
