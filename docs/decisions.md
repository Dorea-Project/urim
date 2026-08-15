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

La maquette des réglages en tranche une part : « Texte biblique téléchargé —
42 Mo · disponible sans réseau » est un **interrupteur**. Le texte est donc
acquis après l'installation, et le retirer doit rendre la place. L'API distante
seule est écartée : elle ne permettrait pas cette promesse. Reste à choisir
entre un embarquement complet et un téléchargement à la demande.

### Q2 — Quel moteur de transcription ?

**Bloque** M3.

**Contradiction à lever en premier.** La maquette de relecture affiche
« 55 fragments acquittés » et « Deux fragments attendent le réseau. Ils
partiront seuls, dans l'ordre ». Acquittés par qui ? Si la transcription se
fait sur l'appareil, rien n'a à partir. Soit les fragments montent chez un
tiers — et « l'audio ne quitte jamais le téléphone » tombe — soit
l'acquittement est purement local, et le mot « réseau » est de trop.

Sur l'appareil, conformément à la maquette et à la politique. Reste à choisir
le moteur, à mesurer ce qu'il coûte en taille d'application et en temps sur un
message long, et à décider du repli quand il échoue.

La maquette des réglages en fait un interrupteur : « Transcrire sur l'appareil
— plus lent, mais l'audio ne quitte jamais le téléphone ». Le désactiver
suppose donc un envoi distant. Soit ce repli existe, et la politique doit le
dire, soit il n'y a pas d'interrupteur à proposer.

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

Le profil et les réglages tutoient sans exception — « Ton numéro y est
reconnu », « Économise tes données mobiles », « Urim n'utilise jamais tes
préparations ». Le vouvoiement ne subsiste qu'à la connexion.

Recommandation : **« tu »**, et corriger cet écran-là plutôt que les autres.

### Q6 — D'où vient le nom de l'utilisateur ?

L'accueil affiche un avatar « KA ». L'inscription ne collecte qu'un numéro de
téléphone. Il manque une étape, ou une saisie différée au premier usage.

Le profil répond à la moitié : « Nom affiché » s'y modifie, et le monogramme en
est dérivé. Reste le moment de la première saisie — pendant l'inscription, ou
au premier usage. En attendant, le profil accepte un nom vide et affiche le
numéro à sa place.

### Q7 — Le discernement pastoral a-t-il sa place ?

Un domaine complet a été écrit sur une lecture erronée du produit : consigner
une question, les passages qui l'éclairent, la décision qui en découle. Il
reste sur `feat/core-architecture`, non fusionné.

Soit il devient un module à part entière, soit on le supprime. Le laisser en
suspens indéfiniment est la seule mauvaise réponse.

### Q8 — Une seule langue, ou plusieurs ?

Rétrofiter la localisation sur trente écrans coûte cher. La décision doit
tomber avant M2.

### Q9 — Qu'est-ce qu'une église rattachée ?

**Bloque** la section « Églises » du compte.

La maquette dit : « Église Béthel — Yopougon · Ton numéro y est reconnu. Tes
préparations n'y sont pas visibles », puis « Une seule identité, plusieurs
églises possibles. Ce que tu écris dans Urim ne traverse jamais vers elles ».

C'est une promesse d'étanchéité, pas une préférence d'affichage : elle suppose
un annuaire tenu ailleurs — vraisemblablement le reste de la plateforme Dorea —
qui reconnaît un numéro, et une frontière que le code doit garantir.

Restent ouverts : d'où vient la liste, qui rattache qui, et ce que
l'utilisateur peut en faire (quitter une église ? refuser un rattachement ?).

### Q10 — Que synchronise-t-on, et vers où ?

**Bloque** les trois réglages hors connexion.

« Synchroniser en Wi-Fi seulement » suppose une synchronisation, donc une copie
hors de l'appareil. « Espace utilisé — 318 Mo » et la liste des appareils vont
dans le même sens.

La politique de confidentialité promet que les préparations ne sont **lues** par
personne d'autre ; elle ne dit pas qu'elles ne quittent pas l'appareil. L'écart
est peut-être tenable — un dépôt chiffré côté serveur reste illisible — mais il
doit être tranché et écrit avant que le mot « synchroniser » n'apparaisse en
production.

### Q11 — Que fait « Retirer » sur un appareil ?

