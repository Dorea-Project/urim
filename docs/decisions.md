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

**Ce que la lecture du serveur change (19/08).** Le corpus **est déjà côté
serveur**, et il est servi : `GET /urim/passages` rend un passage sans ouvrir
de préparation, `GET /urim/lemmes` rend la concordance. La question n'est donc
plus « d'où vient le texte » — il vient du même endroit que le raisonnement,
avec la versification et les unités relues qui vont avec. Ce qui reste ouvert
est plus étroit, et c'est le seul morceau qui bloquait vraiment : **qu'embarque
l'appareil pour lire hors connexion**, sachant que D41 a déjà tranché qu'on
n'ouvre pas une préparation sans réseau. M5 peut donc commencer sans attendre.

### Q2 — Quel moteur de transcription ?

**La contradiction est dans le code, pas seulement dans la maquette (19/08).**
Le serveur porte une file de travaux `urim_capture_job` dont les natures sont
`transcrire`, `extraire_versets`, `aligner`, `purger_audio` : la transcription y
est prévue **côté serveur**. La maquette, elle, promet « transcrit sur
l'appareil », et la politique de confidentialité promet qu'aucun contenu ne part
chez un tiers. Les deux ne peuvent pas être vrais en même temps ; trancher Q2,
c'est d'abord dire laquelle des deux promesses on garde.

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

**La voix la rend plus libre, pas plus contrainte.** On pouvait défendre « le
modèle doit être embarqué, parce que l'audio ne doit pas sortir ». Après D52 et
D56, l'argument tombe : **l'audio ne sort plus de toute façon**, et ce qui monte
est du texte. Q3 redevient donc ce qu'elle est vraiment — une question
d'engagement contractuel du fournisseur, pas de confidentialité technique. Une
seule contrainte s'y ajoute, et elle ne dépend pas du lieu : la synthèse ne
reçoit que du texte passé à la proforma (I25).

« Aucun entraînement de modèle sur ton contenu » est une promesse écrite. Un
modèle distant reste possible si le fournisseur s'y engage contractuellement,
mais cela doit être dit à l'utilisateur — la politique actuelle laisse
entendre que rien ne sort de l'appareil.

### Q4 — Que garde l'appareil ? — **tranchée, puis rouverte le 27/08 par la voix**

⚠️ **La capture ajoute une ligne d'un autre ordre de grandeur, et le tableau
ci-dessous ne la connaît pas.** Ce qu'on garde aujourd'hui — des mots, une file
de gestes — se compte en kilo-octets. Une prédication captée pèse **77 Mo pour
quarante minutes** (PCM 16 kHz, D53), vit **sept jours**, et se purge selon sa
propre règle. Trois conséquences à traiter avant le premier pilote : ce que
devient un téléphone plein le dimanche matin, ce que la purge fait d'un audio
jamais transporté, et ce qu'on montre au pasteur de la place qu'il occupe.

🔴 **Et la capture est le premier objet d'Urim qui ne se synchronise pas.** Tout
le reste vit sur le serveur : un pasteur qui ouvre Urim sur sa tablette retrouve
son travail. Une capture, non — elle vit sur un téléphone, sept jours, et nulle
part ailleurs. C'est la conséquence directe de *« la capture n'est jamais
refusée »*, qui interdit d'attendre le réseau ; ce n'est donc pas un défaut à
corriger mais **une promesse à formuler**, et D45 la heurte : la règle des deux
appareils laisse croire que les deux voient la même chose.

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
| ~~**Les mots du pasteur**~~ — la barre de saisie et le formulaire d'ouverture | **Fait** (D32, D33). Restent ses points et le thème réécrit, qui n'ont pas encore d'écran. |
| ~~**Une file de gestes**~~ — décider, écarter **et parler** | **Fait** (D36, D37, D38). |
| ~~**Le dernier tour reçu**~~, et la dernière liste du fil | **Fait** (D34). L'écran s'ouvre sur ce qu'il sait, dit d'où ça vient, et se rafraîchit derrière. |
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

#### Les deux endroits où ça résistait — les deux sont traités

**`POST /turns` n'est pas une décision.** Réglé par une clé d'idempotence
portée par le client et reconnue par le serveur (D38).

**Le corpus dérive.** Le serveur le signalait déjà par `corpus_drifted`, et
personne ne l'écoutait. L'écran le dit maintenant une fois, sobrement, et
n'empêche rien : le tour n'est pas faux, il n'est plus **mot pour mot** celui
que le pasteur avait sous les yeux.

#### L'étape 5 — **on n'ouvre pas hors réseau**, et c'est tranché

> *« On ne peut pas soumettre une préparation hors réseau, car l'interaction
> fait appel à des informations externes. »*

C'est la réponse, et elle referme la question au lieu de la reporter. Ouvrir
n'est pas enregistrer une phrase : c'est **la faire lire**. L'étage 0 regarde si
les mots se suivent comme dans l'Écriture, l'étage 1 aligne des versets, la
pesée interroge 4 561 unités relues et 442 889 jetons. Rien de tout cela n'est
sur l'appareil, et l'y mettre serait un autre produit.

La frontière du hors connexion est donc nette, et elle se dit en une phrase :
**on continue sans réseau, on n'ouvre pas.** Continuer est tenu — les mots ne se
perdent plus, le dernier tour se relit, décider, écarter et parler attendent.
Ouvrir refuse, en disant *pourquoi* et en gardant la phrase : sans la raison, le
pasteur croirait avoir perdu ce qu'il vient d'écrire.

#### Ce qui reste vrai de l'ancienne réponse

Drift (SQLite) pour la file et les tours gardés, `path_provider` pour l'audio.
Les préférences système ne conviennent pas : une file grandit, et un tour réel
pèse jusqu'à 27 ko de JSON.

### Q5 — « tu » ou « vous » ? — **tranchée, et autrement que prévu**

Ma recommandation était éditoriale : choisir « tu » et corriger l'écran d'entrée.
La réponse est meilleure, et elle change la nature de la question.

> *« Je m'appelle Urim, votre compagnon, je suis là pour vous assister — si ça
> ne vous gêne pas, on se tutoie ? »*

**Ce n'est pas un choix de rédaction, c'est une permission demandée.** Urim
vouvoie d'abord, parce qu'on ne tutoie pas quelqu'un qu'on rencontre ; il
demande, et il obéit. La forme d'adresse devient donc une **donnée du compte**,
pas une constante de la copie — et le tutoiement est *accordé*, jamais présumé.

C'est aussi ce qui empêche Urim d'être mécanique. Un outil qui tutoie d'office
est familier sans être proche ; celui qui demande d'abord est poli, et la
politesse est ce qui fait entendre quelqu'un plutôt que quelque chose.

#### Ce que ça coûte, mesuré et non estimé

Tout ce qu'Urim dit est écrit en « vous », et **en dur** : 25 occurrences dans
les tables du tour, 18 dans les répondeurs, 32 dans les motifs des étages
(`weigh_conviction` 10, `resolve_passage` 11, `route_entry` 6…). Rien n'est dans
un catalogue, et le français ne se transforme pas mécaniquement — « prêchez-vous »
ne devient pas « prêches-tu » par une règle, et « votre » demande le genre et le
nombre pour devenir « ton », « ta », « tes ».

#### La règle qui interdit le raccourci

**On ne pose pas la question avant de pouvoir honorer la réponse.** C'est D13
appliqué à une phrase au lieu d'un interrupteur : demander « on se tutoie ? »
puis continuer à vouvoyer serait exactement le mensonge que D13 refuse — et
tutoyer l'interface tout en vouvoyant Urim se lirait comme une faute, pas comme
une nuance.

#### Un catalogue n'est pas la réponse — voir Q20

J'avais recommandé de sortir les phrases dans un catalogue à deux formes
d'adresse. C'est écarté : deux variantes de chaque phrase dérivent, et le
tutoiement n'est que le premier axe — la proactivité en demanderait d'autres.
Si la phrase est **rendue** plutôt qu'écrite, la forme d'adresse devient une
consigne et non un second catalogue. C'est l'objet de **Q20**.

Le salut et le nom, eux, peuvent partir avant : ils vivent dans la copie du
produit.

### Q5bis — qui a le droit d'écrire une phrase, et laquelle — **tranchée**

Posée en écrivant le salut, parce que D29 dit que le client n'écrit jamais une
phrase de sa propre autorité, et qu'il fallait savoir si « Je m'appelle Urim »
en est une.

