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

### Q4 — Que garde l'appareil ? — **la question centrale de M1 et M2**

J'ai écrit un jour qu'elle était « sans objet » parce que les préparations
vivent sur le serveur. C'était faux, et de la mauvaise façon : la question n'a
pas disparu, elle a changé de forme et **elle est devenue plus dure**. Ce n'est
plus « où est la vérité » — c'est le serveur, et c'est réglé. C'est **ce que
l'appareil garde pour que l'outil serve quand le réseau ne sert pas.**

Deux mesures posent le problème mieux qu'un argument :

- **huit secondes par tour**, en local, sans réseau du tout — quatre appels en
  32 s au banc `live`. Chaque lecture rejoue les huit étages du pipeline ;
  c'est le prix de D28, et il est payé à chaque ouverture d'écran.
- **Abidjan, samedi soir.** Sans réseau, une application qui ne garde rien
  n'affiche rien : ni le fil, ni le dernier tour, ni les mots que le pasteur
  vient d'écrire. Elle devient une brique le jour où elle sert le plus.

La feuille de route promet déjà le hors connexion, et la politique de
confidentialité promet que le travail reste à son auteur. Ni l'un ni l'autre ne
tient aujourd'hui.

#### Quatre choses à garder, et elles n'ont pas les mêmes règles

| Ce qu'on garde | Pourquoi, et la règle |
|---|---|
| **Les mots du pasteur** — sa saisie en cours, ses points, le thème qu'il a réécrit | Non négociable, et écrit **avant** tout appel réseau. Perdre les phrases d'un homme parce qu'une requête a échoué est la seule faute que cet outil n'a pas le droit de commettre. |
| **Une file de gestes** — décider, écarter, parler faits sans réseau | Rejouée **dans l'ordre** à la reconnexion. C'est la synchronisation, et elle n'a pas besoin d'être inventée : voir plus bas. |
| **Le dernier tour reçu**, par préparation | Pour que l'écran s'ouvre tout de suite et se lise sans réseau. Il porte l'heure où il a été reçu : au rejeu de demain, le moteur peut dire autre chose (D28), et l'écran ne doit pas prétendre le contraire. |
| **L'audio** d'une transcription | Fichier local, plusieurs dizaines de Mo. Dépend de **Q2**, pas d'ici. |

#### Ce qui rend la synchronisation possible, et c'est le serveur qui l'offre

Le modèle de D28 — *aucun historique, seulement des décisions* — n'est pas un
obstacle au hors connexion : c'en est la clé.

Les décisions sont un petit ensemble ordonné, et le serveur les **périme en
cascade** : décider un étage amont invalide mécaniquement l'unité, la
faisabilité et le thème qui en dépendaient. Rejouer une file dans l'ordre
d'émission donne donc le même état que si les gestes avaient été faits en
ligne, sans code de fusion à écrire. Une pile de phrases à réconcilier aurait
demandé l'inverse.

#### Les deux endroits où ça résiste

**`POST /turns` n'est pas une décision.** Une phrase libre rejouée deux fois
peut coûter deux passages du répondeur — et un appel de modèle. Il faut une
clé d'idempotence portée par le client, ou une déduplication à l'envoi.

**Le corpus dérive.** Un geste mis en file mardi, rejoué vendredi, peut
rencontrer un corpus qui a changé — le serveur le signale déjà
(`corpus_drifted`). Ce que l'écran doit dire alors reste à trancher : le tour
n'est pas faux, il est **différent de celui qu'on avait sous les yeux**.

#### Ce qui reste vrai de l'ancienne réponse

Drift (SQLite) pour la file et les tours gardés, `path_provider` pour l'audio.
Les préférences système ne conviennent pas : une file grandit, et un tour réel
pèse jusqu'à 27 ko de JSON.

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

### Q8 — Une seule langue, ou plusieurs ? — **socle posé, langue en attente**

Rétrofiter la localisation coûte cher, et la dette a été prise : au moment de
poser la question, l'application comptait déjà **647 littéraux dans 74
fichiers**. Le chiffre ment un peu — 166 sont du contenu scripté qui mourra avec
le vrai moteur — mais l'interface elle-même pèse environ **300 chaînes**, dont
80 sur les seuls écrans d'entrée.

