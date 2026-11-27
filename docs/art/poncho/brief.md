# Poncho — contrat de production des sprites

Mission : [#38](https://github.com/noctambulart/tequila-kill/issues/38). Ce lot prépare des ressources graphiques ; leur intégration au personnage jouable appartient à #40.

Ce brief décrit le lot historique V4 en cellules de 48 × 48 pixels. Pour les ressources actuellement jouables en cellules de 144 × 144 pixels, consulter [#58](https://github.com/noctambulart/tequila-kill/issues/58) et [#60](https://github.com/noctambulart/tequila-kill/issues/60), qui renvoient aux exports et scènes d’essai concernés. Les coordonnées ci-dessous appartiennent au contrat V4.

## Références et intention

- Référence principale explicitement retenue par le producteur le 23 novembre 2026 : **colonne Poncho de `output/concept-art/2026-11-22/07-recherche-silhouettes.png`**, reprise fidèlement. Les essais A/B ne concernent pas ce lot.
- Concept de scène habitée : `output/concept-art/2026-11-22/06-scene-habitee-identites.png`, référence secondaire pour l'environnement et la bouteille.
- Portrait et chapeau historiques dans `archives-originales/TheMexicanTequilaWar/`, conservés intacts.
- Grand sombrero paille clair **à bord ovale**, **couronne olive haute avec son volume visible**, poncho brun foncé triangulaire et frangé. Conserver les proportions et la projection dessinées sur la planche, visage masqué. La V1 avait transformé le chapeau en disque vu verticalement ; elle est écartée après le retour du producteur. La V2 suit le concept choisi.

## Contrat proposé avant production

| Paramètre | Livraison |
| --- | --- |
| Format | PNG RGBA avec véritable transparence, sans décor ni repère de joueur incrusté |
| Cellule du personnage | 48 × 48 px ; silhouette principale d'environ 32 px de large, marges pour les poses |
| Ancrage | Point au sol sous le personnage : pixel (24, 40), commun à toutes les cellules ; la silhouette se développe au-dessus |
| Rendu | Pixels nets, palette réduite issue des concepts, affichage au plus proche voisin |
| Visée | Arme/bras séparés, pivot explicite ; orientation de visée indépendante du déplacement |
| Directions | Corps maintenu debout dans la projection du concept ; arme/bras orientables à 360° autour du pivot V4 (24, 26), examinés dans huit directions. Ne pas faire tourner le corps entier comme un disque |
| Éclairage | Ombrage local discret ; ombre portée livrée séparément pour ne pas la faire tourner avec la visée |
| Sources | Sorties originales imagegen, prompts exacts, références et transformations d'export conservés |
| Aperçus | Taille native, agrandissement entier et séquences animées sur fond sable et fond contrasté |

Le 48 × 48 est une cellule de livraison proposée pour ce lot, cohérente avec l'héritage Poncho. Il ne fixe ni le rayon de collision, ni la taille d'une tuile, ni la taille finale après les essais de caméra.

## Couverture prévue après examen de la pose étalon

- Repos et déplacement : base stable, balancement bref des franges et pas discrets ; sprint par variante de cadence et d'amplitude.
- Dash : pose ramassée et franges en arrière ; la poussière et les effets extérieurs relèvent de #47.
- Revolver : bras et arme séparés, repos/recul ; pas de projectile ou de flash incrusté au personnage.
- Rechargement : action composable du bras, pouvant être répétée balle par balle ; sa durée est pilotée par les règles du jeu.
- Boisson : bras et bouteille levée lisibles ; cycle court compatible avec le déplacement. La possession et le score restent gérés par le jeu.
- Dégâts et fantôme : présentation dérivée des sprites (teinte/opacité), sans inventer une animation de mort ni de nouvelles règles.

La production comprend une pose de repos, une boucle de marche de six cellules, quatre poses de dash, quatre poses de tir/recul, quatre poses de rechargement et quatre poses de boisson. Le sprint réutilise la marche à une cadence proposée plus rapide. La V3 ajoute une pose de bras au repos et une boucle de six poses d'avant-bras/arme, synchronisée avec les six pas et réutilisée pour la course. Les cadences d'aperçu ne fixent aucun délai de gameplay ; le manifeste consigne les correspondances et les réglages de présentation. Aucune séquence produite n'est réputée intégrée au gameplay par cette mission.

## Étape de validation

Produire et présenter d'abord une pose étalon, au format natif et au rendu cible. Le workflow sprite-pipeline part d'une image étalon approuvée avant de générer les bandes. L'examen porte sur la projection du dessus, la silhouette du sombrero, l'olive de la couronne, la frange brune et l'échelle dans l'arène. Les déclinaisons conservent ensuite une échelle et un ancrage communs.

État : le producteur demande de reprendre la recherche de silhouettes, puis de continuer. Cette sélection remplace la proposition V1 et fournit la référence retenue pour les déclinaisons. Pose V2 extraite avec imagegen, normalisée et examinée : cellule transparente 48 × 48, 23 couleurs visibles, ancrage (24, 40), silhouette dans [8, 11, 40, 40]. La couronne haute et le bord ovale sont conservés. Le lot animé est livré : sept entrées d'animation, 29 cellules dont six réutilisées pour le sprint. Aperçu GIF, atlas, cellules séparées et manifeste sont dans `output/sprites/poncho/issue-38/`. Lecture continue vérifiée dans Godot sur toutes les cellules. Les retours créatifs restent possibles ; l'appréciation en partie sera recueillie dans l'intégration #40.

## Fichiers de la première étape

### Correction V3 après retour sur la main

Le producteur demande une main mobile pendant la course, pouvant sortir de sous le chapeau. Le ticket #38 est rouvert. Deux nouvelles bandes imagegen fournissent l'avant-bras coudé : six poses de déplacement et huit poses de tir/rechargement. Les corps V2 restent identiques pixel pour pixel.

Le point de visée descend de (24, 26) à **(24, 29)**. L'ordre des couches devient corps, bras/arme, boisson, puis cache du bord du chapeau. Les caches reprennent les pixels exacts du haut du corps (jusqu'à la ligne 31 incluse), sans redessiner le sombrero. La main émerge sous le bord tandis que le début de la manche reste masqué. Le bras de marche/course partage la phase du corps ; ses variations de position ne sont pas effacées par un recentrage pendant l'export.

Livraison : `exports/v3/`, comparatif `review/poncho-v3-comparison.gif`, sources `source/*arm-v3*`. Contrôle de la main visible sur les six poses, des silhouettes inchangées, des alpha et de la synchronisation continue dans Godot. Cette correction reste une livraison graphique distincte de l'intégration #40.

### Précision V4 — main derrière le bord, comme dans la proposition

Le producteur précise le sens de « sous le chapeau ». La main ne doit pas être descendue à côté du poncho : le chapeau la masque, avec la prise de l'arme qui dépasse légèrement. La V4 remonte la prise et reprend la couche d'arme V2 pour conserver la longueur visible du canon. Une piste de six déplacements conserve le mouvement lié aux pas ; les corps et le chapeau sont identiques aux versions précédentes. Pivot de visée courant : (24,26), point au sol (24,40). Exports et manifeste dans `exports/v4/`, comparatif `review/poncho-v4-comparison.gif`, reconstruction par `scripts/poncho/build_v4.py`. Il s'agit d'un ajustement d'assemblage des couches existantes, sans nouvelle génération ni nouveau dessin du personnage.

- `output/sprites/poncho/issue-38/source/` : image générée originale, prompt exact et paramètres de normalisation avec empreinte SHA-256.
- `output/sprites/poncho/issue-38/exports/poncho-idle-seed-v2.png` : base fidèle à la silhouette retenue. La V1 est conservée pour l'historique et n'est pas utilisée pour les animations.
- `output/sprites/poncho/issue-38/review/` : aperçu natif et agrandi, ainsi que rendu réel Godot à huit rotations.
- `scripts/poncho/prepare_seed.py` : normalisation reproductible avec Python 3 et Pillow, sans repeindre la source.
- `scripts/poncho/build_lot.py` : normalisation des bandes, export des cellules/atlas, manifeste, contrôle des alpha et aperçus.
- `scripts/poncho/build_v3.py` : nouveaux bras, synchronisation, caches du chapeau, contrôle de la main visible et comparatif V2/V3.
- `godot/tools/review_poncho.gd` : présentation autonome des séquences et des directions de visée, sans remplacement des personnages jouables.

Reproduire la base V2 avec `python3 scripts/poncho/prepare_seed.py --version v2` dans un environnement disposant de Pillow.

Construire la base avec `python3 scripts/poncho/build_lot.py`, puis les corrections avec `python3 scripts/poncho/build_v3.py` et `python3 scripts/poncho/build_v4.py`, dans cet ordre. Reproduire les captures avec `godot --path godot --script res://tools/review_poncho.gd`. Le visualiseur utilise la V4 ; `-- --v2` et `-- --v3` sélectionnent les anciens lots. La commande se termine après capture ; ajouter `-- --animate` pour la lecture en boucle. Le fond de l'aperçu n'est pas incrusté dans les PNG exportés. Les [dépendances des outils](../../../scripts/README.md) sont déclarées séparément de celles du jeu.
