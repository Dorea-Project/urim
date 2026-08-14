# Couche présentation

Frontière partagée entre deux pistes — lire avant de modifier.

| Ce qui vit ici | Propriétaire | Branche |
|---|---|---|
| `*_view_model.dart` — état et logique de présentation | Piste 2 | `feat/core-architecture` |
| Pages, widgets, thème, styles | Piste 1 | `feat/ui-prototype` |

## Contrat entre les deux

Un ViewModel :

- expose un état **immuable** via `AsyncValue<T>` (Riverpod) ;
- expose des **méthodes d'intention** (`refresh()`, `submit(...)`) ;
- n'importe **aucun** widget et ne connaît ni `BuildContext`, ni `Navigator` ;
- appelle des use cases, jamais un repository ni un datasource directement.

Un widget :

- lit l'état avec `ref.watch` et déclenche les intentions avec `ref.read` ;
- ne contient aucune règle métier ni appel réseau ;
- traduit les `Failure` en messages affichables — le ViewModel transmet la
  `Failure` telle quelle, la localisation appartient à l'UI.

Tant que ce contrat tient, les deux pistes avancent en parallèle sans se
marcher dessus : la piste 1 peut remplacer entièrement un écran sans toucher
au ViewModel, et la piste 2 peut réécrire un ViewModel sans casser l'écran.

## Organisation

Un dossier par écran ou par flux :

```
presentation/
  home/
    home_view_model.dart   <- piste 2
    home_page.dart         <- piste 1
    widgets/               <- piste 1
```