Trois registres, et la frontière est nette :

| Registre | Qui l'écrit | Exemples |
|---|---|---|
| **Ce qu'Urim dit d'une préparation** | le serveur, toujours | `say`, `why`, `ask`, les intitulés de groupe, les motifs de blocage |
| **La voix du produit** — il se présente, il explique ce qu'il est | la copie de l'application | la présentation animée, le salut, « si ça ne vous gêne pas, on se tutoie ? » |
| **L'état de l'application** | l'application, seule à le savoir | « Gardé sur cet appareil », « un geste attend le réseau » (D40) |

Ce qui reste interdit est intact : une phrase sur un texte, un motif, une pesée.

### Q6 — D'où vient le nom de l'utilisateur ? — **tranchée**

**De l'inscription.** Le nom est demandé pendant l'entrée, pas différé au
premier usage — et c'est le même écran que le salut de Q5 : Urim se présente,
demande à qui il parle, puis demande s'il peut tutoyer. Un formulaire aurait posé
trois champs ; une rencontre pose trois phrases.

Ce que ça demande, et qui n'existe pas encore : `POST /auth/verify-registration`
ne prend aujourd'hui que le téléphone, l'OTP, le code secret et l'appareil. Les
colonnes `accounts.first_name` / `last_name`, elles, existent depuis le M0.

Le profil garde son champ « Nom affiché » — on change de nom, on ne se
réinscrit pas.

### Q7 — Le discernement pastoral a-t-il sa place ? — **à supprimer**

Un domaine complet écrit sur une lecture erronée du produit : consigner une
question pastorale, les passages qui l'éclairent, la décision qui en découle.
783 lignes sur six fichiers, dans `feat/core-architecture` — sources de données,
modèles, dépôt, trois modèles de vue.

**Il n'a plus sa place, et on sait maintenant pourquoi.** Urim ne consigne pas
des décisions pastorales : il conduit un tour, et ce qu'une préparation garde,
ce sont les décisions du pasteur sur un texte (D28). La question de départ n'est
pas « quel est mon problème » mais « qu'est-ce que je veux prêcher ». Ce sont
deux produits.

Ce qui le rend nuisible plutôt que neutre : 783 lignes câblables invitent
quelqu'un à les câbler. Une branche qui dort a l'air d'un travail en attente,
pas d'une erreur reconnue.

**Décision : supprimer la branche**, en gardant sa trace ici —
`bc8d8467e525443b32d7abf1caf4d095151895cd`. Le code reste atteignable par ce
SHA tant qu'il n'est pas ramassé ; ce document est ce qui
permettra de le retrouver si le besoin réapparaît — et de se souvenir qu'il
avait été écarté une fois, avec cette raison.

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

### Q10 — Que synchronise-t-on, et vers où ? — **tranchée**

Ce n'est pas une sauvegarde, et le mot « synchroniser » était le problème.

**Ce qui sort de l'appareil est la synthèse validée, et elle sort vers Dorea** —
l'application de l'assemblée — où elle devient un encart : le texte, l'audio, ce
que les fidèles peuvent relire de la prédication. Le geste n'est disponible que
lorsque l'église est sur Dorea, puisqu'il n'y a personne à qui publier autrement.

Trois conséquences, et la première referme une inquiétude :

- **Les préparations ne partent pas.** Ce qui part est ce que le pasteur a
  validé pour son assemblée. L'écart que je craignais entre la politique de
  confidentialité — « personne d'autre ne les lit » — et un dépôt distant
  n'existe pas : il n'y a pas de dépôt distant des préparations.
- **D17 devient concret.** « Rien ne sort avant validation » n'était qu'une
  règle d'écran ; c'est maintenant la porte d'une publication réelle.
- **Le réglage change de nom.** « Synchroniser en Wi-Fi seulement » devient
  « publier sur Dorea » — l'audio d'une prédication pèse des dizaines de Mo, et
  le choix du Wi-Fi garde son sens, mais il porte sur un envoi voulu, pas sur un
  va-et-vient continu.

Ce qui reste de **Q18** — qui voit la synthèse — trouve ici sa moitié :
l'assemblée, sur Dorea, une fois la validation donnée.

### Q11 — Que fait « Retirer » sur un appareil ?

Retirer un appareil, c'est révoquer sa session — donc disposer d'un serveur qui
tient la liste et sait la fermer. Le nôtre est simulé (voir les dettes).

Reste à décider si le retrait efface aussi le contenu local de l'appareil
retiré, ou seulement son accès.

### Q12 — Par quel mécanisme rappelle-t-on ?

**La voix lui donne l'ancre qui lui manquait.** Ce qui bloque cette question
n'est pas la notification, c'est la définition de « pas terminé » : aujourd'hui
« prêché » est un geste manuel, donc une déclaration. Une capture du dimanche
est **un fait** — le système sait qu'un culte a eu lieu sans que personne ne le
lui dise. Ça ne tranche pas Q12, mais ça lui fournit ce qu'aucune colonne ne
portait.

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

### Q16 — Que promet-on sur l'audio ? — **méthode proposée**

La maquette affiche « audio supprimé le 16 août » : une date au **passé**, pour
un effacement que personne n'a décidé. C'est ça qu'il faut corriger d'abord —
pas la durée, le temps du verbe.

L'audio est **local** (Q2) : la question n'est donc pas qui le voit, mais quand
il libère la place. Un message de trente-huit minutes pèse des dizaines de Mo,
et un téléphone se remplit.

#### La méthode

1. **Jamais avant la validation de la synthèse.** L'audio est la seule pièce qui
   permette de vérifier la transcription ; l'effacer avant rendrait invérifiable
   ce que le pasteur s'apprête à approuver.
2. **Annoncé au futur, jamais constaté au passé.** L'écran dit « conservé
   jusqu'au 16 septembre », et non « supprimé le 16 août ». Une suppression qu'on
   apprend après coup est une perte ; annoncée, c'est un ménage.
3. **Trente jours après la validation**, par défaut. Assez pour se réécouter,
   assez court pour ne pas remplir l'appareil.
4. **Deux gestes, toujours offerts** : « Garder » repousse, « Supprimer
   maintenant » libère. La voix d'un homme qui prêche ne s'efface pas sans qu'il
   ait eu la main dessus.

À écrire dans la politique de confidentialité avec ces mots-là — elle promet
aujourd'hui que rien ne part, elle ne dit rien de ce qui reste.

### Q17 — La lecture à voix haute : quelles langues, par quel moyen ?

**Le sprint 7 en livre le tiers sans l'avoir cherché.** Des trois briques
ci-dessous, « sa propre voix » est celle qui ne demande ni traduction ni
modèle — et la capture **est** exactement cela : la voix du pasteur, enregistrée
et gardée. Ce qui reste ouvert pour elle n'est donc plus « comment la
produire », mais **qui l'écoute** — et c'est Q18, pas Q17.

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

### Q20 — Le modèle peut-il porter la voix d'Urim ? — **architecture à valider**

> *« Les conversations ne peuvent pas être en dur, car on a associé Mistral pour
> combler le vide d'interaction, être proactif, jouer plus sur l'intelligence. »*

Le constat est juste, et il rejoint la plainte de Q5 : un compagnon qui dit
« Voici ce que je peux vous proposer ici » à chaque tour est mécanique. Onze
écrans, deux phrases chacun, répétées à l'identique — c'est le vide dont il
s'agit.

Mais le serveur a écrit l'inverse, et il faut le regarder en face :

> *« Les phrases restent déterministes […] le modèle n'a aucun canal de sortie
> en prose, et lui en ouvrir un pour annoncer ce que le moteur vient de faire
> serait payer un appel pour une phrase qu'on écrit une fois. »*

#### Le critère est déjà dans le dépôt, et il tranche

`adapters/mistral.py` dit à quelle condition le modèle a le droit de parler :

> *« Ni l'un ni l'autre ne peut retirer quoi que ce soit […] leur erreur est
> inoffensive, leur absence l'est aussi. C'est la seule raison pour laquelle on
> les autorise à parler. »*

Appliqué phrase par phrase, ce critère donne trois réponses différentes.

