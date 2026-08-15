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
| Connexion SMS et code secret | Fait — **serveur simulé** |
| Politique de confidentialité | Fait |
| Domaine des préparations | Fait |
| Persistance des préparations | **Bloqué par Q4** |

Le domaine du discernement pastoral (`PastoralQuestion`, `ScriptureAnchor`,
`Decision`) reste sur `feat/core-architecture`, non fusionné. Il ne correspond
pas à ce que fait Urim ; il attend une réponse à Q7.

## Modules à venir

### M1 — Accueil et création

Liste des préparations groupées par récence, recherche, feuille « Par où tu
commences ? » et création par les deux voies.

Dépend de **Q4** : les préférences système ne conviennent pas à ce produit.

### M2 — Préparation écrite

Le fil de blocs, la barre de saisie, la dictée. Affiche ce que le domaine sait
déjà représenter ; aucune brique lourde requise.

### M3 — Enregistrement et transcription

Capture audio, forme d'onde, reprise, file d'attente hors ligne, transcription.

Dépend de **Q2**. La file d'attente est une mécanique à part entière : un
enregistrement existe localement dès la fin de la capture, la transcription
part quand elle peut.

### M4 — Synthèse d'Urim

Plan proposé, axes horodatés sur l'enregistrement, correction du plan, export
en texte.

Dépend de **Q3**. L'avertissement est déjà obligatoire dans le modèle.

### M5 — Lecture biblique

Affichage d'un passage, contexte, comparaison de versions, reconnaissance des
citations dans une transcription.

Dépend de **Q1**.

### M6 — Compte

Nom et initiales, appareils connectés, suppression du compte et de son
contenu — promise par la politique de confidentialité, donc due.

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

## Chantiers transverses

- **Hors ligne** — la capture et l'écriture doivent fonctionner sans réseau.
- **Export** — « Exporter en texte » apparaît sur les maquettes.
- **Recherche** — sur les titres, les résumés et le contenu des blocs.
- **Intégration continue** — analyse et tests à chaque poussée.
