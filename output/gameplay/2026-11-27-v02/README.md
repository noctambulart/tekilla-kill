# v0.2 — Un round contre Garcia, prêt pour review globale

Livraison technique locale du **27 novembre 2026**. À la demande du producteur — « Implémente toute les issues et on fera une review de toute la v0.2 » — les missions restantes sont assemblées dans l’ordre technique, avec une seule review finale. **L’essai et l’accord du producteur sur l’ensemble restent attendus dans [#26](https://github.com/noctambulart/tequila-kill/issues/26)** ; les tickets concernés et le jalon restent ouverts jusqu’à cette validation. Aucun accord créatif n’est déduit des contrôles ci-dessous. Aucun commit, push ou export autonome n’est réalisé par cette livraison.

## Lancer seul sur Mac

Dans Terminal, depuis la racine du dépôt :

```sh
godot --path godot
```

Passer l’introduction avec un clic, Espace, Entrée ou Échap, puis choisir **Jouer**. Le bouton ouvre maintenant le duel, sans F6 ni scène à rechercher. Pour ignorer seulement le parcours de titre pendant le développement :

```sh
godot --path godot --scene res://scenes/match/match.tscn
```

Poncho se contrôle au clavier/souris : ZQSD ou WASD, souris, clic gauche, R et Espace pendant le déplacement. Une manette peut remplacer ces commandes avec **Passer à la manette** : sticks, RT, LT et X/carré. **Garcia reste un bot**, même lorsqu’une manette est branchée. Échap/Start ouvre la pause ; la perte de focus ou le retrait du périphérique utilisé demandent une reprise volontaire. **F** bascule la vue ; **P** affiche le plan de développement.

Le résultat propose **Rejouer** et **Retour au titre**. Rejouer remet les états à zéro avec la même composition. L’essai solo v0.1 et les études de développement sont préservés dans leurs scènes directes ; ils ne sont plus derrière Jouer.

## Missions assemblées

| Issue | Réalisation et vérification |
| --- | --- |
| [#24](https://github.com/noctambulart/tequila-kill/issues/24) | Perte vers le tireur, collision aux pieds, délai de reprise par joueur, prise/perte distinctes. Le contrôle mécanique conserve ses 90 cas sur la carte. |
| [#25](https://github.com/noctambulart/tequila-kill/issues/25) | Fantôme invulnérable, très lent, sans autres actions ni ramassage ; récupération progressive, retour sur place à vie et chargeur pleins. Shader fortement désaturé, étoiles masquées puis restaurées avec le score conservé. |
| [#32](https://github.com/noctambulart/tequila-kill/issues/32) | Intentions de Garcia branchées sur le personnage existant, objectif connu, ramassage normal, éloignement d’une menace proche en porteur/fantôme. Aucun périphérique humain ne le commande. |
| [#33](https://github.com/noctambulart/tequila-kill/issues/33) | Poursuite du porteur, réaction retardée, visée imparfaite, vrais projectiles et munitions, rechargement volontaire balle par balle et reprise du combat. Fantômes exclus des cibles. |
| [#34](https://github.com/noctambulart/tequila-kill/issues/34) | Grille AStar sur les collisions existantes, trajets aux pieds, contournement et recherche d’une ligne de tir. Cinq situations reproductibles franchies sans téléportation du bot. |
| [#66](https://github.com/noctambulart/tequila-kill/issues/66) | UI de v0.1 conservée, réserve dans le cadre ovale V10, bouteille existante, ivresse V5 et marquage du porteur indépendants, fantôme V11, trois sons V1. Aucun pourcentage pendant le round. |
| [#26](https://github.com/noctambulart/tequila-kill/issues/26) | Introduction et titre conservés, Jouer vers Poncho/bot, décompte, pause, un round jusqu’à épuisement, résultat exact et pourcentage du gagnant, égalité partagée, rejeu et retour au titre. |

#23 a été validée et clôturée avant ce lot. Les concepts et sons déjà validés de #64/#65 restent les références ; ce lot ne rouvre pas leur conception.

## Sources, intégration et réglages

[match.gd](../../../godot/scenes/match/match.gd) assemble les scènes existantes. Le parcours public utilise le bot par défaut ; les suites mécaniques conservent une fixture à deux humains via une métadonnée propre à leur SceneTree de test. Le menu public ne propose pas cette fixture. Les références des contrôles d’intro, village et saloon sont adaptées au nouveau parcours tout en conservant les scènes historiques.

[bot_controls.gd](../../../godot/scenes/character/bot_controls.gd) fournit les mêmes intentions que les commandes humaines : déplacement, visée, tir et demande de rechargement. Il n’écrit jamais position, vie, munitions ou score pour faire réussir le bot. Réglages d’essai : décision toutes les **0,2 s**, réaction **0,3 s**, erreur de visée **±7°**, distance d’éloignement **300 unités**, distance de tir souhaitée **270 unités**. Le bot n’utilise pas de dash tactique ni de compétence, conformément au socle validé. Ces valeurs restent ajustables après la review.

[arena_navigation.gd](../../../godot/scenes/match/arena_navigation.gd) emploie une grille de **16 unités**, un rayon de requête de **9 unités** pour le noyau physique de **8 unités**, le contact des pieds à `(0, 16)` et le masque du décor solide. Les diagonales ne coupent pas les coins bloqués ; des segments dégagés simplifient le trajet. Le chemin est recherché de nouveau avec les décisions et changements d’objectif. Les objets ne sont pas détruits dans ce jalon ; la navigation après destruction reste en v0.3.

Un défaut découvert pendant l’intégration est corrigé : désactiver tout le monde pendant le décompte retirait aussi les corps statiques de l’espace physique, donc la grille initiale ignorait les murs. Le décor reste maintenant actif, les participants et effets attendent individuellement, puis la grille est construite après synchronisation physique avant le départ commun. Les cinq parcours ci-dessous couvrent cette régression. La caméra, les effets, la récupération de vie, la consommation et les intentions sont figés en pause ; une adaptation au redimensionnement de fenêtre reste possible.

[bottle_presentation.gd](../../../godot/scenes/bottle/bottle_presentation.gd) et [bottle_art.gd](../../../godot/scenes/bottle/bottle_art.gd) reprennent la [référence V11](../../ui/v0.2/issue-64/v11/README.md), les trajectoires V5 et les rapports V10. La texture de bouteille existante est recadrée en mémoire et sa version de verre vide préparée comme dans la maquette. Le cadre est dessiné avec les primitives natives ; aucune nouvelle image IA n’est générée. Les quantités viennent uniquement de `bottle.gd`.

Les étoiles à cinq branches changent d’origine à chaque émission, montent puis retombent avec rotation et effacement, à **4 ou 12 particules**, absentes à quantité nulle et en fantôme. Le seuil illustratif est 30 % du contenu initial ; ce réglage graphique ne change aucune capacité ni le calcul de victoire. Réglages validés repris : rythme de bouteille **4 rad/s**, hauteur **1,1**, écartement **1,05**, taille **1,1**. Les éclats de possession utilisent une autre forme, des tailles supérieures et des emplacements autour de la bouteille. Les tailles minimales de la maquette sont conservées au dézoom : environ **58 px** pour le repère porté et **66 px** pour la bouteille au sol, à la cible 1080p, sans agrandir leur collision.

Les trois WAV de [#65 V1](../../audio/v0.2/issue-65/v1/README.md) sont copiés à l’identique dans `godot/scenes/bottle/assets/`, avec [provenance et SHA-256](../../../godot/scenes/bottle/assets/provenance.json). Gain initial **−3 dB**. Les signaux de prise, perte et épuisement déclenchent chacun une lecture ; les sons de combat restent en place. La dernière gorgée peut se terminer au résultat. Les voix sont arrêtées lors de la sortie de scène.

Les réglages de partie restent ceux de la livraison mécanique : contenu **2 400**, débit **60 unités/s**, projection **90 unités en 0,22 s**, délai de reprise **0,45 s**, même revolver pour les deux personnages. Aucune durée de partie obligatoire n’est déduite des maquettes.

## Vérification technique et preuves

```sh
python3 scripts/godot_tasks.py verifier --timeout 180
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_v02.gd
godot --path godot --audio-driver Dummy --fixed-fps 60 --script res://tools/verify_v02.gd
```

Le lanceur importe et vérifie une copie isolée. **11 suites passent** : introduction ; déplacements (53) ; tir (47) ; rechargement (53) ; village (130) ; zone étalon (55) ; sprites courants et chauds (31 chacun) ; boucle mécanique (69) ; pertes/récupérations (329) ; assemblage public v0.2 (**51 sans rendu, 69 avec rendu dont 18 captures**). Les compteurs sont des assertions et ne prétendent pas représenter autant de règles distinctes.

Preuves : [rapport public sans rendu](verification-headless.json), [rapport avec rendu](verification-rendered.json), [synthèse](checks/summary.json), [journaux de toutes les suites](checks/regressions/), [journal public natif](checks/integration-rendered.log), [géométrie de la réserve](checks/reserve-geometry.json) et [traces des trajets](bot-routes.json). Les pixels visibles de la bouteille fixe restent tous contenus dans l’ovale extérieur V10. Les journaux sans rendu peuvent contenir le message macOS `get_system_ca_certificates` déjà présent avant ces travaux ; il n’empêche pas les suites de réussir. Aucun défaut de gameplay n’est déduit ou masqué par ce filtre d’environnement.

| Parcours du bot, coordonnées des pieds | Départ → objectif | Temps mesuré à 60 Hz |
| --- | --- | --- |
| Saloon | `(360,504)` → `(704,240)` | 133 images, 2,22 s |
| Épicerie | `(1072,536)` → `(800,712)` | 103 images, 1,72 s |
| Remise | `(256,816)` → `(432,688)` | 79 images, 1,32 s |
| Enclos | `(1184,224)` → `(1008,344)` | 73 images, 1,22 s |
| Près d’un couvert | `(1008,344)` → `(840,432)` | 67 images, 1,12 s |

Le contrôle public exerce aussi un porteur caché par un bâtiment : absence de tir dans le mur, contournement, ligne de tir retrouvée puis impact. Les interdictions et le retour du fantôme sont vérifiés sur Garcia dans ce contrôle et sur Poncho dans les contrôles mécaniques. Les événements manette sont simulés, incluant retrait, reconnexion et reprise volontaire ; la compatibilité du matériel physique reste à essayer.

Un round complet au contenu d’origine est joué sans téléportation ni modification de quantité, avec Poncho immobile au départ et Garcia autonome. Il se termine après **2 481 images, soit 41,35 s de simulation**, avec scores exacts **Poncho 0 / Garcia 2 400**. Ce contrôle prouve la boucle et son arrêt ; il ne remplace pas un essai humain des sensations. Les résultats Poncho et égalité utilisent des fixtures de dernière gorgée distinctes, clairement séparées de ce round complet.

## Captures et aperçu sonore

- Au sol : [rapproché](ground-close.png), [éloigné](ground-far.png).
- Poncho porteur : [rapproché](poncho-carried-close.png), [éloigné](poncho-carried-far.png).
- Transfert vers Garcia moins ivre : [rapproché](transfer-close.png), [éloigné](transfer-far.png).
- Fantôme : [rapproché](ghost-close.png), [éloigné](ghost-far.png), [retour](ghost-return.png), [pause](ghost-pause.png).
- Réserve faible : [rapproché](low-reserve-close.png), [éloigné](low-reserve-far.png).
- Résultat : [Poncho](result-poncho.png), [égalité](result-tie.png), [fin du round autonome de Garcia](full-round-result.png).
- [Décompte](countdown.png), [saloon](bot-saloon.png), [combat](bot-combat.png).

[Aperçu animé et sonore MP4, 9,4 s](preview-v02.mp4). Capture native Godot en 1080p, livrée en H.264/AAC 720p pour lecture pratique. Le script [preview_v02.gd](../../../godot/tools/preview_v02.gd) arrange les positions, un niveau d’ivresse préalable et la dernière gorgée pour présenter les états en peu de temps ; cette vidéo **ne sert pas de preuve du round complet**. Les sons y sont déclenchés par les vrais événements : deux prises, une perte et un épuisement. Le PCM source contient de l’audio, aucun échantillon saturé, avec un pic de 16 564/32 767 ; l’équilibre subjectif reste à revoir en partie. Le MP4 est entièrement décodé pour contrôle et une [image extraite](checks/preview-frame.png) est examinée.

Pour reproduire l’AVI avec son, sans encodeur externe :

```sh
godot --path godot --audio-driver Dummy --fixed-fps 60 --write-movie /tmp/tequila-v02-preview.avi --script res://tools/preview_v02.gd
```

L’encodage MP4 utilise seulement un binaire FFmpeg temporaire fourni par `imageio-ffmpeg 0.6.0`, hors du dépôt. Ce paquet n’est pas une dépendance du jeu ni des vérifications Godot.

## Review globale à faire avec le producteur

Lancer depuis le titre, jouer jusqu’au résultat, rejouer et revenir au titre. Examiner la réactivité des commandes, la difficulté/réaction du bot, ses trajets à travers les bâtiments, l’occasion de récupération offerte par un tir, le passage en fantôme, la lisibilité du porteur face à l’ivresse, le niveau de réserve, les trois sons et la pause. Consigner les retours dans #26 ; les corrections restent dans ce jalon. La clôture des tickets et du jalon attend l’accord explicite sur cette version assemblée.