Retirer un appareil, c'est révoquer sa session — donc disposer d'un serveur qui
tient la liste et sait la fermer. Le nôtre est simulé (voir les dettes).

Reste à décider si le retrait efface aussi le contenu local de l'appareil
retiré, ou seulement son accès.

### Q12 — Par quel mécanisme rappelle-t-on ?

« Préparation en cours — un rappel le samedi si un message n'est pas terminé. »

Une notification locale planifiée suffit, mais elle demande une permission
système, une heure, et surtout une définition de « pas terminé » que le domaine
ne connaît pas : une préparation n'a aujourd'hui aucun état d'achèvement.

### Q13 — Créer un compte et se connecter, est-ce le même chemin ? — **tranchée**

**Deux portes.** Le backend en expose deux jeux de routes, et refuse de dire si
un numéro est connu : répondre ferait de la route un annuaire des inscrits.
C'est donc l'utilisateur qui choisit, depuis la présentation — les deux boutons
de la maquette étaient déjà la bonne réponse.

- **Inscription** : `POST /auth/register` (numéro) → SMS → `verify-registration`
  (numéro + code + **code secret** + appareil) → jetons.
- **Connexion** : `POST /auth/login` (numéro + code secret + appareil) → jetons,
  ou **202** si l'appareil est inconnu → SMS → `verify-device` → jetons.

Les deux parcours sont écrits. Trois conséquences d'écran :

- le consentement n'est demandé qu'à l'inscription — celui qui revient l'a donné
  le jour où il a créé son compte ;
- se connecter **pose la serrure locale** avec le code qui vient d'être validé,
  plutôt que de le faire saisir deux fois de suite ;
- « Code oublié ? » aboutit toujours, même sur un numéro inconnu, et l'écran ne
  dit jamais le contraire.

### Q14 — D'où viennent les dix loci ?

Le fil guidé propose trois axes — l'Église, l'homme, le péché — extraits d'un
ensemble de dix, annoncé par « Voir les dix loci ». Cette liste n'existe nulle
part : ni sa composition, ni ce qui rattache une phrase à l'un plutôt qu'à un
autre.

C'est la pièce centrale du moteur, pas un détail d'écran.

### Q15 — Qui borne la péricope ?

Urim propose d'étendre « Actes 2:42 » à « 42-47 », et prévient que s'en tenir
au verset seul rend les pesées inapplicables : « Tu forces les bornes ».

Reste à décider ce que cela signifie concrètement — les textes qui résistent
disparaissent-ils, ou sont-ils simplement marqués comme non recalculés ? — et
d'où viennent les bornes littéraires, qui ne sont pas dans le texte biblique
lui-même.

### Q16 — Que promet-on sur l'audio ?

La relecture affiche « audio supprimé le 16 août » : une durée de conservation
est donc annoncée, sans qu'aucune règle ne l'ait fixée. Combien de jours, et
que devient la transcription quand l'audio disparaît ?

À écrire dans la politique de confidentialité avant d'être affiché.

### Q17 — La lecture à voix haute : quelles langues, par quel moyen ?

La synthèse propose quatre lectures : une voix de synthèse française, deux
traductions — dioula, baoulé — « à relire par un locuteur avant diffusion », et
la voix de celui qui a prêché.

Trois briques distinctes, dont deux entièrement nouvelles : la synthèse vocale
et la traduction vers des langues très peu dotées. La quatrième — s'enregistrer
soi-même — ne demande rien d'autre que la capture audio, et pourrait sortir la
première.

### Q18 — Une fois validée, qui voit la synthèse ?

