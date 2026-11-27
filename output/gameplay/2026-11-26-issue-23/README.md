# #23 — Ramasser et boire la bouteille

Mission commencée le 26 novembre 2026, livraison technique le 27 novembre 2026. Suivi : [Issue #23](https://github.com/noctambulart/tequila-kill/issues/23). Cette livraison locale complète la mécanique existante. Le producteur valide le 27 novembre 2026 : « C’est bon implémente la suite ». [Accord et clôture](https://github.com/noctambulart/tequila-kill/issues/23#issuecomment-7213896944). Les preuves ci-dessous décrivent cette livraison ; la suite sur les pertes/récupérations est suivie dans #24.

## Essayer

Depuis la racine du dépôt, avec Godot 4.7.2 standard :

```sh
godot --path godot --scene res://scenes/match/match.tscn
```

On peut aussi ouvrir [match.tscn](../../../godot/scenes/match/match.tscn) dans Godot et appuyer sur **F6**. Le titre conserve l’essai solo v0.1 derrière **Jouer**.

- Poncho / J1 : ZQSD ou WASD, souris, clic gauche, Espace et R.
- Garcia / J2 : première manette connectée, sticks, RT pour tirer, LT pour dasher, X ou carré pour recharger. Sans manette il reste immobile ; ce contrôle ne fournit pas encore le bot de la v0.2.
- Après le décompte, passer sur la bouteille au centre. Le porteur boit automatiquement, sans bloquer ses actions. Un tir qui blesse interrompt sa possession ; le score acquis reste conservé.
- **Échap** ouvre la pause. **Reprendre** continue la consommation ; **Rejouer** remet les états à zéro. La bouteille vide déclenche le résultat provisoire existant.

## Réalisation

[bottle.gd](../../../godot/scenes/bottle/bottle.gd) conserve une seule source pour la possession, les scores et la réserve. La prise donne priorité à l’actif autorisé le plus proche et tire au sort une égalité exacte. Les prises supplémentaires sont refusées pendant une possession ou après épuisement ; un fantôme ne peut ni prendre ni consommer. Le contenu reste compté en unités entières avec accumulation des fractions de débit et plafonnement de la dernière gorgée.

`get_state()` fournit `holder`, `total_amount`, `remaining`, `scores` et `empty`. Le dictionnaire des scores est une copie indépendante. `state_changed(state)` publie cet état après initialisation, prise, perte et variation des quantités. L’état final est publié avant `emptied`, émis une seule fois. `possession_changed(holder)` reste disponible, avec `null` à la perte. La présentation de #66 peut utiliser ces données sans recalculer les scores.

`configure(players, origin)` réinitialise aussi les fractions, la projection, le délai de reprise et l’état de fin, sans doubler les connexions de dégâts. La scène de contrôle branche les deux apparences existantes et ne montre plus les pourcentages de réserve ou de score pendant le round.

Réglages provisoires conservés : 2 400 unités, 60 unités/s, rayon de prise 15 unités. Cela représente 40 secondes de possession cumulée au débit actuel, sans fixer une nouvelle règle de durée. Projection et délai existants restent à examiner dans #24. L’habillage graphique et sonore définitif relève de #66 ; l’assemblage avec bot, résultat et navigation relève des missions suivantes, dont #26. La vérification des éléments déjà présents ne vaut pas validation de ces missions.

## Vérification technique

[verify_match.gd](../../../godot/tools/verify_match.gd) réutilise la vraie scène, ses personnages, entrées et collisions. Les cas de débit fractionnaire et de dépassement final utilisent des pas de temps contrôlés sur ces mêmes instances ; les actions, transferts, pauses et reprises sont exercés dans la scène.

```sh
godot --headless --path godot --script res://tools/verify_match.gd
godot --path godot --audio-driver Dummy --fixed-fps 60 --script res://tools/verify_match.gd
godot --headless --path godot --script res://tools/verify_shooting.gd
godot --headless --path godot --script res://tools/verify_reload.gd
```

| Contrôle | Résultat | Preuve |
| --- | --- | --- |
| Partie sans affichage | 69 contrôles réussis | [Rapport détaillé](verification-headless.json), [journal](checks/match-headless.log) |
| Partie avec rendu natif 1080p | 73 contrôles réussis, dont quatre sauvegardes de captures | [Rapport détaillé](verification-rendered.json), [journal](checks/match-rendered.log) |
| Régression du tir | 47 contrôles réussis | [Journal](checks/shooting.log) |
| Régression du rechargement | 53 contrôles réussis | [Journal](checks/reload.log) |

Les cas ajoutés couvrent l’état initial publié, l’absence de consommation au sol, la prise unique, le débit fractionnaire, les deux porteurs, les instantanés indépendants, la conservation des quantités dans chaque état, l’épuisement avec dépassement et signal unique, la réinitialisation, le porteur devenu fantôme et l’absence de pourcentages pendant le round. Garcia exerce déplacement, visée, tir, rechargement et dash via événements manette simulés. Les contrôles existants couvrent aussi perte/récupération, arbitrage, pause et reprise, mode fantôme, rejeu et retour au titre.

Les journaux sans affichage contiennent le message macOS `get_system_ca_certificates` déjà présent avant la modification ; les contrôles se terminent avec un code zéro. Le passage avec rendu ne produit pas ce message.

Captures natives examinées : [Poncho porteur](bottle-carried.png), [Garcia porteur en recharge/dash](garcia-carried.png), [fantôme](ghost.png) et [résultat provisoire](result.png). Les contrôles techniques et l’examen de captures ne remplacent pas l’essai du producteur ni un essai sur manette physique. Aucun effet de particules ni son définitif de #66 n’est livré ici.
