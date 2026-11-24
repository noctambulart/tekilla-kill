# Poncho — mission #38, correction V4

## Correction retenue pour la main

Le producteur précise que **la main est sous le chapeau comme sur la proposition**. La V3 avait trop descendu la main, la montrant à côté du poncho. La V4 corrige le placement dans le rig : **la paume est masquée derrière le bord**, avec une petite partie de la prise et le canon qui dépassent. L'arme garde la silhouette initiale de la proposition et son mouvement suit les pas.

- Aperçu actuel : `review/poncho-v4-comparison.gif` ; toutes les actions : `review/poncho-v4-actions.gif`.
- Exports actuels : `exports/v4/`, même format de couches 48 × 48 et point au sol (24,40), pivot de visée (24,26).
- Source : couche main/arme V2 existante, animée par une piste de six décalages de locomotion et masquée par le chapeau. Aucun nouveau dessin du corps ni nouvelle génération d'image.
- Vérifications : 80 à 100 % de la paume masquée sur les six poses de marche face à droite, canon restant visible et six états de mouvement distincts. La synchronisation marche/course reste couplée au corps.
- Reconstruction : `python3 scripts/poncho/build_v4.py`, après les exports V2/V3. Le visualiseur Godot utilise maintenant la V4 ; `-- --v2` et `-- --v3` conservent les anciens aperçus.

Les descriptions V3 ci-dessous restent l'historique de la correction précédente ; le contrat actuel est `exports/v4/manifest.json`.

## Historique V3

Le producteur retient explicitement Poncho dans la **recherche de silhouettes** le 23 novembre 2026. Ce lot reprend son bord ovale, sa couronne olive haute et son poncho triangulaire frangé. La proposition V1 au chapeau circulaire est écartée et conservée uniquement comme historique.

Retour sur la V2 : la main restait fixe pendant la course et semblait posée sur le chapeau. La **V3 ajoute un avant-bras coudé et une boucle de six poses de bras synchronisée avec les pas**. L'attache passe sous le bord du chapeau. Les cellules du corps V2 sont réutilisées à l'identique.

- **Comparatif animé** : `review/poncho-v3-comparison.gif` (ancienne main, marche corrigée, course corrigée).
- **Toutes les actions** : `review/poncho-v3-actions.gif`.
- **Rendu Godot réel** : `review/poncho-v3-godot-*.png`, `review/poncho-v3-comparison-godot.png` et `review/poncho-v3-directions-godot.png`.
- **Exports actuels** : `exports/v3/`, cellules PNG RGBA 48 × 48 et atlas horizontaux. `exports/v2/` reste disponible pour l'historique et la reconstruction des corps.
- **Contrat machine** : `exports/v3/manifest.json` ; mesures, positions de la main visible et empreintes des atlas dans `quality.json`.
- **Sources** : fichiers originaux générés et prompts exacts dans `source/`, sans remplacement des références historiques.
- **Brief** : `docs/art/poncho/brief.md` à la racine du dépôt.

| Séquence | Cellules | Cadence d'aperçu | Couche |
| --- | ---: | ---: | --- |
| Repos | 1 | 1 i/s | Corps |
| Marche | 6 | 8 i/s | Corps |
| Sprint | 6, réutilisation de la marche | 12 i/s | Corps |
| Dash | 4 | 20 i/s | Corps |
| Tir / recul | 4 | 18 i/s | Bras droit / arme |
| Rechargement | 4 | 8 i/s | Bras droit / arme |
| Boisson | 4 | 6 i/s | Bras gauche / bouteille |
| Bras au repos | 1 | 1 i/s | Bras droit / arme |
| Bras en marche | 6 | 8 i/s, même phase que Marche | Bras droit / arme |
| Bras en course | 6, réutilisation de la boucle de bras | 12 i/s, même phase que Sprint | Bras droit / arme |

Les cadences sont des propositions graphiques, pas des délais de gameplay. Une recharge de balle peut déclencher une boucle du geste ; le code garde la responsabilité des munitions et du temps. Sprint et marche partagent leurs cellules. Le fantôme et les dégâts sont des teintes/opacités de présentation ; les effets extérieurs sont suivis dans #47.

Le **point au sol est (24, 40)**, le **pivot de visée V3 (24, 29)**. Le corps reste droit dans la projection du concept ; seul le bras/arme tourne. Ordre d'affichage : **corps → bras/arme → boisson → cache du chapeau**. Les caches `occlusion/` reprennent les pixels exacts de la partie supérieure de la cellule du corps ; ils font passer l'attache du bras sous le bord. Utiliser le cache de la même cellule que le corps.

`walk_arm` utilise exactement la phase de `walk`, et `sprint_arm` celle de `sprint` : ne pas lancer deux horloges indépendantes. Les positions relatives des poses de bras sont conservées pendant la normalisation ; les recentrer cellule par cellule supprimerait leur balancement. Pour un tir/rechargement en déplacement, conserver la piste d'attache d'épaule fournie par le manifeste. La visée reste une rotation indépendante. Les cellules 48 × 48 sont des couches ; ne pas couper le personnage composé à ces limites après rotation de l'arme.

La boisson utilise l'autre bras et peut être superposée au tir. Aucun numéro/cercle de joueur ni ombre portée n'est incrusté dans les exports.

Les bandes ont une échelle commune à leurs cellules, un ancrage constant, une transparence binaire et une palette limitée sans tramage. Le corps reprend la palette de la base V2. La première cellule de marche et de dash reprend la base exacte. Les cellules de repos de la marche et de récupération du dash sont également verrouillées sur cette base.

Reconstruction (Python 3 et Pillow) :

```sh
python3 scripts/poncho/prepare_seed.py --version v2
python3 scripts/poncho/build_lot.py
python3 scripts/poncho/build_v3.py
```

Dans Godot, vérifier les images et capturer les états :

```sh
godot --path godot --script res://tools/review_poncho.gd
```

Ajouter `-- --animate` pour regarder les six séquences en boucle. L'aperçu est indépendant du jeu et ne modifie aucun personnage jouable.

Ajouter `-- --verify-animation` pour contrôler automatiquement la lecture continue : chaque cellule doit être parcourue et les images rendues doivent changer.

La V3 contrôle les dix entrées, dont les nouvelles pistes de bras, et leur synchronisation avec le corps. `-- --v2` permet de rejouer les anciens aperçus.

**État : correction V3 produite et vérifiée techniquement ; #38 rouverte pour les retours graphiques.** Dix entrées, 42 cellules d'animation en comptant les réutilisations et 17 caches de chapeau dérivés du corps. La main visible varie sur la boucle et apparaît sous le bord. La lisibilité aux zooms de partie, les gestes selon les déplacements réels et les réglages des cadences seront éprouvés dans #40 ; aucune intégration au gameplay ni validation créative d'une partie jouée n'est revendiquée.
