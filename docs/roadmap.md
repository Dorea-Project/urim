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
| Persistance des préparations | **Bloqué par Q4** |
| Profil et réglages | Fait — églises et appareils **simulés** |
| Accueil, création, fil guidé | Écrans faits — les réponses d'Urim sont **scriptées** |
| Relecture d'une prédication, synthèse à valider | Écrans faits — transcription et capsules **scriptées** |

Le domaine du discernement pastoral (`PastoralQuestion`, `ScriptureAnchor`,
`Decision`) reste sur `feat/core-architecture`, non fusionné. Il ne correspond
pas à ce que fait Urim ; il attend une réponse à Q7.

## Modules à venir

### M1 — Accueil et création

**Écrans faits.** Les travaux sont groupés par récence, chaque carte dit à qui
est la main — « Rend la main », « Matière servie », « Retour disponible »,
« Refus motivé » — et la feuille « Quelle tâche ? » ouvre les deux voies. Le
formulaire d'ouverture crée une vraie préparation, avec sa date de culte.

Restent dus : la recherche, et la persistance — **Q4**. Aujourd'hui, fermer
l'application perd tout.

### M2 — Préparation écrite

**Écrans faits, moteur absent.** Le fil est un dialogue : Urim expose son
raisonnement, pèse des textes, pose une question, et attend (D14). Répondre
par un choix ou par la barre de saisie revient au même.

Ce qui manque est le moteur lui-même : les axes (**Q14**), les textes pesés
(**Q1**), les bornes de péricope (**Q15**). Les réponses affichées sont
scriptées.

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
- l'espace utilisé, qui ne se calcule qu'une fois le stockage tranché — **Q4**.

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

- **Hors ligne** — la capture et l'écriture doivent fonctionner sans réseau.
- **Export** — « Exporter en texte » sous une synthèse, « Texte ou PDF » pour
  l'ensemble des préparations depuis les réglages. Le PDF est une brique de
  plus : mise en page, polices embarquées, partage système.
- **Recherche** — sur les titres, les résumés et le contenu des blocs.
- **Intégration continue** — analyse et tests à chaque poussée.
