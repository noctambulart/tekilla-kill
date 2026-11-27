# Essai v0.2 · Perte de bouteille, deuxième réglage

27 novembre 2026. Après le [premier essai](../2026-11-27-v02-stun/README.md), le producteur trouve le résultat « pas mal » et demande une bouteille projetée un peu moins loin et un étourdissement un peu plus long. Cette itération applique :

| Réglage | Premier essai | Essai courant |
| --- | ---: | ---: |
| Distance de projection | 180 unités | **150 unités** |
| Durée d’étourdissement | 0,5 s | **0,65 s** |
| Durée de projection | 0,22 s | 0,22 s |

Déplacement, dash et ramassage restent bloqués pendant l’étourdissement ; visée, tir, recharge et vulnérabilité restent disponibles. Même règle pour Poncho et Garcia bot. Pause, fatal/fantôme et rejeu conservent leurs comportements.

## Vérification

`python3 scripts/godot_tasks.py verifier partie --output /private/tmp/tequila-stun-v2 --timeout 180` : **quatre suites réussies, 497 assertions sans rendu**, avec import dans une copie isolée.

- [Partie mécanique : 69](match/verification-headless.json).
- [Pertes et géométrie : 330](drops/verification-headless.json), dont les quatre tirs réels avec arrivée à 150 unités et les 90 chutes sur la carte.
- [Étourdissement : 47](stun/verification-headless.json), dont reprise impossible à 0,64 s puis possible à 0,65 s, commandes humaines, bot, pause, recharge, vulnérabilité et fantôme.
- [Parcours public : 51](v02/verification-headless.json), incluant un round complet.

[Résumé des contrôles](checks/summary.json), journaux dans `checks/`. Pas de nouvelle capture : seuls les deux paramètres d’équilibrage changent. Le premier lot conserve les preuves avec rendu de la mécanique. Les tests de durée utilisent maintenant le réglage de la bouteille pour leur chronologie.

## Essayer

Fermer l’ancienne fenêtre, relancer le projet puis cliquer sur **Jouer** :

```sh
godot --path /Users/noctambul/Dev/Noctambul/IA/jeux-video/tequila-kill/godot
```

Apprécier la distance après impact et le temps disponible pour que le tireur récupère, surtout près d’un mur. Ces valeurs sont un nouvel essai à valider en jouant ; suivi dans [#24](https://github.com/noctambulart/tequila-kill/issues/24) et [#26](https://github.com/noctambulart/tequila-kill/issues/26).
