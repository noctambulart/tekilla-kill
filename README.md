# Tequila Kill

Tequila Kill est un jeu de combat en arène, en vue du dessus, où jusqu’à **16 joueurs** se disputent la dernière bouteille de tequila d’**Arroyo Seco**, un petit village fictif de l’Arizona privé de livraison.

Chaque personnage possède une arme et une compétence spéciale pour s’emparer de la bouteille. Celui qui la détient la boit jusqu’à ce qu’un autre la lui arrache. Quand elle est vide, **le joueur qui en a bu le plus remporte la partie**.

Ce projet reprend un prototype développé il y a plusieurs années, avec l’aide de l’IA.

## Concept et présentation

- [Concept du jeu](docs/concept.md)
- [Fiche unique de présentation](output/pdf/tequila-kill-fiche.pdf)
- [Références graphiques originales](docs/references-graphiques.md)
- [Fiches illustrées des versions Unity v1 et v3](docs/archives-unity.md)
- [Vocabulaire du jeu](GLOSSARY.md)

## Organisation du développement

- [Organisation de la production, des conversations, des agents et des skills](docs/agents/organisation.md)
- [Carte des décisions pour la première version partageable](https://github.com/noctambulart/tequila-kill/issues/2)
- [Outils de reconstruction et dépendances Python](scripts/README.md)

## État du projet

Le projet utilise **Godot 4.7.2 standard**, **GDScript** et le moteur de rendu **Compatibility**, pour une base 2D. Une cinématique d’environ 50 secondes précède le titre. **Jouer ouvre désormais la v0.3 : Poncho humain contre Garcia bot**, sur la carte actuelle d’Arroyo Seco, jusqu’au résultat, au rejeu ou au retour au titre. La v0.1 reste accessible dans sa scène de développement ; son [accord du producteur du 25 novembre 2026](https://github.com/noctambulart/tequila-kill/issues/59#issuecomment-7167447296) et ses retours restent dans les Issues.

La **[v0.2 · Un round contre Garcia](https://github.com/noctambulart/tequila-kill/milestone/2)** est validée explicitement par le producteur le **27 novembre 2026**, après les ajustements de récupération de bouteille : étourdissement **0,8 s**, projection **150 unités en 0,22 s**. [Accord global et suivi #26](https://github.com/noctambulart/tequila-kill/issues/26), [livraison intégrée](output/gameplay/2026-11-27-v02/README.md) et [réglage final vérifié](output/gameplay/2026-11-27-v02-stun-v3/README.md). La **[v0.3 · Arène et objets cassables](https://github.com/noctambulart/tequila-kill/milestone/3)** est validée explicitement par le producteur le **27 novembre 2026**, après les corrections de casse, de crosse, d’ivresse et de ramassage. Elle ajoute le dash par-dessus les petits objets et la vie en quatre segments. [Bilan de livraison et validation](output/releases/v0.3/README.md), [suivi #29](https://github.com/noctambulart/tequila-kill/issues/29), [tag v0.3](https://github.com/noctambulart/tequila-kill/tree/v0.3). Le réseau reste pour une étape ultérieure.

La **[v0.4 · Boucle complète et salon local](https://github.com/noctambulart/tequila-kill/milestone/4)** est cadrée mais non lancée : salon à quatre places, humains par ordre d'arrivée et bots, personnages actuels avec le même tir, podium et rejeu. Le [grill et les concepts DA du salon #67](https://github.com/noctambulart/tequila-kill/issues/67) bloquent toutes ses autres missions jusqu'à validation. Les compétences spéciales passent en **[v0.5](https://github.com/noctambulart/tequila-kill/milestone/6)** ; le fusil de Garcia est reporté sans version fixée. Chaque version validée est entièrement commitée et identifiée par un tag poussé sur GitHub, selon la [procédure de conservation des versions](docs/agents/organisation.md#commit-et-tag-de-chaque-version).

## Ouvrir et lancer le projet

1. Utiliser Godot **4.7.2 standard** (la version .NET n'est pas nécessaire).
2. Dans le gestionnaire de projets Godot, choisir **Importer** et sélectionner [`godot/project.godot`](godot/project.godot).
3. Ouvrir le projet, puis appuyer sur **F5** pour lancer le projet (ou **F6** pour lancer uniquement la scène ouverte).

Depuis la racine du dépôt, si `godot` est disponible dans le terminal :

```sh
godot --path godot --editor
godot --path godot
```

Pour démarrer en plein écran, lancer `godot --path godot --fullscreen`. Avec **F5**, décocher **Intégrer le jeu au prochain lancement** dans le menu **⋮** tout à droite de la barre **Jeu**, relancer, puis cliquer sur le bouton vert de la fenêtre macOS. Pour agrandir l’aperçu intégré, choisir **Conserver le format d’image** (*Keep Aspect Ratio*) dans ce même menu. [Modes d’affichage dans Godot](https://docs.godotengine.org/en/stable/tutorials/editor/game_embedding.html)

L’introduction démarre automatiquement. Un **clic gauche n’importe où sur l’image**, **Espace**, **Entrée**, **Échap**, le bouton affiché ou **A / B / Start** sur une manette permettent de la passer. La lecture complète et le passage conduisent à l’écran titre. Celui-ci conserve trois boutons : **Jouer** ouvre le round Poncho contre Garcia bot, **Revoir l’introduction** relance la cinématique et **Quitter** ferme le jeu. Le focus arrive sur **Jouer**. Les boutons de menu utilisent les actions d’interface par défaut de Godot.

La scène `godot/scenes/intro/intro.tscn` peut aussi être ouverte et jouée avec **F6**, indépendamment du gameplay. Elle rejoint le titre en fin de lecture. Suivi de cette première version : [Issue #16](https://github.com/noctambulart/tequila-kill/issues/16), dans [l'epic de l'introduction](https://github.com/noctambulart/tequila-kill/issues/15).

## Jouer à la v0.3 · Arène et objets cassables

Lancer `godot --path godot`, passer l’introduction et choisir **Jouer**. Poncho affronte Garcia bot sur la même carte ; le décompte, la bouteille, la pause, le résultat et le rejeu sont conservés.

- **Ramassage** : la bouteille se récupère automatiquement en passant à **28 unités** de son point au sol (contre 15 auparavant). Les murs et couverts intacts arrêtent cette portée ; le fantôme et l’étourdissement bloquent toujours la prise.
- **Casse au tir ou à la crosse** : un pot résiste à **1 impact**, une chaise à **3**, une caisse à **5**. Une balle et une crosse infligent les mêmes dégâts. Les débris conservent la taille globale de l’objet intact, leurs proportions et leur appui au sol. Les débris laissent passer personnages et balles. Les bâtiments et les autres meubles restent permanents. Les trois résistances sont réglables sur la carte.
- **Dash** : Espace ou LT permet de franchir les pots et chaises intacts, sans dégâts et à portée normale. L’arrivée est vérifiée avec **2 unités de marge** autour des pieds. Si elle est occupée ou si un mur, une caisse ou un adversaire bloque le trajet, le dash s’arrête devant le petit objet. Une interruption pendant le franchissement replace le personnage au dernier point libre du trajet ; la pause conserve le mouvement en cours.
- **Coup de crosse** : clic gauche ou RT frappe automatiquement un adversaire actif à **30 unités maximum**, dans l’arc frontal de **90°** de la visée, si le trajet est libre. Il fonctionne à vide, ne consomme aucune cartouche et partage la cadence du tir de **0,24 s**. Un nouvel appui interrompt la recharge pour frapper. La crosse reste possible pendant l’étourdissement ; elle est bloquée en dash et en fantôme. Garcia utilise la même règle. Si un mur ou un objet intercepte le trajet du tir dans les 30 premières unités, la commande donne également une crosse sans cartouche : dégâts habituels sur les objets cassables, aucun dégât sur les murs permanents. Un obstacle proche sur le côté ne la déclenche pas.
- **Vie** : les quatre segments sous chaque personnage perdent une unité par balle ou crosse. En fantôme, ils se remplissent progressivement sur **5 s**, avec un son à chaque segment terminé, quatrième compris. Le calcul interne conserve 100 PV / 25 dégâts pour rester compatible avec les outils de développement.
- **Garcia** : la casse met à jour ses chemins et ses lignes de tir. Rejouer remet les objets intacts, la vie et la bouteille à zéro.

Les résistances et la portée de crosse ci-dessus sont les réglages choisis par le producteur le 27 novembre 2026. [Livraison initiale](output/gameplay/2026-11-27-v03/README.md) et [corrections après essai : taille des débris et crosse devant les obstacles](output/gameplay/2026-11-27-v03-review/README.md). La [validation globale du producteur](output/releases/v0.3/README.md) clôt cet essai, suivi dans [#29](https://github.com/noctambulart/tequila-kill/issues/29).

```sh
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_v03.gd
# Contrôle avec rendu natif et captures :
godot --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_v03.gd
```

## Base v0.2 · Un round contre Garcia

Depuis Terminal à la racine du dépôt, lancer `godot --path godot`, passer l’introduction si souhaité, puis choisir **Jouer**. Aucun raccourci F6 ni branchement de manette n’est nécessaire pour ce duel contre le bot.

- **Poncho au clavier/souris** : ZQSD ou WASD, souris pour viser, clic gauche pour tirer, R pour recharger, Espace pendant un déplacement pour dasher.
- **Poncho à la manette** : brancher une manette et cliquer sur **Passer à la manette**. Les sticks contrôlent déplacement et visée, RT tire, LT dashe, X ou carré recharge. Garcia reste contrôlé par le bot. Le bouton permet de revenir au clavier.
- Après le décompte, marcher sur la bouteille pour boire automatiquement. Tirer sur le porteur la fait tomber vers le tireur. La réserve commune se lit dans la bouteille en haut ; les petites étoiles autour des personnages suggèrent la quantité déjà bue. Le porteur a sa bouteille oscillante au-dessus de la tête et des éclats distincts.
- À zéro vie, le personnage devient fantôme, reste déplaçable très lentement et récupère progressivement sa vie. Il ne peut plus combattre ni prendre la bouteille jusqu’au retour à pleine vie ; sa quantité bue reste acquise.
- **Échap / Start** ou **Pause** suspend toute la partie. La perte de focus et le retrait de la manette utilisée mettent aussi en pause ; une reprise volontaire est nécessaire. **F** bascule le cadrage et **P** le plan de développement.
- Bouteille vide : le résultat annonce le vainqueur et sa part de la bouteille initiale, ou une victoire partagée sur égalité exacte. **Rejouer** remet la partie à zéro avec le même duel et un nouveau décompte ; **Retour au titre** rejoint le menu.

Après le retour de review, le [troisième réglage corrigé est validé](output/gameplay/2026-11-27-v02-stun-v3/README.md) : le porteur blessé reste immobilisé **0,8 s**, avec combat disponible, et la bouteille est projetée à **150 unités**. Ce réglage est inclus dans la validation globale de v0.2 dans #26.

La review porte sur le duel entier : sensations face au bot, passages dans les bâtiments, récupération de la bouteille, lisibilité des effets aux deux cadrages, sons, pause et parcours de rejeu. [#26 et preuves de livraison](output/gameplay/2026-11-27-v02/README.md). La compatibilité avec une manette physique reste à essayer sur le modèle du producteur ; les vérifications automatisées utilisent des événements simulés.

## Essayer le saloon retravaillé

Pour le développement, lancer directement la scène `saloon_study.tscn` ci-dessous ouvre la zone étalon saloon–entrée–rue–maison, réalisée après les retours sur les proportions, les sprites couchés, les sols et les passages bloquants. Les mêmes personnages, commandes, tirs et rechargements de l’essai solo sont utilisés. **F** bascule entre vue d’ensemble et caméra adaptative ; **P** montre les empreintes solides en rouge, **F2** réinitialise et **Échap** revient au titre.

Cette étude reprend les rapports du concept avec des sprites à échelle uniforme, des chaises dessinées dans leur orientation, des murs en bois/adobe, des matériaux de sol et une transition continue aux ouvertures. La lumière chaude entre depuis les façades ouvertes, avec un intérieur plus frais. La collision est placée aux pieds des deux personnages. **Le producteur a retenu cette direction et sa palette chaude pour toute la carte** : ces principes sont maintenant appliqués au [village V6](#visiter-la-carte-darroyo-seco). La zone étalon reste disponible comme référence locale.

```sh
godot --path godot --scene res://scenes/arroyo_seco/saloon_study/saloon_study.tscn
godot --headless --path godot --script res://tools/verify_saloon_study.gd
# Captures natives déterministes, y compris si la fenêtre est masquée sur macOS :
godot --path godot --fixed-fps 60 --script res://tools/verify_saloon_study.gd
```

Les données de la zone sont dans `godot/scenes/arroyo_seco/saloon_study/layout.json`. `scripts/arena/prepare_saloon_study.py` reproduit les ressources avec Python + Pillow, sans génération ni déformation des images. Les sources originales, prompts de l’outil intégré `image_gen.imagegen`, captures réelles et relevé de vérification sont conservés dans [le dossier de l’étude](output/arena/2026-11-25-saloon-study/README.md). Le contrôle vérifie notamment le coin transparent de la maison, le débord du toit, les trois ouvertures, le vide du comptoir en L, les collisions aux pieds et les commandes réelles. La fidélité artistique s’examine sur les captures et en jouant ; elle n’est pas déduite des tests. Suivi : [correction #60](https://github.com/noctambulart/tequila-kill/issues/60).

Après le retour sur la cohérence des personnages avec la maison, cette zone utilise les **variantes chaudes de Poncho et Garcia** : reflets miel/crème, tissu cuivré et ombres chocolat, avec la couronne olive, le foulard rouge et les épaules indigo conservés. Les PNG sont dans `godot/scenes/character/assets/saloon_warm/` ; `scripts/arena/prepare_warm_players.py` reproduit les animations avec une échelle, un ancrage et une palette communs à chaque personnage. [Comparaison avant/après, sources et contrôles](output/arena/2026-11-25-saloon-study/character-warm/README.md). `verify_saloon_study.gd` écrit désormais ses captures dans ce sous-dossier. Pour vérifier également les cycles des deux personnages et leurs huit visées : `godot --path godot --fixed-fps 60 --script res://tools/verify_player_visuals.gd -- --warm`.

## Jouer à la v0.1 · Essai solo

L’essai solo historique se lance directement avec `godot --path godot --scene res://scenes/arroyo_seco/solo_trial.tscn`. Poncho explore Arroyo Seco, vise, tire et dashe. Garcia reste en place et encaisse les tirs. Cette scène reste disponible pour comparer et ajuster carte, commandes et sprites ; le bouton Jouer ouvre désormais la v0.2.

- **Clavier et souris** — ZQSD ou WASD pour se déplacer, souris pour viser, clic gauche pour tirer, Espace pour dasher et R pour recharger.
- **Manette** — brancher une manette et choisir **Passer à la manette**. Les sticks contrôlent le déplacement et la visée, RT tire, LT déclenche le dash et X ou carré recharge.
- **F2** ramène les deux personnages à leur position de départ et remet la cible et le chargeur à neuf. **F** bascule entre la caméra adaptative et la vue d’ensemble, **P** affiche le plan et **Échap** revient au titre.

Quand tu essaies de tirer à vide, les cartouches clignotent en rouge. Garcia sursaute quand un tir touche sa silhouette, y compris le bord du chapeau. Un tir contre un mur projette des éclats au point d’impact. [Tir et impacts](https://github.com/noctambulart/tequila-kill/issues/20)

Chaque cartouche insérée pendant le rechargement joue un clic métallique extrait des [anciens builds Unity](docs/archives-unity.md#bruitage-de-rechargement).

La caméra garde Poncho et Garcia à l’écran. Son zoom rapproché est limité à **0,85**, soit environ **18 % de terrain visible en plus** qu’au zoom natif quand les personnages sont côte à côte. La marge de cadrage passe de **72 à 160 unités** selon leur éloignement, avec du champ devant Poncho quand il se déplace. Le dézoom nécessaire à leur visibilité est immédiat ; le rapprochement reste progressif. Le poncho tombe jusqu’à l’ombre au sol et masque les pieds dans toutes ses poses. [Caméra adaptative](https://github.com/noctambulart/tequila-kill/issues/46) · [Sprites](https://github.com/noctambulart/tequila-kill/issues/58)

Suivi des essais et des ajustements de cette version. [V0.1 — Essai solo](https://github.com/noctambulart/tequila-kill/issues/59)

## Essayer la bouteille — missions #23 et #24

Depuis Terminal, à la racine du dépôt, lancer la scène de contrôle (aucun raccourci F6 nécessaire sur Mac) :

```sh
godot --path godot --scene res://scenes/match/match.tscn
godot --headless --path godot --script res://tools/verify_match.gd
godot --headless --path godot --script res://tools/verify_bottle_drops.gd
```

Cette scène est maintenant le duel public **Poncho humain / Garcia bot**. Passer sur la bouteille la ramasse automatiquement ; son porteur boit pendant le déplacement, la visée, le tir, le dash et le rechargement. **Échap** suspend la consommation et **Rejouer** remet les états à zéro. Les anciens contrôles mécaniques `verify_match` et `verify_bottle_drops` conservent leurs fixtures à deux humains, isolées du parcours public ; `verify_v02` vérifie le bot et l’assemblage final.

Un tir qui blesse le porteur, même sans épuiser sa vie, projette la bouteille vers la position du tireur au moment de l’impact. Un actif autorisé peut la récupérer pendant la projection. **Réglage d’équilibrage validé le 27 novembre 2026 : projection de 150 unités en 0,22 s et étourdissement du porteur de 0,8 s.** Pendant cet étourdissement, déplacement, dash et ramassage sont bloqués ; visée, tir et recharge restent disponibles, et le blessé reste vulnérable. Un dash en cours s’arrête, une recharge engagée continue. Le coup fatal donne priorité au mode fantôme. La pause gèle le délai et Rejouer le remet à zéro. L’exclusion personnelle existante de 0,45 s reste comprise dans ces 0,8 s, sans ajouter une seconde d’interdiction. La collision suit les pieds et arrête la projection au contact du décor. [Réglage et vérifications de cet essai](output/gameplay/2026-11-27-v02-stun-v3/README.md).

Les scores et la réserve sont calculés dans `godot/scenes/bottle/bottle.gd`, sans pourcentage affiché pendant le round. `get_state()` et les événements de prise, perte et bouteille vide alimentent la présentation V11 et les sons V1 de #66 sans seconde logique de score. Le contenu et le débit restent réglables (valeurs provisoires : 2 400 unités et 60 unités/s). La présentation et le parcours du round sont disponibles pour la review de #26.

Étapes conservées : [#23 validée](https://github.com/noctambulart/tequila-kill/issues/23), [sa livraison](output/gameplay/2026-11-26-issue-23/README.md) ; [#24](https://github.com/noctambulart/tequila-kill/issues/24), [sa livraison](output/gameplay/2026-11-27-issue-24/README.md). Le [lot v0.2](output/gameplay/2026-11-27-v02/README.md) décrit l’assemblage courant. Vérification technique et validation du producteur restent distinctes.

## Essayer le tir, le rechargement et les déplacements — missions #18 à #21

La zone de développement historique reste accessible directement, sans entrée dans le menu :

```sh
godot --path godot --scene res://scenes/movement_test/movement_test.tscn
```

- **J1 bleu** : ZQSD sur AZERTY / WASD sur QWERTY, souris pour viser, **clic gauche pour tirer**, **R pour recharger**, Espace pour dasher. Les touches sont repérées par leur position physique.
- **J2 rouge** : première manette connectée, stick gauche pour bouger et doser la vitesse, stick droit pour viser, **gâchette droite (RT / R2) pour tirer**, **X / carré pour recharger**, gâchette gauche (LT / L2) pour dasher. La dernière visée est conservée au relâchement du stick droit. Une manette branchée après l'ouverture peut aussi rejoindre l’essai. Sans manette, J2 reste une cible immobile.
- Contourner les trois obstacles et essayer les limites de la zone, les diagonales et les changements de direction. Le bouton **Retour au titre** permet de recommencer sans revoir l'introduction.

La vitesse maximale est de **210 px/s**, contre 200 au dernier essai. La montée en vitesse prend environ **150 ms** et le freinage environ **130 ms** depuis la pleine vitesse, avec une dizaine de pixels de glissement. Dans un virage serré, le personnage conserve une partie de son élan dans l’ancienne direction pendant qu’il prend la nouvelle. La trajectoire s’arrondit. La vitesse, l’accélération, le freinage et la réponse dans les virages sont réglables séparément dans Godot.

Le dash donne une impulsion de **120 ms** dans la direction de l’élan actuel. La trajectoire et la visée restent fixes jusqu’à la fin de l’impulsion ou jusqu’au contact d’un obstacle. La jauge sous le personnage se remplit en **550 ms** après le dash : elle forme un trait de **1 unité logique** de haut et disparaît dès que le dash est prêt. Il faut alors être en mouvement et effectuer un nouvel appui. [Issue #19](https://github.com/noctambulart/tequila-kill/issues/19)

Le revolver provisoire contient **6 balles**, tire au maximum une fois toutes les **240 ms** et inflige **25 points de dégâts** sur **100 PV**. Un appui bref tire une fois ; le maintien répète jusqu’au chargeur vide, sans rechargement automatique. Les balles parcourent **900 px/s**, sur **720 px** au maximum, et s’arrêtent au premier personnage ou obstacle. Ces réglages sont exposés dans Godot. Un flash de bouche, une traînée et un éclat d’impact rendent le tir visible ; la cible touchée clignote brièvement. Vie et munitions sont affichées sous les personnages et dans le bandeau supérieur.

Un appui sur **R** ou **X / carré** remplit volontairement le chargeur **balle par balle**, même s’il est partiellement plein. Une balle arrive toutes les **400 ms**, valeur réglable sur le revolver. La réserve est infinie. Chaque cartouche apparaît entière sous le personnage au moment où la balle est ajoutée au chargeur, sans jauge ni remplissage intermédiaire ; le bandeau indique « recharge ». Déplacement et visée restent libres. Un **nouvel appui de tir avec au moins une balle disponible** interrompt pour tirer, en conservant les balles ajoutées et en respectant la cadence. Un ancien maintien ne coupe pas la recharge ; un appui à vide n’est pas mémorisé pour tirer à l’arrivée de la première balle. Tir et recharge demandés ensemble donnent priorité au tir si une balle est disponible. Suivi : [Issue #21](https://github.com/noctambulart/tequila-kill/issues/21).

Le dash laisse **continuer une recharge déjà commencée**, sans remettre à zéro ni suspendre le délai de la cartouche en cours. Les nouveaux appuis de tir et de recharge pendant le dash sont ignorés, sans mise en attente. Pour commencer une recharge ou tirer après le dash, il faut un nouvel appui après sa fin ; un tir maintenu avant ou pendant le dash ne repart pas seul. Cette règle remplace l’interruption de recharge initialement retenue dans #6/#21, suivant le [retour du producteur #63](https://github.com/noctambulart/tequila-kill/issues/63).

Les contacts entre personnages repoussent légèrement sans dégâts. Le bouton **Réinitialiser l’essai** rétablit vie, chargeurs et positions et retire les projectiles. Il permet de continuer à essayer après zéro PV dans cette zone historique ; le mode fantôme de #25 est actif dans le round v0.2. Suivi du tir : [Issue #20](https://github.com/noctambulart/tequila-kill/issues/20).

Cette zone utilise les sprites de Poncho et Garcia décrits ci-dessous, avec des gestes d’arme encore provisoires pour Garcia. Les commandes sont relâchées en cas de perte de focus ou de retrait de la manette. La pause complète et la configuration J1–J4/profils restent dans leurs missions respectives. Les sensations et la compatibilité des manettes physiques restent à examiner en jouant. Suivi des déplacements : [Issue #18](https://github.com/noctambulart/tequila-kill/issues/18).

## Sprites jouables de Poncho et Garcia — missions #58 et #60

Les personnages du village V6 utilisent la palette chaude retenue le 25 novembre : **Poncho pour J1 et la visite**, avec sombrero miel, couronne olive et tissu cuivré frangé ; **Garcia pour J2**, avec chapeau chocolat, épaules indigo et foulard rouge. Les cellules source de **144 × 144 pixels** sont dessinées dans **48 × 48 unités logiques**, soit des corps d’environ 32 unités de large. En 1080p à zoom natif, un pixel de texture correspond à un pixel affiché. Les PNG courants sont dans `godot/scenes/character/assets/saloon_warm/`, indépendamment du dossier `output/`. Le tissu de Poncho rejoint son ombre au sol sans étirement. Les lots précédents restent disponibles pour comparaison et dans la zone de test historique.

Le corps conserve la projection du concept pendant la visée ; seule la couche d’arme tourne, avec la main masquée par le chapeau. Les vrais états de déplacement pilotent repos, marche et dash. Les nouvelles séquences détaillées reprennent le contrat d’animation précédent et la piste de main validée sur Poncho V4. La couche d’arme est encore commune et provisoire : le fusil et les gestes spécifiques de Garcia restent dans #39/#40. Les vitesses, collisions et règles des actions restent séparées de cette présentation.

Les sources, prompts de l’outil intégré `image_gen.imagegen`, manifestes et comparaisons sont dans `output/arena/2026-11-25-saloon-study/character-warm/`. `scripts/arena/prepare_warm_players.py` reproduit les exports avec Python + Pillow : une échelle, une palette et un ancrage communs à chaque animation, transparence binaire et rééchantillonnage au plus proche voisin. Les livraisons précédentes restent dans leurs dossiers datés. Pour vérifier les transitions réelles et la visite, et enregistrer les captures en omettant `--headless` (remplacer `--warm` par `--legacy` pour les premiers dessins ; omettre les deux pour le lot V5) :

```sh
godot --headless --path godot --script res://tools/verify_player_visuals.gd -- --warm
```

Suivi de cette intégration visuelle dans les scènes existantes : [Issue #58](https://github.com/noctambulart/tequila-kill/issues/58). L’intégration complète des actions en partie et la validation créative en jouant restent dans [#40](https://github.com/noctambulart/tequila-kill/issues/40).

## Visiter la carte d’Arroyo Seco

Pour visiter sans combat, lancer directement la scène de développement :

```sh
godot --path godot --scene res://scenes/arroyo_seco/arena_review.tscn
```

La **V6** généralise la zone étalon et les personnages chauds validés par le producteur, dans la structure du [concept aux passages en fondu](output/concept-art/2026-11-25/09-village-passages-fondu.png). Elle occupe **1440 × 960 unités**, soit une grille de **45 × 30 tuiles de 32**. Le saloon conserve ses dimensions validées de 448 × 352 unités ; l’épicerie, la remise, l’enclos et quatre maisons sont recalés autour de lui. Les quatre départs sont libres et équidistants de la bouteille. Les traversées intérieures et les contournements restent ouverts avec le mobilier intact.

Le village partage les sprites, les murs bois/adobe, les ombres et les matériaux de la référence. Huit compléments de décor ajoutent les rayonnages, produits, outils et maisons, avec deux matériaux pour le bois et la terre de l’enclos. Exports et provenance : `godot/scenes/arroyo_seco/assets/village_v6/`, complétés par la bibliothèque du saloon et certains objets V5. Les objets gardent une échelle uniforme et les rayonnages verticaux sont dessinés dans leur orientation. Les quatre lieux ont des transitions continues aux ouvertures. Les personnages utilisent leurs pieds pour les collisions et la profondeur ; les bâtiments deviennent partiellement transparents lorsqu’ils les masquent derrière un toit.

Le lot de mobilier #42 fournit aussi les **états cassés et les débris des caisses, chaises et pots**. Les 14 variantes visuelles (huit intacts et six états de destruction) sont exportées en textures `.tres` et scènes `.tscn` dans `godot/scenes/arroyo_seco/assets/prop_visuals/`. Le manifeste `assets/prop-visuals.json` précise dimensions, ancrages et rôle de chaque état. Les scènes sont uniquement visuelles : la suppression de la collision et les dégâts restent à raccorder dans #29/#43. L’aperçu comparatif et les prompts sont conservés dans `output/arena/2026-11-24/issue-42/`.

- **ZQSD / WASD** pour avancer, **souris** pour viser et **Espace** pour dasher avec Poncho.
- La visite démarre **en vue rapprochée**, à l’échelle native du personnage ; **F** ou le bouton affiche la vue d’ensemble puis permet de revenir au suivi.
- **P** ou le bouton : afficher le plan, les quatre départs et les parcours de poursuite/interception.
- **R** : revenir au départ ; **Échap** ou **Titre** : quitter la visite.

Les murs et meubles sont solides ; les seuils sont ouverts. La bouteille est un repère visuel, sans ramassage ou consommation. La casse des caisses/chaises/pots, le combat, les bots et la caméra adaptative de partie restent dans leurs missions. Cette visite au clavier-souris sert à examiner le lieu ; elle n’est pas une partie multijoueur.

La géométrie, les positions, les départs et les parcours sont éditables dans [`layout.json`](godot/scenes/arroyo_seco/layout.json), en unités du monde. Les sols et les murs utilisent les mêmes dimensions que les collisions ; les objets et maisons distinguent leur dessin de leur emprise au sol. [`build_village.py`](scripts/arena/build_village.py) reproduit la V6 en reprenant le saloon validé sans le redimensionner. Les ressources nécessaires sont livrées dans `godot/`, donc Python, les archives et les sources de génération ne sont pas nécessaires pour jouer.

Reconstruction et vérification de la V6 :

```sh
python3 scripts/arena/build_village.py
# Python avec Pillow, uniquement pour reproduire les exports graphiques :
python3 scripts/arena/prepare_village_v6.py
godot --headless --path godot --script res://tools/verify_village.gd
```

Sans `--headless`, le contrôle produit les captures de l’ensemble et de chaque quartier dans [le lot V6](output/arena/2026-11-25-village-v6/README.md), avec `verification-village.json`. Il vérifie chaque seuil, les boucles, les marges des maisons et la connexion des zones libres échantillonnées à la place. L’ancienne commande `verify_arroyo_seco.gd` lance ce même contrôle. Les étapes V4, V5 et zone étalon sont conservées dans leurs dossiers datés ; le générateur V5 est archivé dans le lot V6. La visite, l’essai solo et la partie existante utilisent désormais la même carte. Suivi : [intégration #60](https://github.com/noctambulart/tequila-kill/issues/60), puis [essai du producteur #59](https://github.com/noctambulart/tequila-kill/issues/59). Les quatre emplacements du plan n’ajoutent pas de mode à quatre. La casse et l’équilibrage de combat gardent leurs missions.

## Structure technique

- `godot/` : racine du projet importé par le moteur. Les archives, références et documents restent à l'extérieur pour éviter leur import automatique.
- `godot/scenes/main/` : scène principale et script associé. Les prochaines fonctionnalités pourront regrouper leurs scènes, scripts et ressources de la même manière.
- `godot/scenes/character/` : personnage mobile, commandes humaines ou bot, revolver et projectile séparés. Chaque humain possède ses propres actions d’entrée ; la manette est liée à un identifiant précis. Le bot fournit les mêmes intentions, sans modifier vitesse, munitions ni score. Le revolver gère le chargeur, le rechargement progressif et la cadence ; le projectile balaie chaque segment pour respecter les couverts fins et proches.
- `godot/scenes/match/` : assemblage du round, navigation sur les collisions actuelles de la carte, décompte, pause, résultat et rejeu. La grille de navigation est construite après synchronisation des collisions, pendant que les participants attendent le départ, puis actualisée après une destruction.
- `godot/scenes/bottle/` : possession et quantités uniques, effets visuels V11, cadre ovale, bouteille et sons placeholders V1 validés. Ces effets lisent les données du jeu.
- `godot/scenes/movement_test/` : zone fermée et obstacles provisoires pour le premier essai à deux, sans remplacer la future arène d'Arroyo Seco.
- `godot/scenes/arroyo_seco/` : carte, géométrie partagée, sources graphiques avec provenance et scène de visite ; indépendante de l’interface de visite pour sa future intégration en partie.
- `godot/scenes/intro/` : cinématique autonome, découpage et mouvements de caméra dans `intro.gd`, illustrations et pistes sonores dans `assets/`.
- `scripts/intro/create_audio.py` : composition et synthèse originales de la première bande sonore, reproductibles avec Python 3 sans dépendance externe. Musique et ambiance sont livrées séparément.
- `godot/tools/verify_intro.gd` : vérification de lecture, fin, passage, relecture et captures des moments clés.
- `godot/tools/verify_movement.gd` : vérification intégrée des déplacements, commandes séparées, visée, collisions et retours au titre.
- `godot/.godot/` : cache local généré automatiquement, ignoré par Git. Les fichiers `.uid` et `.import` associés aux ressources sources doivent être conservés.

Le jeu cible le **1920 × 1080** en 16:9, taille demandée à l’ouverture de la fenêtre. Godot rend la 2D directement à la taille d’affichage avec `canvas_items`, sur une grille logique de 640 × 360 avec des tuiles de 32 × 32. Au zoom natif en 1080p, une unité logique occupe trois pixels d’affichage ; les personnages actuels utilisent des cellules de 144 pixels pour 48 unités logiques, soit un pixel affiché par pixel de texture. Le filtrage reste au plus proche voisin et le texte est dessiné à la résolution de sortie. Voir la [base graphique retenue](docs/references-graphiques.md#base-pixel-art-retenue) pour les différentes densités et le comportement au dézoom.

Mission d'initialisation : [Issue #11](https://github.com/noctambulart/tequila-kill/issues/11).

## Vérification technique

Pour lancer les vérifications Godot en une commande, depuis la racine du dépôt :

```sh
python3 scripts/godot_tasks.py verifier
```

Les [commandes locales](scripts/README.md#vérifications-et-captures) permettent aussi de choisir un sujet, de produire des captures et de vérifier les liens Markdown.

Depuis la racine du dépôt, importer les ressources puis lancer brièvement la scène sans interface graphique :

```sh
godot --headless --path godot --import --log-file /tmp/tequila-kill-import.log
godot --headless --path godot --quit-after 10 --log-file /tmp/tequila-kill-run.log
```

Ces commandes vérifient l'import et le démarrage. Pour vérifier le parcours de l'introduction :

```sh
godot --headless --path godot --script res://tools/verify_intro.gd -- --intro-mute
```

Pour les déplacements et le dash, avec événements clavier, souris et manette simulés dans les scènes réelles :

```sh
godot --headless --path godot --script res://tools/verify_movement.gd
```

Le contrôle couvre l'isolation des périphériques, l'accélération et l'arrêt, le dosage analogique, la visée et les collisions. Il vérifie aussi la direction et la distance du dash, la visée figée, l’arrêt contre un obstacle, la récupération et l’absence de déclenchement différé ou répété. Sans `--headless`, il enregistre aussi un aperçu dans `output/movement/issue-18/`. La compatibilité matérielle reste à vérifier avec une manette physique.

Pour le tir, les dégâts, les contacts et la réinitialisation de l’essai :

```sh
godot --headless --path godot --script res://tools/verify_shooting.gd
```

Le contrôle simule clics et gâchettes dans les scènes réelles : appui très bref, maintien, cadence, chargeur vide, dégâts et attaquant, obstacle fin ou près du canon, première cible, portée, tir après dash, vulnérabilité pendant le dash, contacts, perte de focus, retrait de manette, clics d’interface et retour au titre. Sans `--headless`, il produit aussi `output/combat/issue-20/shooting-test.png`.

Pour le rechargement balle par balle et ses interruptions :

```sh
godot --headless --path godot --script res://tools/verify_reload.gd
```

Ce contrôle utilise les vraies scènes et des entrées simulées : chargeur partiel ou vide, cadence d’ajout, mobilité et visée, tir maintenu ou nouvel appui, tir demandé à vide, recharge poursuivie pendant le dash avec son délai conservé, nouveaux appuis ignorés pendant le dash, isolation des manettes, perte de focus, déconnexion, zéro PV et retour au titre. Sans `--headless`, il ajoute un aperçu 1080p dans `output/combat/issue-21/reload-test.png`. Les sensations et les manettes physiques restent à essayer.

Pour la carte, ses passages et son parcours de visite :

```sh
godot --headless --path godot --script res://tools/verify_arroyo_seco.gd
```

Cette commande est l’alias du contrôle V6 `verify_village.gd` décrit dans la [section de la carte](#visiter-la-carte-darroyo-seco). Les captures et rapports antérieurs restent historiques. La [zone étalon du saloon](output/arena/2026-11-25-saloon-study/README.md) possède aussi son propre contrôle pour conserver la référence retenue.

Pour vérifier la zone étalon, notamment l’alignement des collisions avec les pieds et la traversée du coin de maison auparavant bloquant :

```sh
godot --headless --path godot --script res://tools/verify_saloon_study.gd
```

Pour reconstruire et vérifier les exports du mobilier, puis produire l’aperçu comparatif en omettant `--headless` :

```sh
godot --headless --path godot --script res://tools/prepare_prop_visuals.gd
```

La commande de vérification de l'introduction sans `--headless`, avec `--resolution 640x360`, contrôle le rendu et enregistre les plans examinés dans `output/intro/2026-11-22/review-v1/`. Le test manette utilise un événement simulé ; un essai sur manette physique reste nécessaire. Pour regarder et écouter la séquence en continu, lancer le projet avec F5. Le rendu et la bande sonore sont une première proposition à valider, pas une livraison finale du jeu.

Pour capturer une vidéo propre depuis Godot, sans le bouton de passage :

```sh
godot --path godot --resolution 640x360 --write-movie /tmp/tequila-intro.avi --fixed-fps 24 --quit-after 1260 -- --intro-clean
```

La capture dure 52,5 secondes, dont environ 50 secondes d’introduction et le titre final, et utilise ici une sortie de 640 × 360. Le mode de capture est documenté par [Godot](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html).