D'où le choix de séparer le socle de la langue. `flutter_localizations` et
`gen-l10n` sont en place, les textes vivent dans `lib/l10n/app_fr.arb`, la
présentation y est passée entièrement, et un test refuse toute nouvelle chaîne
en dur dans les zones migrées — la liste s'allonge, elle ne recule pas.

**Trois axes que « bilingue » confond**, et qui ne se décident pas ensemble :

| Axe | Nature | État |
|---|---|---|
| Interface — libellés, erreurs | traduction | socle posé, une seule langue dedans |
| Contenu — le texte biblique servi | droits et données | dépend de **Q1** |
| Acheminement — WhatsApp, SMS, push | préférence par personne | le modèle existe déjà en `fr`, `en`, `en_GB`, `ar` |

Une interface anglaise sur une Bible française est cohérente ; une Bible
anglaise rouvre Q1 — la King James, elle, est dans le domaine public.

Reste à trancher **laquelle**. À noter pour éviter un contresens coûteux : le
dioula et le baoulé que promet la maquette de synthèse sont des langues **à voix
haute**, pas des langues d'écran. Comme interface, l'effort est d'un autre
ordre — orthographe non stabilisée, vocabulaire technique à inventer — et la
plupart des locuteurs lisent le français.

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

### Q14 — D'où viennent les dix loci ? — **répondue par le serveur**

Elles existent, et depuis longtemps. Le moteur les sert avec leurs libellés —
théologie propre, christologie, pneumatologie, anthropologie, hamartiologie,
sotériologie, ecclésiologie, angélologie, démonologie, eschatologie — et pour
chaque phrase du pasteur il signale **celles que sa formulation touche**, avec
un motif écrit pour elle : « L'Église sans amour », « Pourquoi l'amour entre
croyants semble aujourd'hui impossible ». Les autres restent ouvertes, avec la
mention « c'est vous qui savez ce que vous prêchez ».

