# Arroyo Seco V6 — village complet

Le 25 novembre 2026, le producteur retient le saloon et les personnages chauds : « Partons la dessus. Implémente la map entiere ». Cette livraison généralise cette référence dans la [mission #60](https://github.com/noctambulart/tequila-kill/issues/60). L’essai de la version assemblée reste suivi dans [#59](https://github.com/noctambulart/tequila-kill/issues/59).

## Jouer

F5 → passer l’introduction → **Jouer à la v0.1 · Essai solo**. Poncho explore le village et tire sur Garcia immobile. **F** bascule entre caméra adaptative et ensemble, **P** affiche les parcours et les empreintes solides, **F2** réinitialise, **Échap** revient au titre. **Visiter Arroyo Seco** ouvre la même carte sans combat ; son retour au départ utilise **R**. La partie à deux existante utilise aussi cette V6. Le menu conserve la zone du saloon comme référence locale.

## Captures Godot

- [Carte complète sans HUD](village-map-native.png).
- [Vue d’ensemble de l’essai avec les deux personnages](village-overview.png).
- [Saloon](saloon-in-game.png), [épicerie](shop-in-game.png), [remise](shed-in-game.png), [enclos](yard-in-game.png).
- [Maisons et rue arrière](houses-in-game.png).
- [Visibilité du personnage derrière un toit](roof-passage.png).

Les captures viennent du moteur. Le plan sans HUD utilise la scène de carte dans un SubViewport séparé, sans personnages ; les autres plans montrent les vrais personnages et les scènes jouables. Le banc de vérification place temporairement les personnages dans chaque quartier pour les captures de détail. La carte n’est pas un concept art utilisé comme image de fond.

## Carte et rendu

Le village mesure 1440 × 960 unités logiques, soit une grille de 45 × 30 tuiles de 32. Il contient quatre lieux accessibles, quatre maisons fermées, 59 segments de structure, 51 objets solides et 28 décors non bloquants. Les départs sont libres et équidistants du centre. Les routes décrivent six traversées ou boucles, avec le mobilier intact.

Le saloon reprend exactement les dimensions 448 × 352, le mobilier et les proportions de la zone validée, avec une translation de (16, 32). L’épicerie mesure 384 × 288, la remise 288 × 160 et l’enclos 264 × 176. Les maisons et les autres meubles sont recalés sur les personnages ; aucune image n’est étirée pour remplir un rectangle. Les étagères verticales montrent des objets dessinés debout dans cette orientation.

La bibliothèque validée fournit les murs bois/adobe, fenêtres de façade, tables, chaises, comptoir du saloon, tonneaux, pots et maison de référence. Huit compléments ajoutent le comptoir de magasin, les produits, les rayonnages, les outils, l’abreuvoir, une variante de maison et les buissons. Deux matériaux complètent le sable et le sol bleu-gris avec le bois de la remise et la terre de l’enclos. Les transitions de matière et la lumière des ouvertures utilisent le shader partagé de la référence.

Poncho et Garcia utilisent les [palettes chaudes retenues](../2026-11-25-saloon-study/character-warm/README.md). Leur taille, leur ancrage et les actions restent ceux de la référence. Leurs collisions de déplacement sont placées aux pieds ; les maisons ont une emprise de façade/marches distincte du toit et des coins transparents. Les bâtiments s’atténuent lorsqu’ils masquent un personnage derrière leur toit. Les impacts des tirs utilisent une silhouette séparée du déplacement ; les projectiles ignorent les zones attachées à leur tireur. Le mode fantôme désactive aussi cette silhouette, puis la rétablit au retour.

## Données et reconstruction

`godot/scenes/arroyo_seco/layout.json` est la donnée courante. Les coordonnées sont en unités du monde ; `tile_px` décrit la grille de composition. Les positions de départ gardent le pivot existant des personnages ; les parcours et les empreintes sont décrits au sol, avec un décalage des pieds de (0, 16). Les murs utilisent les dimensions des pièces et les ouvertures. Les objets calculent leur base depuis leur format d’affichage, avec une empreinte particulière pour les maisons, le comptoir en L et le rayonnage vertical.

Le rendu complet réutilise les composants de `saloon_study/` au lieu d’en produire une deuxième version divergente. Les ajouts sont dans `godot/scenes/arroyo_seco/assets/village_v6/`, avec `provenance.json`. Les autres ressources livrées dans `godot/` suffisent pour lancer le jeu.

```sh
python3 scripts/arena/build_village.py
python3 scripts/arena/prepare_village_v6.py # Python + Pillow pour l’export
godot --headless --path godot --import
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_village.gd
godot --path godot --fixed-fps 60 --script res://tools/verify_village.gd
python3 scripts/godot_tasks.py verifier
```

Les bibliothèques du saloon et des personnages sont reproductibles par `prepare_saloon_study.py` et `prepare_warm_players.py`. Certains objets repris du lot V5 sont reproductibles par `prepare_village_art.py`. Voir [l’inventaire des outils](../../../scripts/README.md). Le builder V6 et les nouveaux exports ont été relancés : les 12 fichiers de carte, textures et manifeste sont identiques en SHA256. [Relevé de reproduction](reproduction.json).

## Sources graphiques

Outil : **`image_gen.imagegen`, intégré à Codex**. Les images originales et les prompts exacts sont conservés :

| Ajout | Source intacte | Prompt |
| --- | --- | --- |
| Mobilier et maisons complémentaires | [props-raw.png](source/props-raw.png) | [props.prompt.json](source/props.prompt.json) |
| Sol bois et terre de l’enclos | [floors-raw.png](source/floors-raw.png) | [floors.prompt.json](source/floors.prompt.json) |

La préparation extrait les composantes des objets sans les couper à la limite des cellules, conserve un facteur d’échelle uniforme et un alpha binaire, puis rééchantillonne au plus proche voisin. Les pixels de bord des panneaux de matériau sont exclus et l’échantillonnage miroir évite les raccords visibles. Les planches originales ne sont pas repeintes. Le manifeste associe chaque objet à sa source, son rectangle, ses dimensions et son échelle.

La V5, son générateur et son vérificateur restent dans `before/`. Pour reconstruire cette archive, remettre son générateur à son chemin original `scripts/arena/build_village.py` dans une copie dédiée ; il ne décrit pas la V6. Les livraisons graphiques précédentes et la zone étalon restent dans leurs dossiers datés.

## Vérifications

Godot 4.7.2 standard, Compatibility, Apple M1 Pro.

- **118 contrôles natifs, aucun échec**, avec captures : [rapport V6](verification-village.json).
- Tous les seuils sont échantillonnés sur trois trajectoires avec le rayon physique 8. Les six parcours sont traversés avec les objets intacts. Les marges et les coins transparents des quatre maisons sont contrôlés. Les vrais inputs vérifient passage de façade, arrêt au mur, tir, recharge et dash.
- **4066 cellules libres sur une grille de 16 unités rejoignent la place centrale** ; aucune poche isolée n’a été trouvée dans la zone jouable. Cette grille complète les tests continus des portes et routes ; elle n’est pas une preuve de tous les points possibles du terrain.
- La suite complète `python3 scripts/godot_tasks.py verifier` passe dans une copie isolée : introduction, déplacements 53, tir 47, recharge 51, village 110, saloon 56, sprites 31 pour chaque lot et partie 48 contrôles. Les captures ajoutent leurs contrôles d’export aux comptes natifs. [Résumé](checks/summary.json) et [journaux](checks/logs/).
- Import sans erreur et `git diff --check` réussi. Le contrôle natif couvre la visite, l’essai solo et l’ouverture de la partie existante ; son contrôle dédié confirme aussi la bouteille, le mode fantôme, la pause, la fin et le rejeu.

Les vérifications ont d’abord signalé une boucle croisant un coin de périmètre, une étagère gênant l’approche d’une ouverture et les tirs interceptés par la propre silhouette du tireur. La géométrie et l’exclusion des projectiles ont été corrigées, puis les contrôles relancés avec succès. Les captures de l’ensemble, des quartiers et du passage derrière le toit ont été examinées.

La direction du lot de référence est validée ; l’équilibrage, les sensations et la validation du village complet demandent encore l’essai du producteur. Aucun nouveau mode à quatre ni système de destruction n’est ajouté. Les caisses, chaises et pots restent préparés visuellement pour la casse, à raccorder dans #29/#43. La compatibilité d’une manette physique n’est pas déduite des entrées simulées. Aucun commit/push de cette livraison n’a été effectué.
