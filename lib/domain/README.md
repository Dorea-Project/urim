# Couche domaine

Le cœur métier d'Urim. **Ne dépend de rien** : ni Flutter, ni Riverpod, ni
Dio, ni base de données. Un fichier de cette couche n'importe que `dart:*`,
`package:equatable` et d'autres fichiers de `domain/` ou de `core/` eux-mêmes
dépourvus de framework.

C'est la règle qui rend le métier testable sans émulateur et remplaçable sans
réécriture. Elle se vérifie :

```bash
grep -rE "package:(dio|flutter/|go_router|flutter_riverpod)" lib/domain/
```

## Les deux domaines

Urim tient sur deux modèles distincts, reliés par la référence biblique.

### Bible — `entities/bible/`

Le texte, en lecture seule.

| Entité | Rôle |
|---|---|
| `VerseRef` | Référence à un verset : `bookId` + chapitre + verset. Forme canonique `gen.1.1`. |
| `PassageRef` | Étendue continue de versets, bornes incluses. Ne peut pas enjamber deux livres. |
| `BibleTranslation` | Une traduction. Porte le copyright : le texte biblique est rarement libre de droits. |
| `BibleBook` | Un livre du canon. `order` est la seule source d'ordre fiable — les identifiants ne se trient pas alphabétiquement. |
| `Verse`, `Passage` | Le texte, toujours rapporté à sa traduction. |

`bookId` est stable et indépendant de la langue (`gen`, `psa`, `rom`) ; les
noms affichés dépendent de la traduction.

### Discernement pastoral — `entities/pastoral/`

Le cœur du produit : consigner une question, les passages qui l'éclairent, et
la décision qui en découle.

| Entité | Rôle |
|---|---|
| `PastoralQuestion` | Racine de l'agrégat. Porte l'étape de discernement et les transitions permises. |
| `ScriptureAnchor` | Rattachement d'un passage à une question. `note` porte le travail réel : ce que ce passage éclaire ici. |
| `Decision` | Décision consignée. Immuable : revenir dessus rouvre la question et en consigne une nouvelle. |

Deux partis pris à connaître avant de modifier ces entités :

- **`AnchorWeight` distingue `supports`, `challenges` et `informs`.** Un
  discernement qui n'enregistre que ce qui conforte la piste envisagée n'est
  pas un discernement.
- **Les décisions s'empilent, elles ne s'écrasent pas.** `listDecisions`
  renvoie l'historique complet ; c'est lui qui rend le cheminement relisible.

## Étapes du discernement

```
open ──► discerning ──► decided
 │            │  ▲          │
 │            ▼  │          │
 │        suspended         │
 │            │             │
 └──────────► abandoned ◄───┘
                 │
                 └──► (retour en discerning uniquement)
```

Les transitions permises sont portées par `PastoralQuestion.canTransitionTo`,
pas par les cas d'usage : la règle appartient à l'entité et vaut partout où
elle est manipulée. Une question `decided` ou `abandoned` ne se redécide pas
sans repasser explicitement par `discerning`.

## Cas d'usage

| Cas d'usage | Règle qu'il porte |
|---|---|
| `GetPassage` | Aucune : relais vers le dépôt. |
| `SearchScripture` | Refuse les requêtes de moins de 3 caractères avant d'atteindre le dépôt. |
| `OpenPastoralQuestion` | Refuse une question sans énoncé. |
| `AnchorScripture` | Rattacher un passage engage le discernement : une question `open` bascule en `discerning`. |
| `RecordDecision` | Vérifie la transition, écrit la décision, puis seulement ensuite clôt la question. |
| `WatchPastoralQuestions` | Flux, pour que la liste reflète les modifications faites ailleurs. |

Les cas d'usage qui horodatent ou créent un identifiant reçoivent `Clock` et
`IdGenerator` (`core/time/`, `core/id/`) plutôt que d'appeler `DateTime.now()`
directement — sans quoi leurs tests ne seraient pas déterministes.

## Ce qui n'est pas modélisé

- **La provenance du texte biblique n'est pas tranchée.** `BibleRepository`
  est muet là-dessus : embarqué dans les assets, API distante ou cache
  alimenté par téléchargement, le choix appartient à la couche data et
  n'obligera à rien réécrire ici.
- **Aucun suivi de personnes.** Un module de suivi de communauté impliquerait
  des données personnelles sensibles — chiffrement, consentement, durée de
  conservation — à cadrer explicitement avant d'écrire la première ligne.

## Sens de la dépendance

`data` → `domain` ← `presentation`

Les deux couches externes dépendent du domaine ; le domaine n'en connaît
aucune. L'inversion se fait par les interfaces de `repositories/`, que `data`
implémente.