« Aucun membre ne la voit » suppose qu'après validation, des membres la voient.
On sort alors d'Urim vers l'assemblée — donc vers **Q9**, et vers une promesse
inverse de celle du profil : les préparations ne traversent jamais, mais la
synthèse validée, si.

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
| D11 | Les réglages vivent dans les préférences système | Quelques scalaires lus au démarrage, jamais listés ni cherchés. Ce qui disqualifie les préférences pour les préparations (Q4) ne vaut pas pour eux. |
| D12 | La taille du texte porte sur la lecture, pas sur l'interface | La maquette la range sous « Lecture » et l'illustre d'un verset. L'échelle système reste maîtresse du reste de l'écran. |
| D13 | Un réglage dont l'effet n'existe pas est affiché **inactif**, et dit ce qu'il attend | Un interrupteur qui bascule sans rien changer est un mensonge que l'utilisateur découvre au pire moment. Visible plutôt qu'absent : il dit où va le produit. |
| D14 | Le fil est un dialogue : Urim demande, l'utilisateur tranche | Les maquettes ne montrent aucune génération d'un bloc. Chaque étage pose une question et attend — d'où l'état « Rend la main », qui ordonne l'accueil. |
| D15 | Les textes qui résistent sont affichés au même rang que ceux qui soutiennent | Un moteur qui ne servirait que ce qui appuie fabriquerait la preuve de ce qu'on avait déjà décidé de trouver. Le type `TextStance` les met au même niveau, et l'écran aussi. |
| D16 | Toute réponse d'Urim porte sa trace | « Comment j'en suis arrivé là » est ce qui distingue une proposition d'un oracle : sans elle, l'utilisateur ne peut ni vérifier ni contredire. |
| D17 | Rien ne sort avant validation explicite | La synthèse n'existe que pour son auteur tant qu'il ne l'a pas validée. C'est le code qui le tient, pas l'intention : la lecture à voix haute est fermée tant que le drapeau est faux. |
| D18 | Le verset n'est jamais réécrit par le modèle | Les capsules viennent d'un modèle, le texte biblique de la Bible. Les deux sont affichés séparément, et l'écran le dit. |
| D19 | Le contrat vient du backend existant, pas d'une invention côté mobile | `app/contexts/auth` expose déjà le parcours complet. Les noms de champs (`phone_number`, `secret_code`, `device_id`) sont repris tels quels dans la couche data, et traduits une seule fois vers le vocabulaire du domaine. |
| D20 | Le code secret est une donnée **serveur**, posée en même temps que le code SMS | Le serveur n'ouvre pas de compte sans serrure : `verify-registration` prend les deux. Le code reste aussi dérivé localement, pour déverrouiller sans réseau — deux usages, une seule saisie. |
| D21 | Jetons et identifiant d'appareil au coffre matériel ; tout le reste aux préférences | Keystore / Keychain pour ce qui ouvre des portes, préférences pour ce qui n'a pas de valeur volée. La dette « la clé du code secret vit dans les préférences » se referme ici. |
| D22 | L'identifiant d'appareil est tiré au hasard, jamais lu dans le matériel | IMEI et Android ID sont des données personnelles, pistables d'une application à l'autre. Urim n'a besoin que de savoir « c'est le même appareil qu'hier ». |
| D23 | Un seul rafraîchissement à la fois, un seul rejeu par requête | Trois écrans qui échouent ensemble ne doivent pas déclencher trois rotations : la deuxième invaliderait le jeton de la première. Et une requête qui échoue deux fois signe une session morte, pas une boucle à retenter. |

## Dettes assumées

| Dette | Échéance |
|---|---|
| `DevAuthDataSource` accepte un code vérifié localement — ne prouve rien. Coupée par `--dart-define=USE_MOCK_AUTH=false`, interdite en production | À la première campagne contre le serveur |
| Identifiants de démonstration en dur : numéro prérempli, code SMS fixe, code secret suggéré. Affichés seulement quand personne ne répond vraiment | Avec le vrai serveur SMS |
| `applicationId` encore `com.example.urim`, APK signé avec la clé de debug | Avant toute distribution |
| La dérivation locale du code secret vit dans les préférences ; les jetons, eux, sont au coffre matériel | Avant toute mise en ligne |
| Le code secret existe à deux endroits — serveur et dérivation locale. Le changer d'un côté ne met pas l'autre à jour | Avant l'écran de changement de code |
| Le changement de code secret depuis le profil n'existe pas : seul « code oublié » permet d'en changer, et il révoque les autres appareils | Avec l'écran de compte |
| Les églises et les appareils du profil viennent d'un jeu d'exemple en mémoire | Q9 et Q11 |
| Le fil guidé, la relecture et les capsules sont **scriptés** : aucun moteur ne les produit | Q1, Q2, Q3, Q14 |
| Les préparations vivent en mémoire — fermer l'application les perd | Q4 |
| Aucune intégration continue | Dès que possible |
| Le mode développeur Windows n'est pas activé — bloque les compilations Windows | Au besoin |
