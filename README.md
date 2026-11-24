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

## État du projet

Le projet utilise **Godot 4.7.2 standard**, **GDScript** et le moteur de rendu **Compatibility**, pour une base 2D. Une première cinématique autonome d'environ 50 secondes précède l'écran titre provisoire : duel de regards, mouche et reflet de la bouteille, avec une première proposition sonore originale. Son rythme et son rendu sont à examiner avec le producteur. Une zone de test permet maintenant de déplacer, viser, dasher et tirer au revolver avec Poncho et Garcia, au clavier-souris et à la manette. La suite du combat, la bouteille et les bots restent à implémenter ; les plateformes, périphériques et contrôles retenus sont référencés dans le [concept et les décisions du projet](docs/concept.md). La première version prévoit du jeu local sur écran commun avec des bots ; le réseau viendra ultérieurement.

## Ouvrir et lancer le projet

1. Utiliser Godot **4.7.2 standard** (la version .NET n'est pas nécessaire).
2. Dans le gestionnaire de projets Godot, choisir **Importer** et sélectionner [`godot/project.godot`](godot/project.godot).
3. Ouvrir le projet, puis appuyer sur **F5** pour lancer le projet (ou **F6** pour lancer uniquement la scène ouverte).

Depuis la racine du dépôt, si `godot` est disponible dans le terminal :

```sh
godot --path godot --editor
godot --path godot
```

L'introduction démarre automatiquement. **Espace**, **Entrée**, **Échap**, le bouton affiché ou **A / B / Start** sur une manette permettent de la passer. La lecture complète et le passage conduisent à l'écran titre. **Tester le tir et les déplacements** ouvre la zone de test ; **Visiter Arroyo Seco** ouvre la première carte ; **Revoir l’introduction** relance la cinématique ; **Quitter** ferme le jeu. Les boutons de menu utilisent les actions d'interface par défaut de Godot.

La scène `godot/scenes/intro/intro.tscn` peut aussi être ouverte et jouée avec **F6**, indépendamment du gameplay. Elle rejoint le titre en fin de lecture. Suivi de cette première version : [Issue #16](https://github.com/noctambulart/tequila-kill/issues/16), dans [l'epic de l'introduction](https://github.com/noctambulart/tequila-kill/issues/15).

## Essayer le tir, le rechargement et les déplacements — missions #18 à #21

Depuis le titre, choisir **Tester le tir et les déplacements**, ou lancer directement :

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

Le dash annule le rechargement en conservant les balles terminées. Pendant le dash, tir et recharge sont ignorés, sans mise en attente. Il faut **réappuyer après sa fin** pour recharger ; pour tirer, il faut relâcher puis réappuyer, même si le tir était maintenu avant. Une recharge interrompue ne reprend jamais seule.

Les contacts entre personnages repoussent légèrement sans dégâts. Le bouton **Réinitialiser l’essai** rétablit vie, chargeurs et positions et retire les projectiles. Il permet de continuer à essayer après zéro PV ; le mode fantôme (#25) reste à réaliser. Suivi du tir : [Issue #20](https://github.com/noctambulart/tequila-kill/issues/20).

Cette zone utilise les sprites de Poncho et Garcia décrits ci-dessous, avec des gestes d’arme encore provisoires pour Garcia. Les commandes sont relâchées en cas de perte de focus ou de retrait de la manette. La pause complète et la configuration J1–J4/profils restent dans leurs missions respectives. Les sensations et la compatibilité des manettes physiques restent à examiner en jouant. Suivi des déplacements : [Issue #18](https://github.com/noctambulart/tequila-kill/issues/18).

## Sprites jouables de Poncho et Garcia — mission #58

Les personnages des scènes jouables reprennent maintenant la recherche de silhouettes des concept arts : **Poncho pour J1 et la visite**, avec sombrero paille, couronne olive et poncho brun frangé ; **Garcia pour J2**, avec chapeau sombre, épaules bleu-violet et foulard rouge. La couleur du repère et le numéro restent liés au joueur. Après examen du rendu le 24 novembre, les dessins ont été repris avec des détails plus fins : cellules source de **144 × 144 pixels**, dessinées dans les mêmes **48 × 48 unités logiques**, soit des corps d’environ 32 unités de large. En 1080p à zoom natif, un pixel de texture correspond à un pixel affiché. Les PNG courants sont dans `godot/scenes/character/assets/refined/`, indépendamment des archives et du dossier `output/` ; les premières ressources restent conservées dans les dossiers voisins.

Le corps conserve la projection du concept pendant la visée ; seule la couche d’arme tourne, avec la main masquée par le chapeau. Les vrais états de déplacement pilotent repos, marche et dash. Les nouvelles séquences détaillées reprennent le contrat d’animation précédent et la piste de main validée sur Poncho V4. La couche d’arme est encore commune et provisoire : le fusil et les gestes spécifiques de Garcia restent dans #39/#40. Les vitesses, collisions et règles des actions restent séparées de cette présentation.

Les sources et prompts ImageGen, ainsi que les captures réelles en 1080p et 720p, sont conservés dans `output/sprites/players/issue-58/v2/`. `scripts/refine_player_visuals.py` reproduit les exports courants (Python + Pillow) ; `scripts/prepare_player_visuals.py` reproduit la première version. Le composant propose `refined_art` pour comparer les deux lots. Pour vérifier les transitions réelles et la visite, et enregistrer les captures en omettant `--headless` (ajouter `-- --legacy` pour la comparaison avec les anciens dessins) :

```sh
godot --headless --path godot --script res://tools/verify_player_visuals.gd
```

Suivi de cette intégration visuelle dans les scènes existantes : [Issue #58](https://github.com/noctambulart/tequila-kill/issues/58). L’intégration complète des actions en partie et la validation créative en jouant restent dans [#40](https://github.com/noctambulart/tequila-kill/issues/40).

## Visiter la carte d’Arroyo Seco

Depuis le titre, choisir **Visiter Arroyo Seco**, ou lancer directement :

```sh
godot --path godot --scene res://scenes/arroyo_seco/arena_review.tscn
```

Le village irrégulier occupe une grille de **48 × 30 tuiles**, soit **1536 × 960 px** : saloon à trois accès, cour arrière et contournement, épicerie décalée, remise et enclos. La V4 agrandit les espaces de 50 % sur chaque axe par rapport à la première carte (surface ×2,25), en conservant les tuiles de 32 px et la taille du personnage. Les départs sont à 240 px de la bouteille. Le traitement suit la scène habitée des concept arts : vue verticale, sable calme, dallage bleu-gris et canapé bordeaux.

Huit sprites de décor ont été refaits dans une planche originale avec transparence : caisse, tonneau, table de poker, canapé, chaise, pot, charrette et comptoir. Leurs régions occupées sont lues dans la planche pour que les marges transparentes ne réduisent pas les objets à l’écran. Les anciennes textures et les captures V3 sont conservées pour comparaison. Sources et prompt : `godot/scenes/arroyo_seco/assets/provenance.json` et `output/arena/2026-11-23/atlas-v4-prompt.txt`.

Le lot de mobilier #42 fournit aussi les **états cassés et les débris des caisses, chaises et pots**. Les 14 variantes visuelles (huit intacts et six états de destruction) sont exportées en textures `.tres` et scènes `.tscn` dans `godot/scenes/arroyo_seco/assets/prop_visuals/`. Le manifeste `assets/prop-visuals.json` précise dimensions, ancrages et rôle de chaque état. Les scènes sont uniquement visuelles : la suppression de la collision et les dégâts restent à raccorder dans #29/#43. L’aperçu comparatif et les prompts sont conservés dans `output/arena/2026-11-24/issue-42/`.

- **ZQSD / WASD** pour avancer, **souris** pour viser et **Espace** pour dasher avec Poncho.
- La visite démarre **en vue rapprochée**, à l’échelle native du personnage ; **F** ou le bouton affiche la vue d’ensemble puis permet de revenir au suivi.
- **P** ou le bouton : afficher le plan, les quatre départs et les parcours de poursuite/interception.
- **R** : revenir au départ ; **Échap** ou **Titre** : quitter la visite.

Les murs et meubles sont solides ; les seuils sont ouverts. La bouteille est un repère visuel, sans ramassage ou consommation. La casse des caisses/chaises/pots, le combat, les bots et la caméra adaptative de partie restent dans leurs missions. Cette visite au clavier-souris sert à examiner le lieu ; elle n’est pas une partie multijoueur.

La géométrie, les empreintes des objets, les départs et les parcours sont éditables dans [`layout.json`](godot/scenes/arroyo_seco/layout.json). La même source pilote les visuels et les collisions. [`build_layout.py`](scripts/arena/build_layout.py) reproduit ce fichier et copie les sources graphiques depuis les archives locales ; les copies et leur provenance sont déjà livrées dans la scène, donc les archives ne sont pas nécessaires pour ouvrir la carte.

Les aperçus et le relevé de vérification sont conservés dans `output/arena/2026-11-23/`. Suivi : [plan #27](https://github.com/noctambulart/tequila-kill/issues/27) et [construction #28](https://github.com/noctambulart/tequila-kill/issues/28). Le producteur retient la V4 et ses sprites de décor comme base pour la suite ; les améliorations graphiques supplémentaires sont reportées. Les circulations et collisions sont vérifiées techniquement ; les sensations et l’équilibrage restent à éprouver avec le combat.

## Structure technique

- `godot/` : racine du projet importé par le moteur. Les archives, références et documents restent à l'extérieur pour éviter leur import automatique.
- `godot/scenes/main/` : scène principale et script associé. Les prochaines fonctionnalités pourront regrouper leurs scènes, scripts et ressources de la même manière.
- `godot/scenes/character/` : personnage mobile, commandes humaines, revolver et projectile séparés. Chaque personnage possède ses propres actions d'entrée ; la manette est liée à un identifiant de périphérique précis. Le revolver gère le chargeur, le rechargement progressif et la cadence ; le projectile balaie chaque segment parcouru, y compris entre le personnage et le bout du canon, pour respecter les couverts fins et proches.
- `godot/scenes/movement_test/` : zone fermée et obstacles provisoires pour le premier essai à deux, sans remplacer la future arène d'Arroyo Seco.
- `godot/scenes/arroyo_seco/` : carte, géométrie partagée, sources graphiques avec provenance et scène de visite ; indépendante de l’interface de visite pour sa future intégration en partie.
- `godot/scenes/intro/` : cinématique autonome, découpage et mouvements de caméra dans `intro.gd`, illustrations et pistes sonores dans `assets/`.
- `scripts/intro/create_audio.py` : composition et synthèse originales de la première bande sonore, reproductibles avec Python 3 sans dépendance externe. Musique et ambiance sont livrées séparément.
- `godot/tools/verify_intro.gd` : vérification de lecture, fin, passage, relecture et captures des moments clés.
- `godot/tools/verify_movement.gd` : vérification intégrée des déplacements, commandes séparées, visée, collisions et retours au titre.
- `godot/.godot/` : cache local généré automatiquement, ignoré par Git. Les fichiers `.uid` et `.import` associés aux ressources sources doivent être conservés.

Le jeu cible le **1920 × 1080** en 16:9, taille demandée à l’ouverture de la fenêtre. Godot rend la 2D directement à la taille d’affichage avec `canvas_items`, sur une grille logique de 640 × 360 avec des tuiles de 32 × 32. En 1080p, les pixels des sprites passent en ×3 au plus proche voisin, et le texte est dessiné à la résolution de sortie. La fenêtre reste redimensionnable avec une mise à l’échelle entière. Voir la [base graphique retenue](docs/references-graphiques.md#base-pixel-art-retenue).

Mission d'initialisation : [Issue #11](https://github.com/noctambulart/tequila-kill/issues/11).

## Vérification technique

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

Ce contrôle utilise les vraies scènes et des entrées simulées : chargeur partiel ou vide, cadence d’ajout, mobilité et visée, tir maintenu ou nouvel appui, tir demandé à vide, interruption par dash, commandes ignorées pendant le dash, isolation des manettes, perte de focus, déconnexion, zéro PV et retour au titre. Sans `--headless`, il ajoute un aperçu 1080p dans `output/combat/issue-21/reload-test.png`. Les sensations et les manettes physiques restent à essayer.

Pour la carte, ses passages et son parcours de visite :

```sh
godot --headless --path godot --script res://tools/verify_arroyo_seco.gd
```

Le contrôle charge les scènes réelles : entrées du saloon, passage de cour, accès aux quatre départs, trois parcours avec rayon réel du personnage, murs/comptoir, lignes physiques à travers murs et ouvertures, commandes de visite et retour au titre. Sans `--headless`, il exporte aussi la carte complète, le plan annoté et deux captures de visite. Cela ne valide pas le combat ou la caméra de partie.

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
