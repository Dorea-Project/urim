# Décisions et questions ouvertes

Les décisions déjà prises, et ce qui attend un arbitrage. Répondre à une
question consiste à l'écrire ici — pas besoin d'attendre une session.

## Questions ouvertes

### Q1 — D'où vient le texte biblique ?

**Bloque** M5, et la reconnaissance des citations.

| Option | Ce que ça implique |
|---|---|
| Embarqué | Fonctionne sans réseau. Impose de vérifier les droits de diffusion de chaque traduction. |
| API distante | Rien à embarquer, mais l'application ne lit plus rien hors connexion. |
| Hybride | Le plus confortable, le plus coûteux — synchronisation et invalidation. |

Louis Segond 1910 apparaît sur les maquettes : elle est dans le domaine public,
donc embarquable sans négociation. Toute traduction plus récente demandera une
licence.

### Q2 — Quel moteur de transcription ?

**Bloque** M3.

Sur l'appareil, conformément à la maquette et à la politique. Reste à choisir
le moteur, à mesurer ce qu'il coûte en taille d'application et en temps sur un
message long, et à décider du repli quand il échoue.

### Q3 — Où tourne le modèle de synthèse ?

**Bloque** M4.

« Aucun entraînement de modèle sur ton contenu » est une promesse écrite. Un
modèle distant reste possible si le fournisseur s'y engage contractuellement,
mais cela doit être dit à l'utilisateur — la politique actuelle laisse
entendre que rien ne sort de l'appareil.

### Q4 — Comment stocker les préparations ?

**Bloque** M1.

Les préférences système ne conviennent pas ici : une préparation contient un
fil de blocs qui grandit, et une transcription s'adosse à un fichier audio de
plusieurs dizaines de mégaoctets.

Recommandation : **Drift** (SQLite) pour les préparations et les blocs,
`path_provider` pour les fichiers audio. La recherche plein texte devient
possible, et la mémoire ne porte plus tout le corpus.

### Q5 — « tu » ou « vous » ?

Les maquettes mélangent les deux : « **Votre** numéro valide » à la connexion,
« **Tes** données » ensuite. À trancher avant que les écrans ne se multiplient.

### Q6 — D'où vient le nom de l'utilisateur ?

L'accueil affiche un avatar « KA ». L'inscription ne collecte qu'un numéro de
téléphone. Il manque une étape, ou une saisie différée au premier usage.

### Q7 — Le discernement pastoral a-t-il sa place ?

Un domaine complet a été écrit sur une lecture erronée du produit : consigner
une question, les passages qui l'éclairent, la décision qui en découle. Il
reste sur `feat/core-architecture`, non fusionné.

Soit il devient un module à part entière, soit on le supprime. Le laisser en
suspens indéfiniment est la seule mauvaise réponse.

### Q8 — Une seule langue, ou plusieurs ?

Rétrofiter la localisation sur trente écrans coûte cher. La décision doit
tomber avant M2.

## Décisions prises

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Clean Architecture / MVVM, Riverpod 3, go_router, Dio | Un seul mécanisme pour l'état et l'injection ; routage déclaratif avec garde centralisée. |
| D2 | `Result` explicite, aucune exception au-delà des dépôts | L'échec devient visible dans les signatures et vérifié à la compilation. |
| D3 | Charte bâtie sur `#CC3C1F`, Nova Cut réservée à l'identité | Nova Cut est une police d'affichage : superbe à 110 pt, illisible à 14. |
| D4 | Les maquettes font autorité sur la structure et la copie ; la charte sur les couleurs, la typographie et les espacements | Sinon chaque écran importe la teinte de sa capture. |
| D5 | Une seule redirection décide de l'écran affiché | Les écrans modifient l'état, la redirection en tire les conséquences. |
| D6 | « Passer » vaut « vu » ; le déverrouillage n'est jamais persisté | On ne repropose pas ce qui a été écarté ; fermer l'application la reverrouille. |
| D7 | Code secret à 4 chiffres, PBKDF2 et plafond de 5 essais | Dix mille combinaisons : c'est le plafond qui protège, pas la dérivation. |
| D8 | Une préparation est un fil de blocs scellés | Ce que montrent les maquettes ; le compilateur impose de traiter toute nature nouvelle. |
| D9 | L'avertissement de synthèse est un champ requis | Une réserve optionnelle disparaît au premier écran pressé. |
| D10 | La transcription sur l'appareil est portée par le modèle | Permet d'afficher la promesse honnêtement et de refuser un envoi distant. |

## Dettes assumées

| Dette | Échéance |
|---|---|
| `DevAuthDataSource` accepte un code vérifié localement — ne prouve rien | Avant toute mise en ligne |
| La clé du code secret vit dans les préférences, non dans le trousseau matériel | Avant toute mise en ligne |
| Aucune intégration continue | Dès que possible |
| Le mode développeur Windows n'est pas activé — bloque les compilations Windows | Au besoin |
