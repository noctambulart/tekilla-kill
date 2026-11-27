# Ramassage plus tolérant

Réglage demandé par le producteur le 27 novembre 2026, suivi dans [#29](https://github.com/noctambulart/tequila-kill/issues/29).

Le rayon de ramassage automatique passe de **15 à 28 unités**. Il suffit de frôler la bouteille ; cette portée reste réglable sur `Bottle.pickup_radius`. Le test de portée utilise les points au sol et vérifie le passage entre le personnage et la bouteille pour ne pas permettre la prise à travers un mur ou un couvert intact. Le rayon physique utilisé pendant la projection reste de 8 unités.

Les priorités au plus proche, l’arbitrage d’une égalité exacte, les exclusions de l’ancien porteur et du fantôme restent applicables. Le changement profite aux humains et aux bots. Le cercle de la bouteille provisoire dans les scènes de développement suit aussi le nouveau rayon ; la présentation publique garde son habillage.

**635 contrôles de partie réussis** : boucle mécanique 69, bouteille 336, étourdissement 47, parcours public 52, v0.3 109 et corrections de review 22. Les six nouveaux cas vérifient une prise en frôlant en diagonale, la limite de portée, l’exclusion pendant l’étourdissement et en fantôme, la priorité au plus proche et un mur fin séparant bouteille et personnage.

[Rapport des contrôles de bouteille](verification-headless.json). Journaux dans `checks/`. Commande : `python3 scripts/godot_tasks.py verifier partie`.

Pour essayer : **F5 → Jouer**. La tolérance se juge en jouant ; aucun accord global ni tag de livraison n’est déduit de cette demande.
