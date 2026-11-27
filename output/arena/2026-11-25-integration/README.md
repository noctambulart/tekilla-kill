# Village et personnages intégrés — 25 novembre 2026

Livraison technique de [#60](https://github.com/noctambulart/tequila-kill/issues/60), à essayer dans la v0.1 suivie par [#59](https://github.com/noctambulart/tequila-kill/issues/59). Base artistique choisie : [version09, passages en fondu](../../concept-art/2026-11-25/09-village-passages-fondu.png).

## Voir le résultat réel

- [Essai solo avec Poncho et Garcia](solo-trial-in-game.png).
- [Saloon en vue rapprochée](saloon-in-game.png).
- [Vue d’ensemble dans la visite](village-overview.png).
- [Carte complète rendue par Godot, sans HUD](village-map-native.png).
- [Deux personnages et huit directions de visée dans le moteur](players/directions-in-game.png).
- [Rendu des personnages en 720p](players/movement-720p.png).
- [Dash](players/movement-dash.png), [récupération](players/dash-recovery.png), [dash prêt](players/dash-ready.png).

Ces captures proviennent des scènes livrées. La carte complète sans HUD utilise la même scène dans un SubViewport, sans personnages ; les autres images montrent les scènes jouables ou le banc de vérification des personnages.

## Ressources livrées

Carte V5 de 64 × 40 tuiles de 32 unités, soit 2048 × 1280 : quatre lieux accessibles, quatre maisons fermées, deux contournements, 66 obstacles de structure et 42 objets solides. Les quatre départs sont à 304 unités de la bouteille. `layout-v5.json` est une copie du fichier de production dans `godot/scenes/arroyo_seco/layout.json` ; cette géométrie pilote à la fois le dessin et les collisions. Les fondus indiquent des seuils réellement libres. Le concept n’est pas utilisé comme fond aplati.

Vingt textures de décor dans `godot/scenes/arroyo_seco/assets/village/` et deux personnages dans `godot/scenes/character/assets/village/`. Cellules 144 × 144, dessin dans 48 × 48 unités, largeur de silhouette environ 32 unités. Chaque personnage conserve une échelle commune et un ancrage au sol sur toutes ses poses. Repos 1 pose, marche 6 poses, dash 4 poses ; la visée et le recul restent une couche indépendante. Le tissu de Poncho est dessiné jusqu’au sol, sans étirement de sa texture au rendu. La couche d’arme existante est conservée, encore provisoire pour Garcia.

## Sources et reproduction

Les images originales de génération sont conservées intactes dans `source/`. Outil employé : `image_gen.imagegen`, intégré à Codex.

| Ressource | Source originale | Prompt exact |
| --- | --- | --- |
| Décor 20 objets | [environment-raw.png](source/environment-raw.png) | [environment.prompt.json](source/environment.prompt.json) |
| Poncho 12 poses | [poncho-raw.png](source/poncho-raw.png) | [poncho.prompt.json](source/poncho.prompt.json) |
| Garcia 12 poses | [garcia-raw.png](source/garcia-raw.png) | [garcia.prompt.json](source/garcia.prompt.json) |
| Table isolée, sans chaises attachées | [table-raw.png](source/table-raw.png) | [table.prompt.json](source/table.prompt.json) |

La préparation mécanique utilise Pillow : seuil alpha 128, limites occupées, redimensionnement au plus proche voisin, palette commune 64 couleurs pour chaque personnage. Les manifestes `provenance.json` des dossiers de production indiquent les sources, dimensions et SHA256. La table remplace sa cellule de la première planche. Les archives V4 et le visuel précédent du personnage sont conservés dans `before/` ; les autres lots graphiques restent dans leurs dossiers historiques.

Depuis la racine du dépôt :

```sh
python3 scripts/arena/build_village.py
python3 scripts/arena/prepare_village_art.py # nécessite Pillow
godot --headless --path godot --import
godot --path godot --script res://tools/verify_village.gd
godot --path godot --script res://tools/verify_player_visuals.gd
```

La reconstruction a été exécutée une seconde fois : les 38 fichiers de carte, textures et manifestes reproduits ont les mêmes SHA256. Les ressources livrées dans `godot/` suffisent pour jouer ; Python et les sources originales ne sont pas nécessaires au lancement.

## Vérifications effectuées

Godot 4.7.2 standard, Compatibility, macOS Apple M1 Pro.

| Contrôle | Résultat |
| --- | --- |
| Import du projet | Sans erreur |
| Carte en rendu natif, entrées et physique réelles | 49 contrôles, 0 échec ; [rapport](verification-village.json) |
| Personnages, repos/marche/dash, visée et captures 1080p/720p | 39 contrôles, 0 échec ; [rapport](players/verification.json) |
| Déplacements, collisions et dash | 53 contrôles, 0 échec |
| Tir | 47 contrôles, 0 échec ; [rapport](../../combat/issue-20/verification.json) |
| Recharge | 51 contrôles, 0 échec ; [rapport](../../combat/issue-21/verification.json) |
| Partie existante | 48 contrôles, 0 échec ; [rapport](../../gameplay/bottle-loop/verification.json) |
| `git diff --check` | Sans erreur |

Le premier contrôle de partie avait révélé des départs à distance inégale ; les quatre emplacements ont été corrigés, puis carte et partie ont été revérifiées avec succès. Les seuils sont échantillonnés sur trois trajectoires avec le rayon physique 8, les boucles sont parcourues avec les objets intacts, et des entrées clavier vérifient les passages et arrêts contre les murs.

## Essayer et limites

F5, passer l’introduction, puis **Jouer à la v0.1 · Essai solo**. Poncho est contrôlé et Garcia reste une cible immobile ; **F** affiche l’ensemble, **P** le plan, **F2** réinitialise cet essai. **Visiter Arroyo Seco** permet aussi l’exploration sans combat ; sa remise au départ utilise **R**.

La casse des caisses, chaises et pots est préparée visuellement, avec quelques débris décoratifs non bloquants. Les impacts ne détruisent pas encore ces objets : ce raccordement reste dans #29/#43. Les quatre départs du plan n’ajoutent pas de mode à quatre. La lisibilité pendant un combat collectif, l’équilibrage, les sensations et la manette physique demandent un essai du producteur. Aucune validation créative finale ou clôture du jalon n’est déduite des contrôles techniques.
