# #24 — Perte et récupération de la bouteille après un tir

Livraison technique locale du 27 novembre 2026, après validation de #23. Suivi : [Issue #24](https://github.com/noctambulart/tequila-kill/issues/24). L’essai et la validation du producteur pour cette mission restent attendus.

## Lancer et essayer sur Mac

Dans Terminal, depuis la racine du dépôt :

```sh
godot --path godot --scene res://scenes/match/match.tscn
```

Cette commande ouvre directement la scène bouteille, sans F6. Si elle affiche Pause après une perte de focus, cliquer dans le jeu puis sur **Reprendre**. Le bouton Jouer du titre conserve l’essai solo v0.1.

Poncho / J1 utilise ZQSD ou WASD, la souris, clic gauche, R et Espace. Garcia / J2 utilise la première manette connectée : sticks, RT pour tirer, LT pour dasher, X ou carré pour recharger. Sans manette, Garcia reste immobile ; le bot n’est pas encore livré.

1. Faire prendre la bouteille à Poncho puis le blesser avec Garcia. Même s’il lui reste de la vie, la bouteille doit quitter sa tête et partir vers Garcia ; Poncho conserve la quantité déjà bue.
2. Rejoindre la bouteille avec Garcia pour la récupérer. Refaire l’essai en inversant les rôles. Un actif autorisé peut l’intercepter avant la fin de la projection.
3. Refaire un tir fatal : une seule perte doit survenir, puis le fantôme ne doit pas reprendre la bouteille.
4. Essayer près des murs et aux portes : la bouteille doit s’arrêter contre les parties solides, passer par les ouvertures et rester récupérable.
5. Après une perte, l’ancien porteur ne reprend pas instantanément la bouteille. L’autre actif peut la prendre immédiatement s’il n’est pas lui-même encore soumis à un délai dû à une perte précédente.

Les contrôles automatisés ci-dessous simulent aussi les deux joueurs sans manette physique. Les graphismes et sons définitifs restent dans #66 ; ce lot ne valide pas le fantôme de #25 ni la v0.2 assemblée de #26.

## Réalisation et réglages

[bottle.gd](../../../godot/scenes/bottle/bottle.gd) réutilise la possession, les quantités et l’arbitrage de #23. Le tir conserve la courte projection vers la position du tireur au moment de l’impact. Le déplacement ultérieur du tireur ne redirige pas la bouteille. La consommation cesse dès la perte ; la reprise utilise les mêmes scores et la même réserve.

Le délai de reprise est désormais conservé par numéro de joueur. Une prise/perte rapide par l’adversaire n’efface plus le délai du premier porteur. Ces délais et la projection sont suspendus avec le monde pendant la pause et remis à zéro par `configure`.

Dans [match.gd](../../../godot/scenes/match/match.gd), `ground_offset` est affecté avant l’ajout de la bouteille à l’arbre, à partir de la collision du personnage. Le collider de la bouteille suit ainsi le même contact au sol que les pieds (0, 16 sur la carte actuelle), avec un rayon de 8 unités comme le noyau solide des personnages. Le balayage de projection ne peut donc pas faire passer la bouteille dans un espace trop étroit pour son récupérateur. Le dessin provisoire au sol suit cet ancrage ; le repère porté conserve sa hauteur.

| Réglage provisoire | Valeur |
| --- | --- |
| Distance maximale de projection | 90 unités |
| Durée de projection sans collision | 0,22 s |
| Délai de reprise après sa propre perte | 0,45 s |
| Rayon de ramassage | 15 unités |
| Contenu et débit conservés de #23 | 2 400 unités, 60 unités/s |

Ces valeurs restent réglables ; la distance, la durée et le délai déjà présents ne sont pas transformés en règles d’équilibrage définitives.

## Événements pour #66

- `picked_up(new_holder)` : une prise réussie, après arrêt de la projection et affectation du porteur.
- `dropped(previous_holder, attacker)` : une perte, après libération du porteur et initialisation de la projection. Un dégât ultérieur sans possession ne répète pas cette perte.
- `possession_changed`, `state_changed`, `get_state()` et `emptied` restent compatibles avec #23. Les notifications de possession et d’état précèdent l’événement dédié ; un abonné peut lire l’état actualisé sans calculer une seconde réserve ni un second score.

## Vérification technique

[verify_bottle_drops.gd](../../../godot/tools/verify_bottle_drops.gd) étend les outils de [verify_match.gd](../../../godot/tools/verify_match.gd) pour réutiliser la scène réelle, les commandes simulées, les reprises et la production des rapports/captures.

```sh
godot --headless --path godot --script res://tools/verify_bottle_drops.gd
godot --path godot --audio-driver Dummy --fixed-fps 60 --script res://tools/verify_bottle_drops.gd
godot --headless --path godot --script res://tools/verify_match.gd -- --evidence=res://../output/gameplay/2026-11-27-issue-24/regression
```

Le lanceur `python3 scripts/godot_tasks.py verifier partie` inclut aussi les deux suites dans une copie isolée. L’option `--evidence=` du contrôle de partie permet de conserver les preuves validées de #23 lors d’une nouvelle livraison.

| Contrôle | Résultat | Preuve |
| --- | --- | --- |
| Pertes/récupérations sans affichage | 329 contrôles réussis | [Rapport détaillé](verification-headless.json), [journal](checks/drops-headless.log) |
| Pertes/récupérations avec rendu natif 1080p | 331 contrôles réussis, dont deux captures | [Rapport détaillé](verification-rendered.json), [journal](checks/drops-rendered.log) |
| Régression de la boucle de partie | 69 contrôles réussis | [Rapport détaillé](regression/verification-headless.json), [journal](checks/match-headless.log) |

Les tirs sont de vrais projectiles lancés avec les commandes souris/manette simulées, pour les deux porteurs, en cas fatal et non fatal. Les essais vérifient le sens figé à l’impact, l’unicité et l’ordre des événements, l’arrêt de consommation, la conservation du score, la récupération et la reprise de consommation par le bon joueur. Les scénarios contrôlés ajoutent l’absence de perte sur zéro dégât, les échanges rapprochés, l’interception pendant la projection et la pause.

Le contrôle géométrique exerce **90 chutes sur la carte réelle** : 85 faces accessibles de murs, clôtures ou limites, puis cinq ouvertures (saloon est/nord, épicerie ouest, remise nord, enclos ouest). Pour isoler la collision de projection, ces cas déclenchent directement les dégâts et imposent leur direction ; ils ne prétendent pas qu’un tireur peut envoyer un projectile à travers un mur. Chaque trajet et point d’arrêt est contrôlé avec le gabarit solide du personnage, puis la bouteille est effectivement récupérée. Les cinq passages vérifient aussi la distance complète de projection sans blocage.

Captures natives examinées : [perte de Poncho](j1-bottle-dropped.png) et [perte de Garcia](j2-bottle-dropped.png). Ces captures comprennent un dégât supplémentaire de contrôle après perte, pour vérifier qu’il n’émet pas une seconde perte ; elles montrent donc 74 PV après le tir non fatal et ce point de dégât supplémentaire.

Les journaux sans affichage peuvent contenir le message macOS `get_system_ca_certificates` déjà observé avant la mission ; les contrôles se terminent avec un code zéro. Le rendu natif passe sans ce message. L’examen des captures et les commandes simulées ne remplacent pas l’essai du producteur sur les sensations ou la compatibilité d’une manette physique.
