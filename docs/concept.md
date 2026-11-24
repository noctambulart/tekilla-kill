# Tequila Kill

Suivi du concept : [Concept du jeu : Tequila Kill à Arroyo Seco](https://github.com/noctambulart/tequila-kill/issues/1).

Carte des décisions : [Préparer la première version partageable de Tequila Kill](https://github.com/noctambulart/tequila-kill/issues/2).

Règles de la première version : [Définir les règles d'une partie complète](https://github.com/noctambulart/tequila-kill/issues/3#issuecomment-7068280809).

Plateformes et périphériques : [Choisir les plateformes et les périphériques cibles](https://github.com/noctambulart/tequila-kill/issues/4#issuecomment-7068856907).

Contrôles et sensations : [Définir les contrôles et les sensations de déplacement et de combat](https://github.com/noctambulart/tequila-kill/issues/6#issuecomment-7079555221).

Caméra : [Définir la caméra commune et son zoom adaptatif](https://github.com/noctambulart/tequila-kill/issues/13#issuecomment-7079723366).

Bots : [Comportement commun de la première version](https://github.com/noctambulart/tequila-kill/issues/7#issuecomment-7079943523). Les enrichissements sont suivis dans [Epic — Enrichir les comportements et le caractère des bots](https://github.com/noctambulart/tequila-kill/issues/14).

Personnages, ressources visuelles et retours sonores : [Cadrage validé pour la première version](https://github.com/noctambulart/tequila-kill/issues/8#issuecomment-7080947423).

Cinématique d’introduction : [Cadrage validé](https://github.com/noctambulart/tequila-kill/issues/9#issuecomment-7081903562) et [epic de réalisation](https://github.com/noctambulart/tequila-kill/issues/15).

Parcours et livraison : [Cadrage validé de la première version partageable](https://github.com/noctambulart/tequila-kill/issues/10#issuecomment-7085719217).

Réalisation de la première version : [spécification et suivi des missions GitHub](https://github.com/noctambulart/tequila-kill/issues/17).

## Présentation

**Une bouteille. Un village.**

À **Arroyo Seco**, un petit village fictif de l’Arizona privé de livraison, il ne reste qu’une bouteille de tequila. Jusqu’à **16 joueurs** se la disputent dans un jeu de combat en arène, en vue du dessus.

Chaque personnage possède une arme et une compétence spéciale. Le porteur boit la bouteille jusqu’à ce qu’un autre joueur la lui arrache. Lorsque la bouteille est vide, **celui qui en a bu le plus remporte la partie**.

Pour la première version, une égalité sur la quantité maximale bue donne une victoire partagée.

## Origine et reprise du projet

Tequila Kill est un projet personnel né de l'envie de jouer entre amis, dans l'esprit des soirées sur SNES ou émulateur. Le producteur rapporte avoir développé un prototype avec déplacement, dash, tir et rechargement, en soignant les sensations de contrôle. La bouteille et la boucle de partie complète manquaient encore. Le projet a été abandonné devant le travail nécessaire pour couvrir aussi les graphismes, l'animation, le level design et le son.

La reprise avec l'IA doit permettre au producteur de porter l'intention, choisir les grandes orientations créatives, tester et arbitrer les priorités sans écrire le code. L'agent interlocuteur assure les propositions, la réalisation et l'intégration, par missions successives donnant des résultats concrets à examiner. L'[organisation de la production](agents/organisation.md) précise les responsabilités et les moyens de délégation.

## Première version cadrée

### Référence d'expérience : TowerFall

Le producteur retient **TowerFall** comme référence pour le dynamisme et le plaisir de batailles entre amis, avec des combats techniques où la maîtrise du déplacement, du timing et des actions permet de progresser. Cette référence complète l'intention des soirées SNES ou émulateur à l'origine du projet. La [présentation officielle de TowerFall Ascension](https://store.steampowered.com/app/251470/TowerFall_Ascension/) décrit précisément cette combinaison de multijoueur local, de mécaniques accessibles et de profondeur à maîtriser.

Pour Tequila Kill, rechercher des commandes réactives, des affrontements lisibles et expressifs, une prise en main accessible et une profondeur qui récompense la pratique. Le producteur préfère un départ conditionné par la confirmation de tous les humains. Le salon de TowerFall sert de référence à examiner pour rejoindre et choisir son personnage. Le [rapport de recherche sur son salon](research/towerfall-salon.md) distingue les interfaces attestées des transitions qui restent non vérifiées et des adaptations proposées pour Tequila Kill ; aucun délai de lancement ni règle supplémentaire n'est déduit de la seule référence au jeu.

Après cette recherche, le producteur choisit de définir le salon propre à Tequila Kill, sans attendre de reproduire le parcours exact de TowerFall. La référence aux sensations de combat reste retenue.

Après son essai du 23 novembre 2026, le producteur fixe la cible d’affichage à **1920 × 1080** et demande des déplacements plus rapides avec une légère accélération et un freinage bref au relâchement. Le freinage remplace l’arrêt immédiat du cadrage initial. TowerFall reste la référence de réactivité pour cet ajustement.

Le 24 novembre, le producteur demande une vitesse légèrement supérieure et une inertie plus perceptible, surtout dans les virages. La vitesse garde un instant sa composante dans l’ancienne direction pendant que le personnage commence à prendre la nouvelle.

### Périmètre de livraison

L'objectif est une petite version cohérente qu'une autre personne puisse lancer, comprendre et jouer jusqu'au bout. Les sensations de contrôle travaillées dans le prototype constituent une référence pour la reprise. Les règles de partie, les plateformes, les contrôles, la caméra, le socle commun des bots, les besoins visuels et sonores, l'introduction, le parcours de préparation et les critères de livraison sont cadrés dans les Issues liées ci-dessus. La carte de décisions est terminée ; la spécification et les missions de réalisation s'appuient sur ces résolutions.

La première version privilégie les joueurs réunis devant un **écran commun**, avec des **bots**, joueurs contrôlés par l'ordinateur. Une personne doit pouvoir jouer seule avec des bots. Les nombres de joueurs désignent le total des humains et des bots : une partie à quatre peut réunir un humain et trois bots ou deux humains et deux bots.

La caméra commune utilise un **cadrage adaptatif** : elle garde tous les personnages visibles, y compris les bots et les fantômes, ainsi que la bouteille lorsqu'elle est au sol, même éloignée du groupe. Elle dézoome lorsque ces éléments s'éloignent, puis se rapproche lorsqu'ils se regroupent, jusqu'à une limite de zoom. Ce choix remplace la vue permanente de toute l'arène. Les précisions de cadrage sont suivies dans l'Issue caméra liée ci-dessus.

**macOS sur Apple Silicon est la première cible**, puis Windows. Le support des Macs Intel sera ajouté après un essai dédié. Les premières applications seront transmises directement à quelques testeurs, sans installation de Godot. Les manettes constituent le mode de jeu de référence ; un joueur clavier-souris peut jouer avec des participants à la manette. La cible de la version partageable est de prendre en charge jusqu'à quatre humains simultanés, sous réserve de validation sur les périphériques retenus. Le producteur fournira les modèles de manette plus tard, avant les essais de compatibilité. La configuration des touches et boutons fait partie de la première version partageable, avec des profils de commandes personnels sauvegardés localement, selon les décisions de l'Issue des contrôles.

Pour la première version, les bots disposent d'un **socle commun simple** permettant de jouer une partie complète. Les stratégies liées au classement, les comportements de porteur plus élaborés et les caractères propres aux personnages seront cadrés dans l'epic ultérieure liée ci-dessus. Le producteur y apportera ses autres idées dans un second temps ; cette epic ne bloque pas la première version.

La progression retenue est **2 joueurs pour rendre la boucle complète jouable, 4 comme cible de la première version partageable, puis jusqu'à 8 si les essais et la faisabilité le permettent**. Le salon comporte quatre places et permet des parties à deux, trois ou quatre participants, dont au moins un humain. Les essais couvrent humains et bots, manettes seules et mélange clavier-souris/manettes ; les configurations réellement prises en charge seront déclarées après essais. Les 16 joueurs demeurent une ambition du jeu complet ; le réseau est réservé à une étape ultérieure.

Le salon reprend les affectations des périphériques aux places J1–J4 configurées dans Commandes. Chaque humain rejoint, choisit son personnage et confirme Prêt ; le premier humain peut ajouter des bots ou laisser des places vides. Tous les humains prêts et une composition valide déclenchent trois secondes de décompte, annulées si la composition ou les confirmations changent. Rejouer revient au salon prérempli avec une nouvelle confirmation collective. La résolution du parcours liée ci-dessus contient les interactions et critères détaillés.

La livraison doit permettre à une personne n'ayant pas suivi le projet de lancer l'application, comprendre la fiche, préparer une partie avec des bots, atteindre le podium et rejouer sans explication orale. La vérification technique et cette découverte autonome complètent la validation du producteur en jouant.

Les archives graphiques constituent un héritage à examiner et à harmoniser. Des assets provisoires peuvent servir aux étapes intermédiaires ; la version partageable doit former un ensemble cohérent. Les comportements des anciennes versions peuvent être simplifiés ou modifiés pour cette reprise.

## Vidéo et conservation des étapes

La réalisation servira de matière à une vidéo autour de la question : « Avec l'IA, puis-je enfin réaliser le jeu que je n'arrivais pas à porter tout seul ? » Conserver les versions et décisions importantes pour construire le récit après l'expérience, à partir du résultat réel.

Une cinématique d'introduction intégrée au jeu fait partie du périmètre de la première version partageable, pour ouvrir la vidéo. Son cadrage a été validé par le producteur le 22 novembre 2026. Il demande ensuite de démarrer sa création indépendamment du développement du jeu : cette révision remplace l'attente initialement prévue d'une partie complète fonctionnelle. La réalisation est suivie dans l'epic liée ci-dessus ; la [première version autonome](https://github.com/noctambulart/tequila-kill/issues/16) peut se jouer dans Godot avant l'implémentation du gameplay.

### Cinématique d’introduction retenue

Duel de regards de Poncho et Garcia dans une rue d'Arroyo Seco, en western caricatural et pixel art. La séquence dure environ **50 secondes**, avec une longue attente, une alternance des personnages et des cadrages progressivement plus serrés. Une mouche se pose sur le nez de Poncho et le fait loucher brièvement ; Garcia réagit, puis les personnages retrouvent leur sérieux. La bouteille est révélée à la fin en **reflet dans la pupille**, avec l'œil encore visible autour, avant la transition vers le titre. Le rythme précis sera ajusté sur la version animée.

La séquence se raconte sans voix off ni texte explicatif. Une petite musique de duel western accompagne le vent, des notes et percussions espacées, le bourdonnement de la mouche et des silences, dont une suspension avant le reflet. Les sons exacts et le mixage seront proposés à l'écoute lors de la réalisation.

L'intro se lance à chaque ouverture du jeu, peut être passée à tout moment et conduit à l'écran titre. Une entrée du menu permet de la revoir, avec le même retour à l'écran titre en fin de lecture ou après passage. L’intégration doit préserver la lisibilité du gag et du reflet dans la composition 640 × 360, rendue en 1080p à la taille cible. Le producteur évaluera le rythme et l’humour en regardant la séquence dans le jeu.

Le [storyboard V1](../output/intro/2026-11-22/storyboard-intro-v1.png), la [comparaison des pistes](../output/intro/2026-11-22/comparaison-reflet-pupille.png) et leur [provenance](../output/intro/2026-11-22/provenance.json) sont conservés comme références de cadrage. Les plans individuels et les éléments animables, notamment yeux, expressions, mouche et reflet, restent à produire. La capture pour YouTube et son raccord au récit sont suivis dans le projet vidéo.

## Identité visuelle

Un western caricatural en pixel art : désert brûlant, sombreros, ponchos, portraits expressifs et bouteille verte. Les graphismes conservés du prototype servent de références à la nouvelle version.

La [fiche unique de présentation](../output/pdf/tequila-kill-fiche.pdf) fait partie des informations de concept retenues le 7 novembre 2026. Elle réunit dix graphismes issus des archives originales et des versions Unity v1 et v3 : arène, bouteille, portraits, sélection de personnages et accessoires. Elle présente le nom **Tequila Kill** ainsi que le village **Arroyo Seco**. La provenance des images est conservée dans le [relevé des sources de la fiche](assets/concept/sources.json).

Consulter aussi l’[analyse des références graphiques](references-graphiques.md).

## État et archives

La nouvelle version est initialisée avec **Godot 4.7.2 standard**, **GDScript** et le moteur de rendu **Compatibility**. Le projet se trouve dans `godot/` ; voir les instructions du [README](../README.md). macOS est la cible initiale, suivie de Windows. Les paramètres du jeu local et le gameplay restent à préciser et à implémenter ; la capacité de seize joueurs est un objectif du jeu complet.

Les archives locales comprennent les graphismes **TheMexicanTequilaWar** et deux distributions Windows compilées avec Unity, **TequilaKill_v1** et **TequilaKill_v3**. Leurs noms historiques ne remplacent pas le nom retenu pour le nouveau jeu.

Les [fiches illustrées des versions Unity](archives-unity.md) conservent leurs décors, portraits, menus et accessoires comme références pour la réalisation.
