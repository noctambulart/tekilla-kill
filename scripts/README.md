# Outils de reproduction

Ces outils préparent les ressources et les aperçus. Le jeu utilise les fichiers livrés dans `godot/` ; Python et les archives originales ne sont pas nécessaires pour jouer. Les commandes ci-dessous se lancent depuis la racine du dépôt.

## Vérifications et captures

Lancer ces commandes depuis le terminal avec Python 3.9 ou plus récent. Les vérifications du jeu et les captures utilisent aussi la version de Godot indiquée dans le [README du jeu](../README.md#ouvrir-et-lancer-le-projet). Ces commandes fonctionnent localement, sans service d’IA.

```sh
python3 scripts/godot_tasks.py verifier
python3 scripts/godot_tasks.py verifier carte combat
python3 scripts/godot_tasks.py capturer intro saloon
python3 scripts/check_markdown_links.py
```

Godot importe le projet dans une copie jetable, puis lance les contrôles sélectionnés. Les sujets disponibles sont `intro`, `deplacements`, `combat`, `carte`, `saloon`, `sprites` et `partie`. Sans sujet, la commande les lance tous. `capturer` ouvre des fenêtres Godot pour produire les images. Il faut une session graphique et les fenêtres doivent pouvoir rendre leurs images jusqu’à la fin.

Le sujet `partie` couvre la boucle mécanique (`verify_match`), les pertes/récupérations sur la carte réelle (`verify_bottle_drops`), l’étourdissement du porteur (`verify_holder_stun`) le parcours public Poncho contre Garcia bot (`verify_v02`) et les ajouts v0.3 (`verify_v03`) : casse, franchissement des petits objets, crosse et récupération en quatre segments. `verify_v03_review` couvre les corrections de taille des débris et la crosse devant les obstacles qui interceptent le tir. Les contrôles marqués à pas fixe utilisent 60 images/s simulées, avec ou sans rendu ; les événements clavier/manette restent simulés.

Chaque lancement Godot imprime son dossier de résultats sous `tmp/godot-runs/`. `logs/` contient les journaux et `output/` les images et rapports produits par les scènes. Les ressources du jeu et les captures précédentes restent disponibles à leurs emplacements d’origine. Utiliser `--output` pour choisir un autre dossier parent, ou `--godot` pour indiquer l’exécutable. Un échec donne un code de sortie non nul et indique le journal concerné.

Le contrôle Markdown examine les chemins locaux dans les liens et les images intégrés au texte, ainsi que les ancres de titres `#` dans les fichiers Markdown. Il affiche le fichier et la ligne de chaque erreur. Les URL externes restent hors du contrôle.

## Installer les dépendances

Créer un environnement local, ignoré par Git :

```sh
python3 -m venv tmp/tools-venv
tmp/tools-venv/bin/python -m pip install -r scripts/requirements-art.txt
```

Utiliser ensuite `tmp/tools-venv/bin/python` à la place de `python3` dans les commandes de préparation graphique du README. Les dépendances directes de l’export graphique et de l’inventaire sont fixées aux versions vérifiées ; leurs dépendances transitives ne constituent pas un environnement verrouillé complet.

## Inventaire des archives

[`archives/graphics_inventory.py`](archives/graphics_inventory.py) lit les images, PSD, Pyxel, polices et données des trois builds Unity présents dans `archives-originales/`. Il produit une galerie HTML, des planches et un inventaire avec provenances et SHA-256. Les originaux restent des entrées de lecture ; aucun exécutable historique n’est lancé.

```sh
tmp/tools-venv/bin/python -m pip install -r scripts/archives/requirements.txt
tmp/tools-venv/bin/python scripts/archives/graphics_inventory.py
```

Sortie par défaut : `output/anciens-graphismes/`, ignorée par Git. Pour comparer une reconstruction sans remplacer la galerie existante :

```sh
tmp/tools-venv/bin/python scripts/archives/graphics_inventory.py --output /tmp/tequila-graphics-review
```

La galerie nécessite les archives locales, qui ne sont pas distribuées avec Git. Les erreurs d’extraction sont listées dans `inventaire.json` ; une galerie produite ne signifie pas que toutes les entrées ont pu être lues. Le fichier `sharedassets1.assets.resS` manquant du troisième build est une limite connue de l’inventaire historique. Les polices système peuvent modifier la mise en page des aperçus ; les empreintes des sources restent vérifiables.

## Choisir le script à utiliser

| Outil | Usage et raison de conservation |
| --- | --- |
| `arena/build_village.py` | Reconstruit le `layout.json` courant de la V6, en reprenant le saloon validé à échelle identique et les autres lieux en unités du monde. Le générateur V5 est conservé dans `output/arena/2026-11-25-village-v6/before/`. |
| `arena/prepare_village_v6.py` | Extrait à échelle uniforme les huit compléments de mobilier/maisons et les deux matériaux de la V6, depuis ses planches et prompts datés. |
| `arena/prepare_village_art.py` | Reconstruit les exports du village et des personnages V5 depuis les sources du [lot d’intégration](../output/arena/2026-11-25-integration/README.md). |
| `arena/prepare_saloon_study.py` | Prépare la bibliothèque validée de la [zone étalon du saloon](../output/arena/2026-11-25-saloon-study/README.md), réutilisée par la V6 pour les murs, les meubles et les matériaux. |
| `arena/prepare_warm_players.py` | Reconstruit Poncho et Garcia chauds, validés puis généralisés aux scènes du village V6. Les planches sources restent dans `output/arena/2026-11-25-saloon-study/character-warm/source/`. |
| `intro/create_audio.py` | Reconstruit la musique et l’ambiance originales de l’intro, avec la bibliothèque standard Python. |
| `archives/graphics_inventory.py` | Régénère la galerie et l’inventaire des archives ; permet de retrouver et vérifier leurs provenances. |
| `concept/build_fiche.py` | Générateur conservé de la fiche PDF de concept et de son manifeste de dix images. Il remplace ces deux sorties. Dépendances : `concept/requirements.txt` ; commande : `python3 scripts/concept/build_fiche.py`. La mise en page doit être rendue et examinée après toute modification. |
| `prepare_player_visuals.py` | Reconstruit le premier lot jouable #58, encore disponible pour comparaison dans `CharacterVisual`. |
| `refine_player_visuals.py` | Reconstruit le lot détaillé #58 antérieur au village ; conserve une variante utilisable pour comparaison. |
| `poncho/prepare_seed.py`, `poncho/build_lot.py`, `poncho/build_v3.py`, `poncho/build_v4.py` | Chaîne historique V2 → V3 → V4 : les derniers scripts importent les précédents et réutilisent leurs exports. La couche d’arme du jeu conserve aussi des ressources issues de ce lot. Ordre de reconstruction dans le [brief Poncho](../docs/art/poncho/brief.md). |
| `arena/build_layout.py` | Générateur historique V4 et copie de ses graphismes. Il écrit au même emplacement que la V5 : le lancer dans une copie dédiée à l’archive. |

Les exports graphiques nécessitent Pillow ; les deux générateurs de tracé utilisent seulement la bibliothèque standard. Les sources générées, prompts et manifestes des lots sont des entrées de reconstruction : conserver le script seul ne suffit pas. Les vérifications des scènes sont dans `godot/tools/` et leurs commandes dans le [README](../README.md#vérification-technique).

## Décider de conserver un outil

Conserver un script lorsqu’il reconstruit une ressource livrée, prépare une référence encore utilisée, vérifie une régression ou sert de dépendance à un autre outil. Consigner son entrée, sa sortie et la version concernée dans ce tableau ou dans le README du lot.

Un outil remplacé reste historique tant qu’il est nécessaire à une comparaison ou à la reproduction d’une livraison. Le déplacer sous `tmp/` le retire de Git : réserver ce dossier aux essais ponctuels dont les résultats utiles et la méthode ont déjà été conservés ailleurs. Avant de supprimer un script, vérifier ses imports, ses références documentaires et les manifestes des sorties ; l’absence d’appel depuis le jeu ne suffit pas.