| | Le modèle peut-il ? | Pourquoi |
|---|---|---|
| **`why`** — le motif | **Jamais** | C'est le filet doré. Un motif réécrit par un modèle n'est plus la provenance du raisonnement : c'est un oracle qui explique après coup. Toute la différence entre un atelier et un oracle tient là. |
| **`say`** / **`ask`** | Oui, **à partir de la phrase déterministe** | Le modèle reformule, il ne décide pas de quoi parler. Son erreur redevient inoffensive : la table reste la référence, et une sortie qui promet ce que les blocs n'ont pas est jetée. Le serveur a trouvé ce défaut **trois fois** en marchant son propre arbre — un `say` qui annonçait un contenu absent. Un modèle le refabriquerait à volonté. |
| **Les faits nouveaux** | Il ne les invente pas, il les **dit** | Voir plus bas : c'est là qu'est la vraie proactivité. |

#### Ce qui doit être résolu, sinon l'idée est malhonnête

**La non-reproductibilité sous rejeu.** `GET /studies/{id}` rejoue le pipeline :
une phrase rendue à chaque lecture serait **différente à chaque ouverture**. La
même préparation accueillerait le pasteur autrement chaque matin, sans que rien
n'ait changé. Ce n'est pas un désagrément, c'est le contraire de D28 — le rejeu
est censé garantir que ce qui est dit découle de l'état, pas du hasard.

La sortie : rendre la voix **sur le chemin d'écriture seulement** — ouvrir,
décider, écarter, parler — et la garder contre l'empreinte de l'état. Une
lecture sert la voix gardée, ou la phrase déterministe s'il n'y en a pas. Ce
n'est pas un historique de conversation (D28 tient) : c'est le rendu de l'état
courant, mis en cache comme tel.

**Le temps.** Un tour coûte déjà huit secondes mesurées. Les appels au modèle
tiennent en 2 à 8 secondes — et l'un d'eux, sans délai maximum, a figé une
préparation **35 minutes** le 14 août. La voix rendue doit donc être *en plus*,
jamais *avant* : le tour part avec sa phrase déterministe, et la voix la remplace
si elle arrive. Un compagnon lent est pire qu'un compagnon sobre.

#### La vraie proactivité n'est pas de l'éloquence

C'est le point le plus important, et il ne demande presque pas de modèle.

`propose_theme` sait déjà qu'un axe est une **redite** — il appelle
`recently_preached_axes` et calcule `redite`. L'information est là, calculée, et
elle ne sort qu'enfouie dans un motif. Un compagnon proactif dirait : *« vous
avez déjà prêché cet axe le mois dernier — vous y revenez exprès ? »*

Le vide d'interaction se comble donc d'abord avec **des faits que le moteur a
déjà et ne dit pas**, ensuite avec une voix qui les dit bien. L'inverse — une
belle phrase sur rien — est précisément ce qu'un oracle fait.

#### Ce qui reste à trancher

- Où le modèle tourne, et ce que la promesse « aucun entraînement sur ton
  contenu » lui impose — c'est **Q3**, encore ouverte.
- Le coût par tour, une fois la voix mise en cache : combien d'appels pour une
  préparation menée au bout.

### Q21 — Le pasteur est imprévisible : que fait Urim ? — **recommandation**

**Preuve de terrain, 19/08.** Séance jouée avec un pasteur, sur « Jésus notre vrai idole », unité Colossiens 1:1-14. Au moment de choisir un plan, il demande : *« je peux avoir le sens original de idole ? »* — la question la plus normale du monde à cet endroit. Le produit n'a **ni l'écran** (la concordance est servie par `GET /urim/lemmes`, aucun écran ne l'appelle), **ni le geste** (la parole part vers l'aiguilleur, qui n'a pas d'issue « questionner »), **ni la donnée** (voir la dette sur les gloses). Trois manques pour une seule question, et c'est celle-là qu'il faut garder en tête pour trancher Q21 : le quatrième geste n'est pas un confort, c'est le moment où le pasteur travaille.

Née d'une préparation menée **en vrai** contre le moteur, sur Marc 10:46-52. En
dix minutes, trois défauts, et ils n'en font qu'un.

#### Ce que la séance a trouvé

| Ce que le pasteur écrit | Ce qui arrive |
|---|---|
| `Marc 10:23, Bartimée` | Lu comme une intention sur la richesse. Le nom est ignoré — deux textes du même chapitre, rien à voir, et **aucune question posée**. |
| `Marc 10:46-52` | Lu comme une référence. Résolu, unité bornée : « La guérison de Bartimée ». |
| `Je veux prêcher sur Marc 10:46-52` | Lu comme une intention. **La référence est perdue.** |
| « je veux faire ressortir que Jésus peut tout guérir » | Le répondeur explique ce qu'est un thème, et reserre les douze mêmes plans. |

**1. Une référence n'est vue que si elle est seule.** Cinq mots de politesse
autour et `route_entry` la classe en intention. C'est la façon dont tout le monde
parle.

**2. Les drapeaux de risque ne se lèvent que sur le chemin conviction.**
`study_service` : `if chemin == "conviction": … assiste.lever(lisible)` — sinon
`drapeaux = ()`. Un pasteur entré par une référence n'aura **jamais** de
garde-fou sur son intention, quoi qu'il dise ensuite. Combiné au défaut 1 :

> **On peut avoir son texte, ou son garde-fou. Pas les deux.**

**3. La parole la plus substantielle produit la réponse la plus creuse.**
« Jésus peut tout guérir » est une généralisation depuis une guérison, et
« aveugles physiques et spirituels » une lecture typologique — que le tableau
d'à côté chiffre à *risque moyen*. Urim avait le chiffre et ne l'a pas relié.

#### Le vrai défaut est en dessous des trois

`Tour` rend `decision`, `refus`, `reponse`. La phrase fondatrice du parcours en
promet quatre : *« désigner, écarter, **questionner**, changer d'avis »*.
**`questionner` est le seul verbe sans issue.**

Et la question suivante du pasteur allait être : *« est-ce que je peux avoir le
contexte historique du livre de Marc, la signification de Bartimée ? »*

Urim **avait** les deux réponses. `ContextView` — littéraire et historique — est
déjà dans chaque `StudyView`. `OriginalWordView` sert « ce que sa forme fait ».
La concordance dit où un mot paraît ailleurs. Il n'avait pas le **chemin**.

#### La recommandation

**1. Nommer le quatrième geste : demander.** Une quatrième issue au `Tour`, pas
une branche par sujet. Le canal de parole est le seul par lequel l'imprévisible
arrive, et c'est aujourd'hui le plus pauvre des trois.

**2. Ce qui répond est le corpus, jamais le modèle.** Même règle que
`adapters/mistral.py`, qui rend `{found, book, chapter, verse}` et jamais le
verset : ici le modèle rend *« demande de contexte sur l'unité courante »*, et
jamais le contexte. Son erreur redevient inoffensive — un mauvais encart, pas
une doctrine inventée.

**3. L'imprévisibilité se borne par un inventaire, pas par des branches.** On ne
devine pas ce qu'un pasteur demandera ; on liste ce qu'Urim **peut** servir sur
l'état courant, et le classement devient une question fermée sur cette liste.
Elle est déjà écrite, et elle tient en sept :

| Ce qu'il sait servir | Ce qui le sert |
|---|---|
| le contexte, littéraire et historique | `ContextView`, déjà dans la vue |
| ce que fait la forme d'un mot de l'original | `OriginalWordView` |
| où ce mot paraît ailleurs | la concordance |
| ce que les versions font de ce verset | `VariantView` |
| les textes qui résistent, venus d'ailleurs | `ResistingElsewhereView` |
| un passage entier, hors préparation | `PassageDetailView` |
| ce que j'ai déjà prêché, et sous quels loci | l'archive, la couverture |

« Signification de Bartimée » → un mot de l'original. « Contexte historique de
Marc » → le contexte. Ce qui tombe hors liste va au répondeur, qui existe déjà —
mais en **disant ce qu'il sait faire**. Face à l'imprévisible, la bonne réponse
n'est pas de tout prévoir : c'est de savoir nommer ce dont on est capable.

**4. Demander ne fait pas avancer le pipeline.** Geste latéral, comme écarter.
Le pasteur pose sa question, reçoit sa réponse, et **le tour reste le même** — il
n'a pas perdu sa place. Sans cette règle, chaque question déplacerait sa
préparation, et l'imprévisibilité deviendrait destructrice au lieu d'être
servie.

**5. Et ça déplace Q20.** La proactivité du modèle n'est pas de mieux *parler*,
c'est de mieux **router**. Une reformulation élégante de « Voici ce que je peux
vous proposer ici » n'aurait rien changé à cette séance ; un aiguillage vers le
contexte, si.