Ce qui rattache une phrase à un locus est le rapprochement doctrinal du corpus
curé, et le tour porte sa signature (`ia-mistral` ou le nom d'un relecteur)
quand le libellé n'a pas été écrit par le corpus.

La question était posée depuis le mobile, avant qu'on ait regardé le moteur.

### Q15 — Qui borne la péricope ? — **répondue par le serveur**

L'étage `bound_pericope` le fait, et il ne propose pas une extension : il
propose les **unités littéraires relues** que la demande recoupe. « 1 Jean
4:7-21 » en couvre trois — l'amour comme preuve de la connaissance de Dieu, la
présence de l'Esprit et la confession, l'amour parfait et la confiance — et le
pasteur choisit.

La conséquence de garder ses bornes est servie avec le choix, pas après : tout
ce qui est curé devient illisible pour les étages avals, `bounds_overridden`
devient vrai, et l'alerte sur le proof-texting se tait. Rien ne « disparaît » :
c'est la relecture qui cesse de s'appliquer.

Les bornes viennent de la curation — 4 561 unités couvrent les 66 livres et
portent toutes leurs pesées.

### Q16 — Que promet-on sur l'audio ?

La relecture affiche « audio supprimé le 16 août » : une durée de conservation
est donc annoncée, sans qu'aucune règle ne l'ait fixée. Combien de jours, et
que devient la transcription quand l'audio disparaît ?

À écrire dans la politique de confidentialité avant d'être affiché.

### Q17 — La lecture à voix haute : quelles langues, par quel moyen ?

**Cadre posé.** Le dioula, le baoulé, le bété et les suivantes ne sont **pas des
langues d'interface**. Aucun écran ne sera traduit dans ces langues : elles ne
concernent que la **voix** — la synthèse validée, lue à ceux de l'assemblée qui
écouteront plutôt que de lire. C'est une modalité de sortie, pas une locale.

La distinction n'est pas théorique : traduire trente écrans en bété n'a aucun
sens — l'orthographe n'est pas stabilisée, le vocabulaire d'interface est à
inventer, et les locuteurs lisent le français. Lire à voix haute dans leur
langue, en revanche, touche exactement ceux que l'écrit laisse dehors.

La liste reste ouverte, et elle appartient à l'assemblée : une église
n'aura pas les mêmes langues qu'une autre.

Trois briques distinctes se cachent derrière :

| Lecture | Ce qu'elle demande |
|---|---|
| Français, voix de synthèse | une synthèse vocale française — la brique la mieux dotée |
| Dioula, baoulé, bété… | une **traduction** puis une **voix**, dans des langues très peu dotées, avec relecture humaine annoncée sur la maquette |
| Sa propre voix | **rien** — ni traduction, ni modèle : seulement la capture audio |

La troisième est la seule qui fonctionne aujourd'hui, et c'est aussi la plus
juste : c'est la voix du pasteur que l'assemblée reconnaît. Elle devrait sortir
la première, et les deux autres attendre d'être bonnes plutôt que d'être
livrées médiocres — une traduction approximative d'un texte biblique n'est pas
un défaut d'ergonomie, c'est une faute.

### Q18 — Une fois validée, qui voit la synthèse ?

« Aucun membre ne la voit » suppose qu'après validation, des membres la voient.
On sort alors d'Urim vers l'assemblée — donc vers **Q9**, et vers une promesse
inverse de celle du profil : les préparations ne traversent jamais, mais la
synthèse validée, si.

### Q19 — Où vivent les documents produits ? — **écartée pour l'instant**

À la fin d'une conversation, le pasteur — ou Urim — propose de générer le moment
en `.docx`, `.pptx`, plus tard un ebook ou de l'audio. La question suit d'elle
même : où tout cela se range-t-il ?

**Ce n'est pas le cœur du produit**, et ça attend. Ce qui est consigné ici l'est
pour ne pas être redécouvert, et pour éviter deux erreurs faciles.

**La bibliothèque est une vue, pas un contexte.** Les fichiers appartiennent
déjà à `deliverable`, les faits de prédication à `archive`. Un troisième magasin
donnerait deux propriétaires au même fichier. Ce qui manque n'est pas un
stockage : c'est **l'endroit où les deux portes se rejoignent** — aujourd'hui la
préparation produit des documents, la transcription produit de l'audio, et rien
ne dit à un pasteur « voici ce que tu as, tout confondu ».

**Deux objets seraient réellement nouveaux :**

- **l'ebook** — une *compilation*, plusieurs préparations réunies. Une opération
  sur un ensemble, pas un format de plus à côté du `.docx` ;
- **l'audio de la synthèse** — aujourd'hui un bouton fermé sur un écran ; en
  faire un artefact lui donnerait une existence, et poserait la question de sa
  durée de conservation, comme pour l'audio du culte (**Q16**).

⚠️ **Une bibliothèque est à un geste de la distribution.** Tant qu'elle est *ce
que j'ai*, elle est simple. Le jour où l'un de ces objets se partage, il sort du
pasteur et entre dans l'assemblée — et rouvre **Q18** : qui voit quoi, par quel
canal, avec quel consentement.

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
| D24 | Générer un document n'est pas un export : c'est une **soumission au contrôle** | Le serveur juge ce qui sortira **avant qu'un fichier existe**, et ne rend les octets que pour ce qui porte « conforme ». L'écran ne montre donc pas « Exporter ▾ » mais ce qui sortira, ce qui a été contrôlé, et ce qui bloque encore. |
| D25 | Le `.pptx` et le `.docx` ne sont pas deux exports du même contenu | Le deck est ce que l'assemblée voit ; la note porte ce qui **ne monte pas** à l'écran — mots d'origine, mises en garde, textes qui résistent. Les fusionner ferait perdre la moitié du travail du moteur, ou la projetterait. |
| D26 | Le fil d'accueil parle le **vocabulaire du moteur**, et ne porte **aucune phrase d'Urim** | Deux règles, une même cause. Les quatre états que l'application avait inventés — « Rend la main », « Matière servie »… — étaient une traduction libre de `await_decision`, `continue`, `refuse`, `degrade` : au premier étage ajouté côté serveur, il aurait fallu tenir deux vocabulaires d'accord. Le serveur sert donc `last_outcome` tel quel, et la traduction en français vit à un seul endroit (`turnOutcomeLabel`). Quant au `say` et au `why` d'un tour, ils naissent du **rejeu** du pipeline : les servir dans une liste ferait vingt rejeux à l'ouverture de l'application. Le fil dit **où l'on en est**, l'écran de la préparation dit **ce qu'Urim a dit**. |
| D27 | La projection du dernier tour est écrite là où le moteur s'arrête, et ne fait autorité sur rien | `last_stage_code`, `last_outcome`, `last_turn_at` sont recopiées à la fin de chaque rejeu. La vérité reste le rejeu — elles existent uniquement pour qu'une liste puisse être triée et étiquetée sans faire tourner le moteur. Une projection qui deviendrait source rendrait possible un fil qui ment sur ce que le moteur dirait vraiment. |
| D28 | **Il n'y a pas d'historique de conversation.** Le fil montre un tour, et le compte rendu de la séance en cours | Le moteur rejoue son pipeline à chaque lecture : ce qu'une préparation garde, ce sont les **décisions** du pasteur, pas les phrases. Un journal côté serveur figerait des phrases qu'un moteur amélioré ne dirait plus, et les deux se contrediraient. Conséquence assumée : rouvrir une préparation demain rend ce que le moteur en dit demain. La seule chose que le pasteur ait dite et qui persiste est sa phrase d'ouverture — c'est elle qui ouvre le fil. |
| D29 | Le client n'écrit **jamais** une phrase de sa propre autorité | `say`, `why`, `ask`, les intitulés de groupe, les motifs de blocage : tout vient du serveur, tel quel. L'application fournit la mise en forme. Une phrase fabriquée côté Flutter échapperait à la relecture, aux tests, et à la règle du filet doré. Le corollaire est que le `why` **n'est pas repliable** : le rendre facultatif à l'affichage reviendrait à le rendre facultatif tout court. |
| D30 | Un `kind` de bloc inconnu est **tu**, pas une erreur | Le moteur gagne des étages ; une application installée ne les gagne pas en même temps. Faire tomber l'écran sur un bloc que cette version ne connaît pas punirait le pasteur d'une amélioration du serveur. Même règle que `last_outcome` sur le fil. |
| D31 | Les tests d'écran sont nourris par des **charges réelles capturées**, pas par des données écrites à la main | Ce que j'invente ressemble à mes maquettes : trois pastilles, un motif de deux lignes. Le corpus sert seize pastilles, un motif de 1 423 caractères, dix pesées et dix-huit couples qui reviennent à chaque tour. Les fixtures de `test/fixtures/urim/` sont les réponses exactes du moteur, capturées contre le corpus réel — elles se régénèrent, elles ne se rédigent pas. Corollaire technique : l'analyse doit être appelable **hors transport** (`studyFromWire`), un test de widget contrôlant le temps ne pouvant pas attendre une requête. |
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
| Le fil guidé parle le contrat du serveur, mais un build de démonstration le fait **jouer par un mannequin** (`DemoUrimEngine`) : quatre étages scriptés, aucune Écriture consultée. Il imite la forme du contrat, pas le raisonnement | Quand l'application vise le serveur par défaut |
| **Un tour réel coûte jusqu'à onze écrans de défilement** sur un téléphone. Rien ne déborde ; c'est la longueur qui casse l'usage — dix pesées et dix-huit couples plan × matière, republiés à chaque tour comme décor ambiant, séparent le pasteur de son geste | La prochaine décision d'écran |
| Le thème servi par le moteur est un gabarit de **codes bruts** — « theologie_propre, en textuel doctrinal ». Affiché tel quel sous « THÈME » | Côté serveur, aller chercher le libellé de l'axe |
| Le compte rendu de séance est perdu en quittant l'écran. C'est cohérent avec D28, mais ce qui a été touché il y a cinq minutes disparaît en revenant de l'accueil | À évaluer à l'usage — un cache de session suffirait |
| Une prédication transcrite n'a **pas d'issue moteur** : sa pastille « Retour disponible » a disparu du fil. Le serveur ne connaît que les préparations écrites — sa capture est verrouillée à l'étape 1 | Q2, avec la capture réelle |
| La base de développement partagée est estampillée par une **branche parallèle** (bilingue) : la migration du fil ne peut pas y être appliquée depuis `main`. Le DDL est éprouvé sur la vraie base dans une transaction annulée, pas encore posé | À la fusion des deux branches — une révision de fusion Alembic sera nécessaire |
| Aucune intégration continue | Dès que possible |
| Le mode développeur Windows n'est pas activé — bloque les compilations Windows | Au besoin |
