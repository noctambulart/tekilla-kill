# TowerFall Ascension : salon et lancement local

Recherche bornée du 22 novembre 2026 pour éclairer le salon de préparation de Tequila Kill. Elle porte sur **TowerFall Ascension**, surtout son mode compétitif local, sans généraliser à l’édition Switch, aux modes coopératifs ou aux mods réseau.

## Conclusion utilisable

**Ne pas attribuer à TowerFall la règle « tous prêts → combat immédiat » sur la base de cette recherche.** Des captures directes du jeu attestent trois interfaces distinctes : sélection des personnages, configuration du combat avec un bouton **BEGIN**, et sélection d’une tour sur une carte. Elles ne constituent pas un enregistrement continu et **ne prouvent ni leur ordre exact, ni l’action qui quitte la sélection des personnages**. Le passage précis « dernier personnage confirmé → écran suivant » reste donc non vérifié. [Sélection](https://interfaceingame.com/screenshots/towerfall-ascension-select-character/), [configuration](https://interfaceingame.com/wp-content/uploads/towerfall-ascension/towerfall-ascension-game-mode.png), [carte](https://interfaceingame.com/wp-content/uploads/towerfall-ascension/towerfall-ascension-sacred-ground.png).

**Aucune preuve d’un compte à rebours de salon n’a été obtenue.** Ni sa présence, ni son absence, ni sa durée ne sont établies ici. Ne pas transformer une éventuelle proposition de compte à rebours pour Tequila Kill en fait concernant TowerFall.

## Ce que les sources attestent

### Cadre officiel

La fiche publiée par le développeur présente Ascension comme un jeu local jusqu’à quatre joueurs, centré sur des affrontements compétitifs entre amis, avec des mécaniques accessibles mais difficiles à maîtriser. Elle mentionne 120 cartes Versus et 75 variantes pour personnaliser les parties à sa sortie. Cela justifie la référence pour le dynamisme et la maîtrise, sans définir le fonctionnement du salon. [Fiche officielle Steam](https://store.steampowered.com/app/251470/TowerFall_Ascension/).

Un changelog officiel de la mise à jour 1.2.2 indique que revenir à **Archer Select** depuis le menu de fin d’un match Versus fait désormais sortir tous les joueurs de leur état rejoint. Il confirme donc la distinction entre « être présent sur l’écran » et « avoir rejoint », ainsi qu’un retour possible à la sélection après le match. Il ne documente pas les boutons ni le départ initial. [Annonce officielle, rubrique 1.2.2](https://steamcommunity.com/app/251470/announcements/).

### Observations directes de captures du jeu

Les images suivantes ont été inspectées visuellement. Interface In Game les héberge ; ce sont des observations de l’interface représentée, pas un manuel officiel. La page n’établit pas la plateforme ni le numéro exact de la version capturée. La capture de sélection comprend les indications XINPUT et KEYBOARD1 ; elle correspond donc à une interface avec entrées PC. [Image source](https://interfaceingame.com/wp-content/uploads/towerfall-ascension/towerfall-ascension-select-character.png).

| Interface | Observation certaine dans l’image | Ce qu’elle ne permet pas de conclure |
| --- | --- | --- |
| Sélection des personnages | Quatre portraits colorés sous FIGHT!, des noms, des flèches gauche/droite, des indications A pour deux manettes et C pour le clavier ; la quatrième place affiche un symbole d’absence de périphérique. | La succession exacte rejoindre / parcourir / confirmer ; le bouton annuler ; une étape « prêt » distincte ; la condition de sortie de l’écran. |
| Configuration | GAME MODE: LAST MAN STANDING, STANDARD MATCH, PLAY TO: 5, VARIANTS et BEGIN sont visibles. | Le moment où cet écran apparaît ; qui peut modifier les options ou activer BEGIN ; l’écran obtenu après BEGIN. |
| Carte | SACRED GROUND apparaît au-dessus d’une carte du monde ; un personnage sert de marqueur et une grille d’icônes est visible. | Le bouton de confirmation, les droits des périphériques et l’ordre exact par rapport à la configuration. |

Sources des lignes : [sélection](https://interfaceingame.com/wp-content/uploads/towerfall-ascension/towerfall-ascension-select-character.png), [configuration](https://interfaceingame.com/wp-content/uploads/towerfall-ascension/towerfall-ascension-game-mode.png), [carte](https://interfaceingame.com/wp-content/uploads/towerfall-ascension/towerfall-ascension-sacred-ground.png).

### Indices du code communautaire, avec limites

FortRise est un **chargeur de mods communautaire**, pas le code officiel complet d’Ascension. Son patch `RollcallElement` distingue des états `NotJoined` et `Joined`, gère le défilement gauche/droite et évite certains personnages déjà pris, non débloqués ou interdits par le mod. Mais les fonctions qui traitent réellement les entrées (`NotJoinedUpdate`, `JoinedUpdate`) sont déclarées `extern` / `MonoModIgnore` : leur comportement original n’est pas présent dans ce fichier. **Il ne permet pas d’établir les boutons de confirmation/annulation ni le départ automatique.** [README FortRise](https://github.com/FortRise/FortRise), [patch au commit consulté](https://github.com/FortRise/FortRise/blob/4a8bf7ce29a6e564ef9f0d74b8235f74547bc6e1/TowerFall.FortRise.mm/Patches/RollcallElement.cs).

Le patch `MainMenu.CreateRollcall` ajoute un `ReadyBanner` en Versus et quatre `RollcallElement`. Le code de ce bandeau et sa condition de validation ne figurent pas dans ce patch. Le nom `ReadyBanner` seul ne prouve donc pas « tous prêts → carte », « tous prêts → configuration » ou « tous prêts → combat ». [Patch MainMenu au même commit](https://github.com/FortRise/FortRise/blob/4a8bf7ce29a6e564ef9f0d74b8235f74547bc6e1/TowerFall.FortRise.mm/Patches/MainMenu.cs).

## Réponses aux questions précises

| Question | Résultat de la recherche |
| --- | --- |
| Comment rejoindre ? | L’état rejoint est attesté par l’annonce officielle ; la capture expose des invites par périphérique. La séquence de boutons n’est pas vérifiée. |
| Comment sélectionner / confirmer ? | Des flèches et invites A/C sont visibles ; la fonction exacte de chaque pression et le verrouillage ne sont pas attestés. |
| Peut-on se remettre non prêt / annuler ? | Non vérifié. Le retour à Archer Select en fin de match désinscrit les participants depuis la mise à jour citée. |
| Que se passe-t-il quand tous ont confirmé ? | Non vérifié. Une configuration avec BEGIN et une sélection de carte existent ; aucune séquence observée ne les relie ici au dernier confirmé. |
| Le lancement est-il automatique ? | Non vérifié ; aucune preuve d’un compte à rebours. |
| Existe-t-il un hôte local avec des droits exclusifs ? | Non vérifié. Le jeu local ne suffit pas à déduire une exclusivité du joueur 1 ou du premier périphérique. Les salons de mods réseau ne répondraient pas à cette question sur le jeu local original. |

Les limites de ce tableau renvoient aux sources et aux observations détaillées ci-dessus ; elles sont des absences de preuve dans cette recherche, pas des affirmations d’absence dans le jeu.

## Pistes pour Tequila Kill — propositions, pas faits TowerFall

- Reprendre la lisibilité d’un panneau coloré par participant, avec son personnage, son périphérique et une indication claire de confirmation.
- Définir explicitement nos états : place vide, humain en sélection, humain prêt, bot. Le joueur doit comprendre ce qu’une pression confirme ou annule.
- Arbitrer séparément la condition « tous les humains sont prêts », le choix des paramètres communs et l’action qui lance effectivement la partie. Un démarrage automatique peut convenir à notre jeu, mais serait **notre décision**.
- Si un compte à rebours court est retenu pour le dynamisme, préciser comment l’annuler et ce qui se passe lorsqu’un joueur rejoint ou change son choix.
- Conserver l’ambition de combats techniques entre amis comme intention créative ; la recherche de salon ne valide pas à elle seule les règles ou les sensations de combat de Tequila Kill.

## Méthode et vérification restante

Sources prioritaires recherchées : fiche officielle, annonces du développeur, manuel, code et vidéo de développeur. Aucun manuel officiel décrivant ce parcours ni code original complet n’a été obtenu. Les patches communautaires et captures servent uniquement dans les limites annoncées.

Une vidéo de gameplay comportant une rubrique « Tutorial » a été repérée : [Coop Local Gaming, PC, 2 juin 2021](https://www.youtube.com/watch?v=LIW7PYcpslw). **Elle n’a pas été visionnée** : le navigateur intégré @Browser était indisponible et aucun autre navigateur n’a été utilisé. Son titre « Coop » ne suffirait d’ailleurs pas à prouver le flux Versus. Aucune observation chronométrée n’est donc revendiquée.

Pour lever l’incertitude restante, il suffit d’un essai local original ou d’un enregistrement continu : entrer en Versus, faire rejoindre deux joueurs, changer les personnages, confirmer un seul joueur puis annuler, confirmer les deux, relever l’écran suivant et chaque pression nécessaire jusqu’au combat ; répéter la navigation commune avec les deux périphériques pour vérifier les éventuels droits particuliers. Cette vérification n’a pas été réalisée dans cette recherche.
