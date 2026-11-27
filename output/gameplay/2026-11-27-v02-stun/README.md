# Essai v0.2 · Perte de bouteille et étourdissement

27 novembre 2026. Retour du producteur après la review : « Tout est bien », avec une reprise trop facile de la bouteille par le porteur blessé. Après discussion de plusieurs options, le producteur approuve ce premier réglage à implémenter et essayer. Suivi : [pertes/récupérations #24](https://github.com/noctambulart/tequila-kill/issues/24) et [review globale #26](https://github.com/noctambulart/tequila-kill/issues/26). Les sensations corrigées restent à valider en jouant.

## Réglage livré

- Un porteur blessé perd immédiatement la bouteille et reste étourdi **0,5 s** : déplacement, dash et ramassage bloqués, visée/tir/rechargement disponibles et vulnérabilité conservée.
- Un dash engagé s’arrête au choc. Une recharge engagée conserve sa progression et continue ; une nouvelle recharge peut commencer pendant l’étourdissement. Un appui de dash pendant celui-ci ne reste pas en attente.
- Projection doublée de **90 à 180 unités**, en **0,22 s**, vers la position du tireur à l’impact. Le décor arrête la bouteille ; un autre actif peut l’intercepter en vol.
- L’exclusion personnelle existante de **0,45 s** est comprise dans les **0,5 s**. La reprise redevient possible dès la fin de l’étourdissement si la bouteille est accessible. Aucune interdiction supplémentaire d’une seconde.
- Même règle pour Poncho, Garcia et les bots. Un dégât sans possession ne déclenche ni ne prolonge l’étourdissement. Un dégât nul ne fait rien ; un coup fatal donne priorité au fantôme, y compris pendant un étourdissement.
- La pause gèle le temps restant. Rejouer et la remise à zéro du combat effacent l’état.

Les réglages de perte sont exposés sur le script de bouteille : `throw_distance`, `throw_duration`, `former_holder_delay`, `holder_stun_duration`. L’état de personnage reste distinct de son activité au combat, pour conserver les dégâts et le ciblage du bot pendant l’étourdissement.

## Essayer

Fermer l’ancienne fenêtre du jeu et relancer depuis Terminal :

```sh
godot --path /Users/noctambul/Dev/Noctambul/IA/jeux-video/tequila-kill/godot
```

Passer l’introduction puis **Jouer**. Vérifier les sensations suivantes :

1. Ramasser avec Poncho, continuer à bouger et se faire toucher : arrêt bref, bouteille projetée plus loin, déplacement de nouveau disponible après une demi-seconde.
2. Pendant cet arrêt, viser/tirer ou recharger : le combat reste utilisable. Essayer aussi une recharge commencée avant le choc et un dash interrompu par le choc.
3. Tirer sur Garcia porteur : il subit la même immobilisation, ce qui doit donner une véritable occasion de récupération. Essayer près d’un mur et apprécier si le transfert reste assez disputé.

## Vérification technique

Godot 4.7.2 standard, Compatibility. Sept suites réussies sans rendu, **650 assertions** au total. Vérification native de l’étourdissement : **49 assertions**, dont deux captures. Commandes humaines simulées, même scène et physique que le jeu ; le test du bot utilise la composition publique.

| Suite | Assertions sans rendu | Preuve |
| --- | ---: | --- |
| Partie mécanique | 69 | [Rapport](match/verification-headless.json) |
| Pertes, tirs et géométrie | 330 | [Rapport](drops/verification-headless.json) |
| Étourdissement | 47 | [Rapport](stun/verification-headless.json) |
| Parcours public humain/bot | 51 | [Rapport](v02/verification-headless.json) |
| Tir | 47 | [Résumé](checks/regressions.json) |
| Recharge | 53 | [Résumé](checks/regressions.json) |
| Déplacements et dash | 53 | [Résumé](checks/regressions.json) |

[Rapport avec rendu](stun/verification-rendered.json). Les deux captures [Poncho](stun/j1-stunned.png) et [Garcia](stun/j2-stunned.png) montrent la fixture à deux humains avec son HUD de développement : projection neutralisée pour placer la bouteille aux pieds, état figé à 0,49 s ; elles ne représentent pas le HUD public de v0.2. L’immobilisation se vérifie dans les assertions de position et de temps, pas sur une image fixe. Les captures sont séparées des tests de commandes chronométrés. L’automatisation native reprend le focus et ignore les pauses dues à une autre fenêtre ; la pause explicite est testée ici, la perte de focus dans `verify_match`.

Couverture : 0,49 s sans reprise puis 0,50 s avec reprise, même bouteille aux pieds ; combat disponible ; recharge avant/après choc ; interruption du dash et absence de dash différé ; vulnérabilité ; second dégât sans prolongation ; fatal avant/après la fin de l’étourdissement ; fantôme mobile ; pause ; bot avec intention de déplacement ; remise à zéro et rejeu. Les quatre tirs réels de `verify_bottle_drops` contrôlent l’arrivée à 180 unités, dont deux fatals. Les 90 chutes sur la carte vérifient accessibilité, arrêt et récupération ; les cinq ouvertures vérifient une traversée d’au moins 90 unités, une projection de 180 pouvant rencontrer un obstacle plus loin.

Le round autonome de `verify_v02`, sans réduction de réserve ni téléportation, finit toujours en 2 481 images avec 2 400 unités bues par Garcia. Poncho reste immobile dans ce cas ; ce n’est pas une mesure de difficulté face à un humain actif.

Reproduire les suites dans une copie isolée :

```sh
python3 scripts/godot_tasks.py verifier partie combat deplacements --output /private/tmp/tequila-stun-checks --timeout 180
```

Contrôle ciblé avec rendu (retirer `--audio-driver Dummy` pour écouter) :

```sh
godot --path godot --audio-driver Dummy --fixed-fps 60 --log-file /private/tmp/tequila-stun.log --script res://tools/verify_holder_stun.gd
```

Les journaux sont conservés dans `checks/`. Le message macOS `get_system_ca_certificates` des exécutions sans rendu est celui déjà connu de l’environnement ; aucune autre erreur ne subsiste. Les anciens lots restent inchangés et décrivent leurs réglages historiques. Cette livraison locale ne clôture ni #24 ni le jalon ; aucun commit, push ou export autonome.
