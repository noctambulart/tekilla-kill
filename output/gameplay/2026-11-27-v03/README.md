# v0.3 — Arène et objets cassables

Livraison locale du 27 novembre 2026, suivie dans [#29](https://github.com/noctambulart/tequila-kill/issues/29). La vérification technique est terminée ; la validation du producteur sur la version assemblée reste à donner. Aucun commit ni push effectué par cette mission.

## Lancer et essayer

Depuis la racine : `godot --path godot`, passer l’introduction, puis **Jouer**. Ou F5 dans Godot. Le titre et le round existants lancent maintenant la v0.3.

- Tirer sur les objets : **pot 1 balle, chaise 3, caisse 5**, selon le choix du producteur. Leurs débris ne bloquent ni la marche, ni le tir, ni la bouteille. Les autres meubles et bâtiments restent permanents.
- Dasher par-dessus les pots et chaises : portée normale de **67,2 unités en 0,12 s**, arrivée vérifiée avec **2 unités de marge** autour du pied de rayon 8. Un ou plusieurs petits objets peuvent être franchis. Un trajet bloqué par un obstacle permanent, une caisse ou un adversaire, une arrivée occupée ou une distance insuffisante fait conserver les collisions ordinaires : arrêt devant le petit objet. Le test agrandi ne modifie pas la collision de marche.
- En cas d’interruption pendant le franchissement, retour au dernier point libre déjà traversé, puis restauration des collisions. Une pause conserve la progression. Une petite élévation visuelle et le passage du personnage devant les petits objets accompagnent le franchissement.
- Clic / RT frappe automatiquement au contact : **30 unités et arc de 90°**, selon le choix du producteur. La crosse commune retire 25 PV internes, soit un segment ; elle ne dépense pas de balle et partage la cadence de **0,24 s** du revolver. Portée et arc sont réglables. Le nouvel appui peut interrompre la recharge, même à vide ; un ancien maintien ne l’interrompt pas. Les règles de bouteille, d’étourdissement, de dash et de fantôme s’appliquent.
- La vie comporte quatre segments ; leur remplissage successif dure cinq secondes en fantôme. Un son original bref, synthétisé dans Godot et distinct de la cartouche, joue aux quatre unités complétées. Pause et rejeu conservent les règles communes.
- Garcia utilise les mêmes attaques et ressources. La navigation se reconstruit à la prochaine recherche de chemin après une casse ; la visibilité de tir utilise les silhouettes réelles des couverts intacts. Le rejeu restaure le décor entier.

La carte V6 conserve son tracé. Les essais automatiques confirment les passages et les poursuites ; les ajustements de placement et d’équilibrage dépendront des observations du producteur en duel. Le réseau, les compétences spéciales et le HUD à portraits gardent leurs jalons.

## Implémentation et sources

- [Objets cassables](../../../godot/scenes/arroyo_seco/breakable_prop.gd) : résistance, silhouette de tir, dégâts, libération des collisions et remplacement par les débris.
- [Carte](../../../godot/scenes/arroyo_seco/arroyo_seco.gd) : intégration aux objets existants et trois résistances exposées. Les chaises orientées conservent leurs sprites intacts ; leur état détruit devient un amas commun.
- [Personnage](../../../godot/scenes/character/character.gd) : prévision et restauration du dash, quatre segments, récupération et effets. Le calcul interne 100 PV / 25 dégâts reste compatible avec les outils de développement.
- [Revolver](../../../godot/scenes/character/revolver.gd) : substitution de l’attaque selon portée, arc et accessibilité, cadence et recharge partagées.
- [Bot](../../../godot/scenes/character/bot_controls.gd) et [navigation](../../../godot/scenes/match/arena_navigation.gd) : visibilité du couvert, attaque à vide au contact et actualisation des chemins.
- Visuels réutilisés : états intacts chauds de la carte actuelle, états cassés de `godot/scenes/arroyo_seco/assets/village/`, issus du [lot d’intégration](../../arena/2026-11-25-integration/README.md). Les exports antérieurs de #42 sont conservés. Aucune nouvelle image générée.
- Sons de crosse et de récupération : synthèse originale dans [shot_feedback.gd](../../../godot/scenes/character/shot_feedback.gd), sans sample tiers. Le son historique de rechargement est conservé.

## Vérifications techniques

**889 contrôles sans interface réussis**, dont 109 propres à la v0.3 ; **120 contrôles avec rendu natif réussis**, dont onze captures. Godot 4.7.2 standard / Compatibility, Apple M1 Pro, 1920 × 1080. Le rendu du dash, des débris, de la crosse et des segments a été examiné sur les captures. Le son doit encore être apprécié dans le mixage en jouant.

| Contrôle | Nombre | Résultat |
| --- | ---: | --- |
| Tirs | 47 | Réussi |
| Rechargement | 53 | Réussi |
| Boucle mécanique de partie | 69 | Réussi |
| Perte et récupération de bouteille | 330 | Réussi |
| Étourdissement du porteur | 47 | Réussi |
| Parcours public v0.2 | 51 | Réussi |
| Ajouts v0.3 | 109 | Réussi |
| Carte / connexions des zones libres | 130 | Réussi |
| Déplacements et commandes | 53 | Réussi |

Les nouveaux scénarios couvrent : impacts réels sur chaque type de couvert jusqu’à sa destruction, arrêt de la balle fatale et passage de la suivante, grille de navigation libérée, mur permanent ; crosse à vide, arc et portée, mur fin, maintien, passage crosse–tir, cadence, interruption de recharge, bouteille et fantôme ; franchissement d’un ou deux objets, arrivée occupée, caisse / mur / adversaire derrière, marge insuffisante, arrêt et retour au point libre lors d’une interruption ; quatre unités et sons de récupération, pause et rejeu ; clic réel et événements manette simulés ; caisse de rue de la vraie carte ; Garcia dans les cinq parcours puis un round complet avec la quantité d’origine jusqu’au résultat.

Le round intégral déterministe se termine en 2 481 images simulées, sans changement de quantité ni téléportation : Garcia boit 2 400 unités. Il vérifie l’achèvement de la boucle, pas l’équilibrage face à un humain actif.

Rapports : [sans interface](verification-headless.json), [rendu natif](verification-rendered.json), [récapitulatif](delivery.json), journaux dans `checks/`. Le journal sans interface peut contenir l’erreur macOS connue `get_system_ca_certificates`, liée au sandbox ; aucune erreur de script dans les exécutions finales.

```sh
python3 scripts/godot_tasks.py verifier combat partie carte deplacements
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_v03.gd
godot --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_v03.gd
```

Les contrôles sont intégrés au sujet `partie` de l’outil commun. Les fixtures du contrôle v0.3 isolent les cas limites ; elles ne modifient pas la composition publique du duel.

## Captures natives

- [Caisse de rue intacte](street-cover-intact.png) et [cassée](street-cover-broken.png), sur la carte actuelle.
- [Pot détruit](broken-pot.png), [chaise détruite](broken-chair_n.png), [caisse détruite](broken-crate.png), dans des fixtures à deux personnages.
- [Dash au-dessus d’un pot](dash-pot.png) et [d’une chaise](dash-chair_n.png).
- [Crosse et dégâts](melee-close.png).
- [Fantôme et segments](ghost-segments.png).
- [Garcia traverse le saloon](bot-saloon.png) et [résultat du round intégral](full-round-result.png).

## Essai du producteur

Reste à évaluer en jouant : sensations de la crosse, robustesse des objets, utilité du franchissement, lisibilité aux deux cadrages, sons de récupération et équilibre des passages contre Garcia. Une manette physique reste à essayer sur le matériel du producteur. L’Issue #29 et le jalon v0.3 restent ouverts jusqu’à son accord explicite.