#### Ce qui reste à mesurer

La correspondance n'est pas garantie pour toute question — « signification de
Bartimée » est un nom propre, et le gloss est dans le verset lui-même (Marc le
traduit : *« fils de Timée »*). L'inventaire dit ce qu'on sait servir ; il ne
promet pas que chaque demande y trouve sa case. C'est précisément pourquoi le
répondeur doit rester le fond du canal.

### Q22 — Le mur est mesuré, le vide ne l'est pas — **recommandation**

> *« Il doit accélérer son travail. Il n'a pas le temps — c'est pour ça qu'il a
> besoin d'un compagnon. »*

C'est la phrase qui remet tout le reste dans l'ordre, et elle transforme une
liste de défauts en un seul.

#### Une propriété mesurée, une autre qui manque

`scripts/urim_banc_arbre.py` marche l'arbre conversationnel et pose une seule
question à chaque tour :

> **Après ce tour, le pasteur a-t-il quelque chose à faire ?**

Il est à **zéro mur** sur les chemins réels, confessionnels et absurdes. C'est
une vraie garantie, et elle tient.

Mais elle garantit qu'il n'est pas **coincé**. Elle ne dit rien de ce qu'il a
**gagné**. Ce sont deux échecs différents, et le second est celui qui coûte du
temps :

| | La question | Mesuré ? |
|---|---|---|
| **Le mur** | après ce tour, rien à faire | oui, à 0 |
| **Le vide** | après ce tour, rien de plus qu'avant | **non** |

Un mur se voit et se contourne. Un vide ne se voit pas : le pasteur a lu onze
écrans, il a répondu, et il a reçu les onze mêmes écrans.

#### La séance a produit un tour vide qui passe le banc

Sur Marc 10:46-52, à la phrase *« je veux faire ressortir que Jésus peut tout
guérir »* : douze plans à toucher — donc **pas un mur** —, les mêmes dix pesées,
les mêmes dix-huit couples, et un `say` qui explique ce qu'est un thème. Zéro
matière nouvelle. Le banc l'aurait laissé passer.

#### Tout ce que la séance a trouvé est le même défaut

Chacun de ces points est une facture en temps, payée par quelqu'un qui n'en a
pas :

| Ce qui s'est passé | Ce que ça coûte |
|---|---|
| huit secondes par tour, à chaque ouverture d'écran | l'attente |
| onze écrans de défilement, dont neuf de décor déjà lu | la traversée |
| « je veux prêcher sur Marc 10:46-52 » → référence perdue | tout retaper |
| sa correction explicite ignorée | rouvrir une préparation |
| sa phrase la plus substantielle → un répondeur | rien |
| sa question sur le contexte → aucun chemin | alors que la réponse était **déjà dans sa préparation** |
| son document refusé | alors que quatorze sections sur quinze étaient prêtes |

Le plus dur à admettre est l'avant-dernier : le contexte littéraire de Marc 10
avait été calculé **à l'ouverture**, écrit dans la trace à l'étage
`load_context`, et stocké. Il a attendu, il a demandé, on ne lui a rien dit.

#### La recommandation

**1. Le décor ambiant se sert une fois, pas à chaque tour.** Neuf des onze
écrans sont des pesées et des couples déjà lus. Un tour ne devrait porter que ce
qui a **changé** ; le reste se renvoie, replié. C'est de la mise en page, aucun
étage à toucher — et c'est le plus gros gain de la liste.

**2. Ce qui est déjà calculé s'offre, au lieu d'attendre la question.**
✅ **Fait** pour le texte et le contexte (**D44**). Le tour les **nomme** sous
lui — pas dépliés, juste dits — et une touche les ouvre. Restent les variantes
de version et les mots de l'original, servis dans la même charge et toujours
sans écran. Q21 route la question du pasteur ; celle-ci lui épargne de la
poser.

**3. Le banc gagne un second chiffre.** ✅ **Fait** — et il a rendu son verdict.

    murs sur les chemins reelle       0/44
    tours vides sur les chemins reelle       1/44
    tours vides sur les chemins absurde      1/43

Un tour est **vide** quand ce qu'il sert est inclus dans ce que le tour
précédent servait. Une phrase seule ne compte pas comme un gain : c'est tout
l'objet de la mesure.

**Deux corrections que la mesure a imposées d'elle-même**, et qui valent d'être
notées parce qu'elles disent comment lire un instrument :

- **Une relecture n'est pas un vide.** La première version comptait 22 vides sur
  127, *tous* à la relecture finale. Or une relecture rejoue le même état par
  définition — c'est `GET /studies/{id}`, pas une réponse à un geste. Un tour est
  vide quand il **répond à un geste** sans rien apporter.
- **Le banc ne savait pas parler.** Sa boucle s'arrête dès que le pipeline
  continue : elle n'allait donc jamais au-delà du thème, et **le canal par lequel
  arrive tout l'imprévisible n'était pas marché du tout**. D'où un geste
  nouveau — `PARLER` : suivre jusqu'au bout, puis poser sa vraie question.

#### Les deux vides, nommés

**`Marc 10:46-52` · après une parole · `load_context`** — 32 éléments servis,
tous déjà lus. C'est le tour exact rencontré en séance réelle : *« Ce que je peux
dire de votre travail est déjà sous vos yeux… »* au-dessus de blocs inchangés.
Sa réparation est **Q21** : la parole n'a pas d'issue « demander », donc elle
retombe sur un répondeur.

**Micro resté ouvert · tour 1 · `route_entry`** — découvert par la mesure, pas
soupçonné. Le pasteur agit sur l'écran de confirmation d'une dictée et reçoit
**les deux mêmes options**. Deux éléments, déjà servis au tour 0.

#### Ce que ça dit du reste

Q20 s'en trouve encore déplacée. Un modèle qui reformule mieux « Voici ce que je
peux vous proposer ici » ne fait rien gagner à un homme pressé. Un moteur qui
sert son contexte sans qu'il ait à le demander, si.

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

### Q23 — Que répond le serveur au troisième appareil ? — **répondue : rien**

**Bloque** le message affiché au bon moment.

La règle est posée : deux appareils au maximum (D45). Le profil la rend
visible — « 2 sur 2 », et ce qu'il faut libérer. Mais c'est le serveur qui la
tient, et **on ne sait pas ce qu'il renvoie** quand un troisième téléphone
tente de se lier : `api_error.dart` ne connaît aucun code d'appareil.

Sans ce code, l'écran de connexion affichera un refus générique là où il
devrait dire « tu as déjà deux appareils, retire-en un depuis ton profil ».

Deux choses à obtenir : le code d'erreur, et **qui décide** — le serveur
refuse-t-il, ou propose-t-il de remplacer le plus ancien ? Refuser est plus
honnête : remplacer d'office déconnecterait un appareil sans que personne
l'ait demandé.

**Réponse, obtenue en lisant le serveur (19/08) : il ne répond rien de
particulier, parce qu'il accepte.** `app/contexts/auth` ne compte aucun
appareil — `verify-device` fait confiance sans regarder combien il y en a déjà,
et **aucune route ne sait les lister**. La limite de deux (D45) n'existe donc
aujourd'hui que dans l'écran du profil, qui affiche « 2 sur 2 » devant un
serveur qui en accepterait dix. Ce n'est plus une question ouverte mais un
chantier : compter à la liaison, refuser le troisième avec un code nommé,
exposer la liste et le retrait ciblé. Q11 s'ouvre avec — « Retirer » ne peut
rien retirer tant que rien ne liste.
### Q24 — Élargir le périmètre, et étayer ce qu'Urim raconte — **recommandation**

**Demandé le 19/08**, après une préparation jouée de bout en bout : *« il faut élargir
son périmètre, mettre en évidence son discernement et son argumentation, il doit
soutenir ce qu'il raconte. »*

#### Ce qui a déclenché la demande

Trois questions spontanées d'un pasteur en séance. Deux tombent dans le vide, et
dans **le même** vide :

