# Personnages et décor chaleureux — 25 novembre 2026

Suite de [#60](https://github.com/noctambulart/tequila-kill/issues/60). Le producteur relève que la maison et Poncho semblent appartenir à des styles différents et demande une cohérence avec les couleurs chaleureuses du décor.

## Voir et essayer

F5 → passer l’introduction → **Essayer le saloon retravaillé**. Les nouvelles couleurs sont actives sur Poncho et Garcia dans cette zone. Les autres scènes conservent leurs lots précédents pendant cette itération.

- [Après : les deux personnages devant la maison](house-after.png).
- [Avant : même scène, cadrage, positions et tailles](house-before.png).
- [Nouvelle palette dans le saloon et sur le sable](saloon-in-game.png).
- [Vue d’ensemble](saloon-overview.png).
- [Deux personnages et huit directions de visée](players/directions-in-game.png).
- [Rendu 720p](players/movement-720p.png), [marche/dash](players/movement-dash.png), [récupération](players/dash-recovery.png).

Ces images sont des captures natives Godot, sans retouche. Pour la comparaison devant la maison, seul le lot graphique des personnages est basculé entre les deux captures ; le décor, la caméra, les positions, la visée et l’échelle restent identiques. Le banc de vérification place temporairement Garcia près de Poncho pour ce plan. Les positions de départ de l’essai restent celles de la rue.

## Direction appliquée

Les couleurs et les volumes sont repris directement dans les sprites. La maison de `godot/scenes/arroyo_seco/saloon_study/assets/house.png` sert de référence : reflets miel et crème, ombres brun chocolat, lumière venant du haut gauche et lumière réfléchie par le sable.

- **Poncho** : paille plus lumineuse, tissu ocre cuivré, franges dorées et plis plus lisibles. Couronne olive et silhouette conservées.
- **Garcia** : chapeau chocolat avec lumière cuivrée, étoile et bande crème, foulard rouge/terre cuite et épaules indigo. Il conserve une silhouette et des accents distincts de Poncho.

Les corps gardent leurs proportions, cellules 144 × 144, affichage 48 × 48 unités, pivot de visée (72, 78) dans la source et ancrage au sol (72, 126). L’arme/recul existants restent une couche indépendante. La normalisation conserve une échelle unique sur toutes les poses d’un personnage et une palette commune de 128 couleurs, avec transparence binaire et rééchantillonnage au plus proche voisin. Repos 1 pose, marche 6, dash 4 ; les premières/dernières poses de raccord reprennent le repos selon le contrat existant.

## Sources et reproduction

Outil utilisé : **`image_gen.imagegen`, intégré à Codex**. Deux éditions des planches complètes 6 × 2, référencées sur la maison. Les images originales restent intactes :

| Personnage | Source originale | Prompt exact |
| --- | --- | --- |
| Poncho | [source/poncho-raw.png](source/poncho-raw.png) | [poncho.prompt.json](poncho.prompt.json) |
| Garcia | [source/garcia-raw.png](source/garcia-raw.png) | [garcia.prompt.json](garcia.prompt.json) |

Ressources de production autonomes : `godot/scenes/character/assets/saloon_warm/`, avec `provenance.json`, références et SHA256. Le composant visuel propose `warm_art` pour sélectionner ce lot ; la zone étalon l’active pour ses deux personnages. Les sources de génération ne sont pas nécessaires au lancement du jeu.

```sh
python3 scripts/arena/prepare_warm_players.py # Python + Pillow
godot --headless --path godot --import
godot --path godot --fixed-fps 60 --script res://tools/verify_saloon_study.gd
godot --path godot --fixed-fps 60 --script res://tools/verify_player_visuals.gd -- --warm
```

## Vérification

Godot 4.7.2 standard, Compatibility, Apple M1 Pro.

- **64 contrôles natifs, aucun échec** sur la zone étalon : nouveaux lots réellement chargés, pieds/collisions, ouvertures, maison, mouvement, tir, recharge, dash, menus et captures comparatives. [Rapport](verification.json).
- **39 contrôles natifs, aucun échec** sur les personnages : repos, marche et dash réels des deux personnages, progression des poses, visée indépendante, vues 1080p/720p et huit directions. Les entrées manette sont simulées ; le matériel physique n’est pas validé. [Rapport](players/verification.json).
- Les 16 exports et manifeste sont reproduits à l’identique : [SHA256 et relevé](reproduction.json).
- Import et `git diff --check` sans erreur.

Les captures ont été examinées devant la maison, sur le sable et sur le sol bleu-gris. Les contrôles techniques préservent le contrat d’animation et de collision ; la cohérence artistique reste soumise au regard du producteur. Cette livraison ne vaut pas généralisation des changements à toute l’arène ni clôture du jalon.
