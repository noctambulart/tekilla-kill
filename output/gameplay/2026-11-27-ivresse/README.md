# Ivresse — densité progressive et vol plus rapide

Réglage demandé par le producteur le 27 novembre 2026, suivi dans [#29](https://github.com/noctambulart/tequila-kill/issues/29).

Le nombre d’étoiles augmente progressivement avec la quantité cumulée bue sur toute la bouteille, avec un plafond d’environ 24. Repères : environ 6 après les premières gorgées, 11 à 10 % de la bouteille initiale bue, 16 à 30 %, 19 à 50 %, 22 à 75 % et 24 à 100 %. Ces quantités restent internes au calcul de l’effet.

Le cycle de vol passe de **1,35 à 0,8 seconde**. La trajectoire de montée/chute est parcourue plus rapidement, avec la même forme en cloche. La densité et la durée sont réglables dans `bottle_presentation.gd` (`star_density`, `star_lifetime`). L’effet persiste après la perte de bouteille, se masque en fantôme et revient avec la quantité déjà bue après récupération.

Vérification : **52 contrôles du parcours public réussis**, incluant la progression de densité, le mouvement des étoiles, le fantôme, la pause et le round complet. Deux captures natives examinées : [rapproché](ivresse-close.png), [vue d’ensemble](ivresse-far.png). La fixture visuelle utilise 900 unités bues pour Poncho et 400 pour Garcia, sur une bouteille initiale de 2 400 unités ; elle conserve la quantité totale et ne modifie pas le jeu public.

[Rapport technique](verification-headless.json). Pour essayer : **F5 → Jouer**. Aucun commit ni tag de livraison à cette étape ; l’essai du producteur reste à faire.