| Sa question | Ce que le produit a |
|---|---|
| « le sens original de *idole* » | la concordance (11 occurrences d'εἴδωλον) — mais **80 gloses pour 14 101 lemmes** |
| « le contexte historique » | **5 notes historiques** pour tout le corpus, toutes marquées `semis-demo` — contre 4 820 notes littéraires |
| « en savoir plus sur Colossiens » | 17 unités relues, 19 notes — mais aucun écran ne sert `GET /urim/passages` |

Urim est **fort sur le texte et ses échos internes, vide sur le monde autour du
texte**. Ce n'est pas un défaut d'exécution : c'est le périmètre réel, et il ne
correspond pas à ce qu'un pasteur attend d'un outil d'étude.

#### Ce que « soutenir ce qu'il raconte » veut dire, chiffres en main

La machinerie de la preuve **existe déjà** : chaque énoncé du corpus porte
`source_ref`, `reviewed_by`, `reviewed_at` ; chaque glose porte en plus l'entrée
d'origine mot pour mot, sa licence et le modèle qui l'a traduite. D16 est tenue.

Ce que cette machinerie déclare aujourd'hui :

| Table | `ia-mistral` | un humain | démo |
|---|---|---|---|
| Pesées doctrinales | 45 520 | **10** | 27 |
| Faisabilité homilétique | 81 918 | 0 | 25 |
| Unités relues | 4 552 | **1** | 8 |
| Réserves | 2 392 | 0 | 11 |
| Notes de contexte | 4 816 | 0 | 9 |

**139 198 énoncés, 11 portent un nom humain.** Et le `source_ref` des notes le dit
lui-même : « renvois resolus, **non relu** ». La trace est honnête ; ce qu'elle
avoue, c'est qu'un modèle a écrit et que personne n'a relu.

C'est le cœur de la demande : la trace prouve **d'où vient** un énoncé, pas qu'il
soit **soutenu**. Un pasteur qui monte en chaire sur « ce texte ne développe aucune
conduite éthique concrète » s'appuie aujourd'hui sur une phrase que personne n'a
signée.

#### Trois chantiers, et ils ne coûtent pas la même chose

**1. Rendre la provenance visible — l'écran, pas le corpus.** Le pasteur ne peut pas
distinguer aujourd'hui un énoncé relu d'un énoncé produit et jamais lu : l'écran ne
montre ni `reviewed_by`, ni `source_ref`, et il n'affiche même pas la **référence**
des unités proposées (`turn.py:448` met l'identifiant dans ce champ, et le client ne
le rend pas). Rien à curer, tout à afficher. C'est le moins cher, et c'est ce qui
rend les deux autres honnêtes.

**2. Étendre les catégories — le corpus, pas le moteur.** Les deux trous ont déjà
leur emplacement dans le schéma : `context_kind = 'historique'` est prévu par une
contrainte, et `urim_corpus_lemma` porte `gloss`, `gloss_source`,
`gloss_source_ref`, `gloss_model`. Remplir ne demande aucune architecture nouvelle —
seulement une source citable et un relecteur.

**3. Faire relire ce qui est déjà là.** 4 561 unités × dix pesées est hors de portée
d'un homme. Le tri se fait donc par l'usage : ce qui est **montré** se relit, le
reste attend. Une unité qu'aucun pasteur n'ouvre n'a pas besoin d'être signée.

#### La règle proposée

> **Rien n'entre dans le corpus sans une source citable ; rien ne sort à l'écran
> sans dire qui l'a relu.** Et tant que personne ne l'a relu, l'écran le dit —
> « proposé par le modèle, non relu » — au lieu de le taire.

Elle a un coût que la demande doit assumer : elle **retire de la superbe** à Urim.
Aujourd'hui il parle d'un ton égal de tout ce qu'il sert ; demain, une partie de ce
qu'il dit portera un aveu. C'est le prix de « soutenir ce qu'il raconte », et c'est
la même logique que D15 — les textes qui résistent s'affichent au même rang que ceux
qui soutiennent, parce qu'un moteur qui ne montre que ce qui l'arrange fabrique la
preuve de ce qu'on avait décidé de trouver.

#### Ce que ça déplace

Q20 (« le modèle peut-il porter la voix d'Urim ? ») change de question : le modèle
**porte déjà** l'essentiel de ce qu'Urim raconte — 139 198 énoncés sur 139 209. La
question n'est plus s'il peut parler, mais à quelles conditions ce qu'il a écrit
peut être servi à un pasteur.

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
| D32 | Ce que le pasteur écrit est posé sur l'appareil **avant** de partir au serveur — et le magasin local ne peut jamais bloquer un geste | Étape 1 de Q4. Ce n'est pas un cache : un cache accélère ce qu'on peut refaire, et une phrase perdue ne se refait pas. Deux règles en découlent. **Un champ détruit écrit d'abord** : un minuteur en attente ne survit pas à son écran, et c'est là que les dernières frappes disparaissaient. **Aucune méthode du magasin ne lève, et aucun geste ne l'attend** : perdre un brouillon est grave, empêcher un pasteur d'ouvrir sa préparation parce que le disque est plein serait pire. Ranger un brouillon est du ménage, jamais une condition. |
| D33 | Un fichier par clé, pas encore SQLite | Les décisions recommandaient Drift pour Q4, et ce sera vrai quand quelque chose devra être **interrogé** — une file à ordonner, une recherche. Un brouillon est une clé et une valeur, écrite à la frappe : un moteur SQL et sa génération de code seraient une facture payée d'avance. Un fichier par clé et non un index unique, pour qu'une frappe ne réécrive pas l'ensemble et qu'une écriture interrompue n'abîme que son propre brouillon — écriture par fichier temporaire puis renommage, qui est atomique. L'interface `LocalDocuments` est ce qui changera de dos le jour venu. |
| D34 | Ce qu'on sait d'abord, ce que le serveur dit ensuite — et **on dit d'où ça vient** | Étape 2 de Q4. Le tour gardé s'affiche immédiatement : huit secondes de blanc deviennent zéro, et un écran vide devient un écran quand il n'y a pas de réseau. Trois règles tiennent l'honnêteté. Ce qui vient du magasin **porte l'heure de sa réception** à l'écran — le moteur rejoue à chaque lecture (D28), donc un tour gardé hier soir est ce qu'il *disait* hier soir, et un pasteur qui décide sur un tour périmé ne l'apprendrait qu'au refus du serveur. Un rafraîchissement qui échoue **n'efface rien** : basculer en erreur ferait payer la panne deux fois. Et un rafraîchissement qui revient **ne recule pas** sur une séance déjà avancée. |
| D35 | Le magasin garde le **JSON brut**, pas l'objet analysé | Deux raisons, et la seconde est la plus solide. Aucun second code de sérialisation à tenir d'accord avec le contrat : `studyFromWire` reste le seul chemin d'analyse, celui que les tests éprouvent déjà sur des charges réelles (D31). Et un champ ajouté demain côté serveur est gardé aujourd'hui, sans que rien ne le sache. L'écriture a lieu dans la source distante, seul endroit qui voit le brut, et sur **tous** les gestes — ouvrir, relire, décider, écarter, parler passent par le même point d'analyse. Un tour gardé par un contrat plus ancien qu'on ne sait plus lire vaut un tour absent : on repart du serveur plutôt que de rendre un écran de travers. |
| D36 | Un geste fait sans réseau est **noté**, jamais simulé | Étape 3a de Q4. Décider hors réseau ne peut pas montrer le tour suivant : ce tour est ce que le pipeline aurait répondu, et le fabriquer côté client serait inventer une phrase d'Urim (D29). L'écran dit donc « noté, en attente », garde le tour précédent sous les yeux, et attend. D'où une troisième issue au geste — `Served`, `Queued`, ou un échec — parce qu'il y en a vraiment trois : le serveur a répondu, personne n'a répondu, ou le serveur a **refusé**. |
| D37 | Seul un manque de réseau est mis en file ; un refus du serveur reste un échec | Un étage qui n'attend plus, une option inconnue : c'est un **jugement**, pas un contretemps. Le renvoyer plus tard ne le rendrait pas acceptable, et l'accumuler ferait une file qui ne se videra jamais. La distinction tient à un type — `NetworkFailure` contre le reste — et c'est tout ce qui sépare une file qui se vide d'une file qui pourrit. |
| D38 | Une parole porte une **clé d'idempotence**, tirée à la mise en file et non à l'envoi | Étape 3b de Q4, des deux côtés. Décider et écarter posent un état : les renvoyer donne le même résultat. Une parole, non — le serveur y répond, et la renvoyer coûterait un second passage du répondeur, donc un appel de modèle en plus et peut-être **une autre phrase que celle que le pasteur a déjà lue**. La clé est tirée au moment où le geste entre en file : la tirer à l'envoi la rendrait différente à chaque tentative, c'est-à-dire inutile. Côté serveur, `urim_preparation.last_turn_key` — une colonne et non une table, parce que le client vide sa file **dans l'ordre** et **s'arrête au premier échec** : la seule parole qu'il puisse renvoyer est donc la dernière. Ce que ça ne protège pas : deux appareils agissant en même temps, dont la conséquence est un appel de modèle en trop et non un état faux. |
| D39 | La clé se pose **après** le geste, jamais avant | La réclamer d'abord serait plus simple et perdrait la parole : un geste qui échoue laisserait sa clé brûlée, le renvoi serait ignoré, et la phrase du pasteur disparaîtrait sans que personne ne le sache. Seule une parole réellement traitée ferme la porte derrière elle. |
| D40 | L'application peut décrire **son propre état** ; seul Urim décrit l'Écriture et son raisonnement | Où passe exactement la frontière de D29, posée en écrivant les mentions de provenance. « Gardé sur cet appareil », « le corpus a été relu depuis l'ouverture » : personne d'autre ne peut les dire, puisque le serveur ne sait pas ce que l'appareil détient. Ce qui reste interdit est intact : une phrase sur un texte, un motif, une pesée. |
| D41 | **On continue sans réseau, on n'ouvre pas** | La réponse à l'étape 5 de Q4, et la frontière du hors connexion. Ouvrir n'est pas enregistrer une phrase, c'est la faire **lire** : l'étage 0 regarde si les mots se suivent comme dans l'Écriture, la pesée interroge 4 561 unités relues et 442 889 jetons. Ces informations sont externes par nature ; les embarquer serait un autre produit. Le refus dit donc sa raison et rappelle que la phrase est gardée — un « Pas de connexion » sec ferait croire au pasteur qu'il vient de perdre ce qu'il a écrit. |
| D42 | Le tour dit **de quoi il parle** ; l'écran déplie ce bloc-là et replie le reste | Premier geste de Q22. La valeur existait : `_forme` la calcule pour choisir la phrase, puis la jetait — le client recevait des blocs sans hiérarchie et les dépliait tous. Or les pesées et les couples accompagnent **tous** les tours qui suivent l'étage qui les a produits : c'est du décor ambiant, voulu, et il se réaffichait à l'identique. Mesuré sur un téléphone de 844 px : l'étage des mises en forme passe de **11,1 à 3,4 écrans**, le thème de 9,0 à 1,3. Un pasteur qui prépare le samedi soir n'a pas dix écrans de matière déjà lue à traverser. |
| D43 | Replier n'est pas cacher : l'intitulé porte **le nombre**, et une touche rouvre | Ce qui sépare ranger d'escamoter. Les refusés d'une grille de faisabilité doivent rester atteignables — les cacher laisserait croire qu'on n'y a pas pensé, et c'est la règle que le serveur applique déjà en les servant avec les faisables. Un geste ouvert, lui, ne se replie jamais : un bouton replié est un bouton perdu. |
| D44 | Ce que la préparation **porte déjà** s'offre sous le tour, replié — le texte, puis le contexte | Deuxième geste de Q22. Le contexte littéraire est calculé à l'ouverture par `load_context`, écrit dans la trace, stocké — et n'était montré nulle part : un pasteur l'a demandé en séance alors que la réponse était **déjà dans sa préparation**. Les versets, eux, n'ont jamais eu de bloc — le fil parlait de l'unité, la pesait, proposait des plans, et ne montrait pas le texte que seul le document imprimé portait. Offert, donc, sans qu'il ait à le demander, mais **replié** sous son intitulé et son nombre comme le décor (D43) : nommer coûte **0,1 écran**, déplier en coûterait six. Trois règles tiennent le reste. Rien ne s'affiche de ce que le corpus n'a pas — toutes les unités ne portent pas de note de contexte, et une section vide promettrait ce qu'elle n'a pas. Le bandeau d'attente reste **le dernier** élément : la matière se range au-dessus, c'est le geste en vol que le pasteur regarde après avoir touché. Et le repli est **le même objet** des deux côtés (`FoldedSection`) : deux chromes pour un seul geste apprendraient deux grammaires au pasteur. |
| D45 | Deux appareils au maximum par compte — **règle posée, pas encore tenue par le serveur** (voir Q23) | Un pasteur a son téléphone, parfois une tablette ; au troisième ce n'est plus un compte personnel mais un compte prêté, et les préparations sont ce qu'Urim promet de garder à leur auteur. La limite est tenue par le serveur, qui seul connaît la liste complète ; le profil la rend **lisible avant qu'elle ne se manifeste** — « 2 sur 2 », et ce qu'il faut libérer. Découvrir un refus en pleine connexion sur un téléphone neuf serait le découvrir au pire moment. L'appareil courant reste non retirable : ce serait une déconnexion déguisée, qui a son propre bouton. |
| D46 | Changer son code secret passe par la **route dediee du serveur**, pas par celle de l'oubli | `/account/change-password/{request,confirm}` existe cote backend : authentifiee par le jeton, sans numero a fournir, et **sans revocation d'appareil**. La premiere version faisait passer le changement par `reset-secret-code` — le chemin du code oublie — qui revoque les autres appareils : un pasteur qui change son code au telephone y perdait la session de sa tablette, pour rien. Erreur de lecture, et non d'architecture : le contrat avait ete deduit du client Flutter, ou seules les routes deja branchees apparaissent, au lieu d'etre lu dans `app/contexts/auth`. Une porte distincte (`secretCodeChange`) la separe donc de l'oubli, et la redirection ne laisse repasser les deux ecrans du parcours que tant qu'elle est ouverte — elle se referme au succes comme au refus. Correction conservee du premier jet : la pose du code court-circuitait le serveur des qu'une session existait, ce qui aurait laisse l'ancien code valable partout ailleurs. |
| D47 | Supprimer son compte efface **les deux côtés**, et l'appareil garde sa seule identité | La politique promet « tu peux supprimer ton compte et tout son contenu à tout moment », sous une mention de la loi n° 2013-450 ; rien ne le tenait. Le serveur efface maintenant pour de bon (`/account/delete`, deux temps avec SMS) : préparations, livrables, archives, captures, transcripts, retours, réservations partent ; la ligne du compte survit **vidée de son identité** — numéro remplacé par une pierre tombale, noms, e-mail et empreintes de code effacés, statut `closed` — parce que la vie d'église s'y accroche et que détruire la ligne emporterait les registres d'une communauté avec le compte d'une personne. La loi demande qu'on ne soit plus identifiable, pas qu'on disparaisse des livres d'autrui. **L'ordre est la décision** : serveur d'abord, appareil ensuite — l'inverse laisserait, sur un refus, un téléphone vidé devant un compte vivant que plus rien ne permet d'atteindre. Côté appareil, trois magasins partent — fichiers, préférences, coffre — les fichiers en premier pour la même raison. Seul `device.id.v1` survit : ce n'est pas du contenu mais le nom de ce téléphone auprès du serveur, et l'effacer ferait passer le même appareil pour un neuf, consommant une **seconde place sur deux** (D45) qu'un fantôme garderait. Le SMS n'est pas une formalité : c'est la seule opération du profil qui ne se défait pas, et un téléphone déverrouillé oublié sur une table suffirait sans lui. |
| D48 | Changer de numéro se fait depuis le profil, et le code part sur le **nouveau** numéro | `/account/change-phone/{request,confirm}` existait côté serveur et l'application n'en faisait rien : la ligne du profil affichait un numéro mort sous la phrase « changer de numéro suppose un nouveau code par SMS ». C'est le nouveau numéro qu'il faut prouver — l'ancien l'a été le jour de l'inscription, et le jeton atteste déjà du compte. La boîte refuse le numéro courant : demander un SMS pour ne rien changer serait un code payé pour rien. La trace locale de session est réécrite au passage, sinon le profil montrerait un numéro que le serveur ne connaît plus jusqu'au prochain lancement. Même forme que D46 et D47 : une porte (`phoneChange`), l'écran du code réemprunté tant qu'elle est ouverte, refermée au succès comme au refus. |
| D49 | L'accueil se scinde en **deux pages** — préparer, prêcher — et une icône de la barre du haut passe de l'une à l'autre | La feuille « quelle tâche ? » posait la question par modale, une fois, à celui qui pensait déjà à autre chose ; la bascule la pose en permanence et sans geste supplémentaire. Ce qu'elle règle surtout, c'est le **micro en double** : dicter une phrase et capter une prédication partagent une icône sans partager de problème (voir `Dictation`), et tant que les deux vivaient sur le même écran aucune mise en forme ne levait l'ambiguïté. Séparées, elles ne se rencontrent jamais — la dictée reste dans le champ de la préparation, la capture est le bouton de l'autre page. **L'icône montre la destination, jamais l'état** : un micro sur la préparation, une plume sur les prédications ; l'inverse fait reculer celui qui croyait avancer. Conséquence tenue par le code : une prédication transcrite quitte le fil des préparations (`PreparationOrigin`), sans quoi la bascule montrerait deux fois la même carte. |
| D50 | La page d'ouverture est décidée par **le calendrier**, jamais demandée — et la dérogation se justifie à l'écran | Poser la question à l'inscription reviendrait à faire choisir entre deux écrans que personne n'a encore vus, et à retarder la valeur au moment où il faut la montrer ; une préférence enregistrée pour rien devient une préférence oubliée (D13). La règle tient en une phrase : **on ouvre sur « préparer », sauf le jour du culte, tant que rien n'a été capté ce jour-là**. Elle est asymétrique par construction — se tromper de page coûte une tape, rater la capture coûte la prédication, et le domaine du serveur l'écrit : *« la capture n'est jamais refusée ; ce qui n'est pas capté dimanche est perdu pour toujours »*. Le jour du culte se déduit sans rien demander : le `serviceDate` posé à la main d'abord, le jour le plus fréquent du corpus déjà capté ensuite — ce qui vaut pour une assemblée du mercredi soir — dimanche à défaut. **Retenir la dernière page visitée a été écarté** : le pasteur qui ferme sur « préparer » le samedi soir rouvrirait là dimanche matin, et superposer les deux règles rendrait l'écran imprévisible, ce qui est pire que d'avoir tort de façon constante. Enfin le bandeau « Culte aujourd'hui · rien n'est encore capté » n'est pas décoratif : un automatisme qui ne se justifie pas passe pour une panne. **La même déduction sert deux fois** : elle propose aussi la date du culte à l'ouverture d'une préparation (`nextService`). Trois endroits écrivaient « dimanche » en dur — la proposition du formulaire, la puce du composeur, la ligne de la carte d'accueil — et un pasteur qui prêche le mercredi soir lisait « dim. 26 août » sur un mercredi, puis corrigeait la date à la main à chaque préparation. Le jour se lit désormais **dans la date** (`frenchShortDate`), et le jour de l'assemblée dans son corpus. |
| D51 | **L'accueil est la conversation** ; la liste passe au tiroir, et la bascule demande avant d'agir | Trois corrections qui n'en font qu'une : *ce qu'on fait tous les jours reste sous les doigts, ce qu'on consulte de temps en temps se range*. **La conversation d'abord** — on écrivait sa phrase à l'accueil, on était poussé sur un écran portant un second champ identique, et la conversation commençait là : deux écrans, deux composeurs, une seule conversation. La répétition ne se voyait pas sur une maquette, elle a sauté aux yeux sur un téléphone. Ce qu'on écrit à l'accueil y continue désormais (`PreparationConversation`, montée sous la barre de l'accueil), et `resumeId` décide laquelle s'ouvre : ce qui rend la main d'abord, puis le culte le plus proche, puis le dernier travail touché. **Le tiroir ensuite** — le fil groupé par récence n'avait plus de place sans reprendre à la conversation ce qu'on venait de lui donner ; il y rejoint le profil, qui occupait un coin permanent de la barre pour un écran ouvert une fois par mois, les réglages, et « Projets » affiché inactif avec ce qu'il attend (D13). **La bascule enfin** — une icône seule n'explique pas où elle emmène : elle changeait de travail avant d'avoir dit ce qu'elle changeait. La feuille nomme les deux côtés et marque celui où l'on est ; c'est toujours un seul geste, avec une phrase entre les deux. |
| D52 | **Q2 tranchée : la transcription tourne sur l'appareil**, avec un modèle embarqué de la famille Whisper | La contradiction était ouverte depuis le début — la file serveur prévoyait `transcrire`, la maquette promettait « sur l'appareil », et les deux ne pouvaient pas être vrais. La spec T-Rec la tranche **par implication sans le dire** : F3 exige un sermon entier sans connexion et I23 que la première détection ne dépende pas du réseau ; sans transcript, pas de détection locale, donc le STT est embarqué ou la spec ne tient pas. **Ce n'est pas une préférence de modèle** : l'étage 2 exige « timestamps mot à mot, score de confiance conservé par mot », I26 pose son seuil par span et I28 ancre la capsule au fragment source. Le reconnaisseur système (`speech_to_text` 7.4.0, déjà au dépôt) rend `recognizedWords` et **une seule confiance pour tout le résultat** — les deux invariants n'auraient rien où s'accrocher ; et sur la plupart des Android il envoie l'audio chez Google, ce qui rendrait D10 faux au sens propre. Vosk tient le hors-ligne mais son français est trop faible pour un transcript qu'on comparera à un squelette ; un service distant casse I23, F3 et D10 d'un coup, et coûte à la minute sur chaque culte de chaque assemblée. **Trois contreparties assumées** : Whisper invente du texte sur les silences — un culte en est plein, il faut une détection d'activité vocale en amont ; il ne sépare pas les locuteurs, donc la réserve de l'écran de relecture reste entière ; et l'accent ivoirien avec passages en dioula fera monter le taux d'erreur — ce que la mesure en trois églises existe précisément pour trouver. Le choix du gabarit — `tiny`, `base`, quantisation — reste au banc d'essai, pas au décret. |
| D53 | La capture s'écrit en **fragments de trente secondes**, en PCM 16 kHz mono, et le disque fait foi | Trois raisons qui tiennent ensemble. **Trente secondes est la fenêtre de Whisper** : un fragment se transcrira d'une passe sans être recoupé, et c'est aussi ce qu'on accepte de perdre si l'application meurt — une demi-minute, jamais le culte. **16 kHz mono PCM est exactement ce que Whisper mange** : ni rééchantillonnage ni décodage entre l'étage 1 et l'étage 2, sur un téléphone qui fait déjà tourner le modèle ; le prix est réel — 32 ko/s, ~77 Mo pour quarante minutes contre 19 en AAC — et l'audio ne vit que sept jours. **La coupe est comptable, pas acoustique** : fragmenter en arrêtant puis relançant l'enregistreur coûterait un blanc à chaque frontière, soit plusieurs secondes de prédication perdues sur quatre-vingts fragments, invisibles et irrécupérables ; on lit donc le flux et on le découpe soi-même. Enfin le nom du dossier porte l'identifiant et le début, les octets donnent la durée — le PCM est à débit constant — et un témoin d'arrêt propre dit, **par son absence**, qu'une capture s'est interrompue toute seule. Rien à tenir à côté, rien qui puisse diverger du disque. |
| D54 | La file d'envoi tient sur **une marque haute**, écrite après l'accusé, et le fragment s'écrit sous `.part` avant d'être renommé | Quatre choix qui se tiennent. **Une marque haute suffit** : les fragments sont numérotés et partent dans l'ordre, donc un seul entier — combien le serveur a accusés — dit tout. Un journal par fragment finirait par diverger du disque, et la divergence irait dans le pire sens : croire envoyé ce qui ne l'est pas. **La marque s'écrit après l'accusé, jamais avant** : dans l'autre ordre, une application tuée entre les deux laisserait un fragment marqué envoyé qui ne l'est pas, et il ne repartirait jamais. Ainsi le pire est un fragment envoyé deux fois, ce que l'additivité stricte (I24) est faite pour absorber — *le serveur sait absorber un doublon, il ne sait pas deviner un trou*. **Un refus arrête la file sans sauter le fragment** : le prochain passage reprend exactement là. **Et l'écriture passe par `.part` puis un renommage**, parce que le renommage est atomique et l'écriture ne l'est pas : sans ce détour, la file pourrait lire un fragment à moitié écrit et l'expédier tel quel, ce que I24 interdit ensuite de corriger. Un `.pcm` présent est complet par construction. 🔴 **Le tri de la file est un défaut trouvé par son test** : il portait sur le chemin, donc sur l'identifiant, alors que l'échéance se lit sur la date — une capture nommée « a… » passait devant une capture de la semaine précédente, à un jour de sa purge. La plus ancienne passe devant : si elle ne part pas maintenant, elle ne partira jamais. |
| D55 | **Urim rédige le plan et dit pourquoi**, au lieu de faire choisir entre `expositif × doctrinal` et `textuel × typologique` | Le fondateur l'a vu sur un téléphone, et l'a dit en une phrase : *« il ne faut pas donner du boulot en supplément »*. L'étage 6 proposait trois couples plan × matière avec, pour tout motif, un niveau de risque — « faible », « moyen », « élevé ». Trois défauts d'un coup. **C'est du vocabulaire d'exégète, pas de prédicateur** : un pasteur ne choisit pas entre « textuel » et « thématique », il veut un plan. **Un adjectif sans motif ne dit rien** : les couples écartés sont argumentés — *« l'unité ne met en scène aucun personnage : Nicodème a quitté le dialogue »* — les couples retenus ne le sont pas. On explique pourquoi on refuse, jamais pourquoi on accepte. **Et le travail est reporté sur le pasteur** au moment précis où il vient chercher de l'aide. Désormais : Urim tranche le couple, **rédige les points**, et pose une seule question — « vous changez quoi ? ». Le pasteur corrige au lieu de choisir. ⚠️ **Le prix est réel et il se paie à chaque tour** : Urim tranche une question technique sans la poser, donc il doit **dire pourquoi il l'a tranchée**, à chaque fois. Un plan rédigé sans son motif serait un oracle — exactement ce que le filet doré existe pour empêcher. La machinerie est à moitié là : `PlanSuggestion(body, transition, model)` rédige déjà, mais **après** que le squelette est choisi ; il s'agit de la déplacer avant. |
| D56 | L'audio ne monte que pendant la **campagne de mesure**, sous un réglage explicite qui s'éteint ensuite | Avec le transcript fabriqué sur le téléphone (D52), l'audio n'a plus **aucune raison technique** de partir : c'est du texte rédigé qui monte, et le domaine serveur garde pourtant `audio_purge_at` et un état `captée`. La seule raison qui reste est de comparer le transcript embarqué à une référence humaine — ce que la mesure dans trois églises exige (I30 : *« un score produit par un modèle pour juger un autre modèle est interdit »*). C'est une raison de **campagne**, pas d'architecture. Donc un mode daté, qui se coupe quand le verdict tombe. **Sans cette borne, on le garderait par inertie**, et il coûterait des mégaoctets sur chaque forfait à Abidjan — pour une référence dont plus personne n'aurait l'usage. Ce que ça implique : le réglage est visible et le pasteur sait quand il est actif, parce que « sur l'appareil » cesse d'être vrai tant qu'il l'est. |
| D57 | **« J'ai prêché celle-ci » ferme la préparation** — mais seulement quand c'est son auteur qui archive | Archiver sans fermer laisserait un travail fini en tête du fil, et demanderait **deux gestes pour une seule réalité** : le pasteur devrait dire qu'il a prêché, puis dire qu'il a terminé. ⚠️ **La garde est indispensable, et elle n'est pas évidente.** `record_from_study` appelle `ensure_may_read`, pas `ensure_may_prepare` : un pasteur qui relit le travail d'un confrère peut archiver **sa** prédication à partir de cette préparation — c'est voulu, *« l'archive est celle de qui archive, c'est lui qui est monté en chaire »*. Fermer sans condition clôturerait donc le travail de l'auteur parce qu'un lecteur l'a prêché, exactement le genre de dommage que ce service existe pour empêcher (*« rien ne peut salir l'archive de quelqu'un d'autre »*). La fermeture ne se déclenche donc que si `author_id == actor_account_id`, et seulement depuis `ouverte` : une préparation **rangée** reste rangée, une close l'est déjà. Reste à écrire dans `archive_service.record_from_study` — la session du 27/08 n'a pas pu écrire dans `back-dorea`. |
| D23 | Un seul rafraîchissement à la fois, un seul rejeu par requête | Trois écrans qui échouent ensemble ne doivent pas déclencher trois rotations : la deuxième invaliderait le jeton de la première. Et une requête qui échoue deux fois signe une session morte, pas une boucle à retenter. |

## Dettes assumées

| Dette | Échéance |
|---|---|
| `DevAuthDataSource` accepte un code vérifié localement — ne prouve rien. Coupée par `--dart-define=USE_MOCK_AUTH=false`, interdite en production | À la première campagne contre le serveur |
| Identifiants de démonstration en dur : numéro prérempli, code SMS fixe, code secret suggéré. Affichés seulement quand personne ne répond vraiment | Avec le vrai serveur SMS |
| APK signé avec la clé de debug — `signingConfigs.getByName("debug")` en release. L'`applicationId`, lui, est passé à `app.dorea.urim` : la dette ne le disait plus juste, et un APK installé sur un vrai téléphone l'a montré | Avant toute distribution |
| La dérivation locale du code secret vit dans les préférences ; les jetons, eux, sont au coffre matériel | Avant toute mise en ligne |
| Les églises et les appareils du profil viennent d'un jeu d'exemple en mémoire | Q9 et Q11 |
| La relecture d'une prédication et les capsules de synthèse sont **scriptées** : aucun moteur ne les produit. Le fil guidé, lui, parle au vrai moteur | Q2, Q3 |
| Le fil guidé parle le contrat du serveur, mais un build de démonstration le fait **jouer par un mannequin** (`DemoUrimEngine`) : quatre étages scriptés, aucune Écriture consultée. Il imite la forme du contrat, pas le raisonnement | Quand l'application vise le serveur par défaut |
| Le thème reste un gabarit de codes bruts **à l'écran** — « theologie_propre, en textuel doctrinal ». Le document, lui, ne s'en sert plus pour se titrer | Côté serveur, aller chercher le libellé de l'axe |
| Le compte rendu de séance est perdu en quittant l'écran. C'est cohérent avec D28, mais ce qui a été touché il y a cinq minutes disparaît en revenant de l'accueil | À évaluer à l'usage — un cache de session suffirait |
| Une prédication transcrite n'a **pas d'issue moteur** : sa pastille « Retour disponible » a disparu du fil. Le serveur ne connaît que les préparations écrites — sa capture est verrouillée à l'étape 1 | Q2, avec la capture réelle |
| Le bouton « Enregistrer la prédication » tient le bas de la page « prêcher » **et ne répond pas** : ni l'appareil ni le serveur ne portent la capture. Il garde sa place plutôt que de disparaître (D13), et la ligne dessous dit ce qu'il attend — mais tant qu'il est mort, la règle d'ouverture (D50) peut poser le pasteur, un dimanche matin, devant une page dont le geste central est fermé | Q2, étape 1 de M3 |
| La suppression n'efface que le contenu des contextes **listés** dans `get_delete_account_command` — aujourd'hui Urim seul. Un contexte qui gardera du contenu personnel sans s'y inscrire le laissera survivre à son auteur | À chaque nouveau contexte porteur de contenu personnel |
| « Écrire mes points » et les deux livrables sont **fermés côté application** : le serveur les sert, aucun écran ne les ouvre. La ligne le dit (D13), ce qui ne la rend pas moins due | Palier 1 de la feuille de route |
| Une préparation ne porte **qu'un axe**, et le code le tranche sans que le produit l'ait posé. Un pasteur qui veut prêcher le Christ *dans* les relations humaines — ce que dit Colossiens 3:23-24 — n'a pas de geste pour le dire | Question de produit, à ouvrir |
| **Le corpus dit où un mot paraît, presque jamais ce qu'il veut dire** : 80 gloses pour 14 101 lemmes (0,6 %). εἴδωλον — 11 occurrences — n'en a pas. La concordance (`GET /urim/lemmes`) existe et répond ; le dictionnaire, lui, est vide à 99,4 %. La roadmap promet « les mots de l'original » : ce qui existe est la concordance, pas le sens | Avant de promettre l'original au pasteur |
| Le document produit est **posé dans un dossier**, jamais partagé : `share_plus` exige `win32 ^5` et le coffre à secrets `^4`. Le pasteur doit aller le chercher avec un gestionnaire de fichiers au lieu de l'envoyer ou de l'imprimer d'un geste | Quand le coffre montera de version, ou avec un autre canal de partage |
| Le **PowerPoint** reste fermé côté application : composer des diapositives demande un éditeur — titre, référence, texte projeté — qui n'existe pas. Le serveur, lui, l'ouvre dès qu'un plan porte un point | Sprint suivant, avec l'éditeur de diapositives |
| Le mode développeur Windows n'est pas activé — bloque les compilations Windows | Au besoin |
