# Références graphiques de Tequila Kill

Analyse des archives locales du 6 novembre 2026, complétée par les décisions de densité graphique ci-dessous. Les observations décrivent les fichiers retrouvés ; les propositions historiques ne remplacent pas les références retenues dans les Issues de réalisation.

Pour produire ou intégrer un nouveau lot, partir des références et exports liés par sa mission : [personnages jouables #58](https://github.com/noctambulart/tequila-kill/issues/58), [village et zone étalon #60](https://github.com/noctambulart/tequila-kill/issues/60). Les sources anciennes ci-dessous documentent l’héritage du jeu.

Les liens ci-dessous pointent vers les [archives originales](../archives-originales/TheMexicanTequilaWar/), conservées localement et ignorées par Git. Ils nécessitent la présence de ces archives sur la machine.

## Identité à retenir

Un western mexicain caricatural en pixel art : soleil brûlant, sable jaune, bois usé, sombreros très visibles, ponchos et bouteilles vertes. Les portraits donnent aux personnages une personnalité de bandit ou de militaire de western. Les accessoires de bar relient le décor à l'objectif de la partie.

La [maquette de maison avec environnement et ombres](../archives-originales/TheMexicanTequilaWar/MokeUp/HouseDark_with_enviro_shadow.png) constitue la référence la plus complète pour l'arène. La [sélection de personnages](../archives-originales/TheMexicanTequilaWar/GUI/selection_perso_tekilla_kill.png) montre comment les portraits, les panneaux et les noms étaient assemblés.

## Ce que montrent les images

### Arène et personnages en jeu

- La maquette adopte une vue verticale : les sombreros apparaissent comme de grandes formes rondes, les tables et les chaises sont vues du dessus.
- Le sol associe sable clair et dallage gris bleuté. Les caisses, barrières, rochers et plantes structurent les espaces.
- Les ombres sont longues et décalées vers le bas et la gauche dans la maquette. Elles donnent du relief au mobilier et aux murs.
- Plusieurs éléments du personnage sont séparés : [chapeau](../archives-originales/TheMexicanTequilaWar/Sprites/Characters/Poncho_Hat.png), [ombre](../archives-originales/TheMexicanTequilaWar/Sprites/Characters/Poncho_Shadow.png) et [arme](../archives-originales/TheMexicanTequilaWar/Sprites/Characters/Gun_Small.png).
- La [chaise](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/Chair.png), la [table garnie](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/Table_Large.png), la [caisse](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/Crate_Wood.png) et le [canapé](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/couch.png) donnent au lieu un caractère habité.

### Portraits et bouteille

- Les portraits de [Poncho](../archives-originales/TheMexicanTequilaWar/Faces/Poncho.png) et de [Garcia](../archives-originales/TheMexicanTequilaWar/Faces/SgtGarcia.png) utilisent de larges chapeaux, des visages exagérés et des arrière-plans de western.
- Poncho est très sombre, avec un poncho brun et un ciel orange. Garcia combine un uniforme bleu-violet, un foulard rouge et une moustache très marquée.
- La [bouteille verte](../archives-originales/TheMexicanTequilaWar/Faces/Tequila_Rectangle_3.png) possède une silhouette distincte, une étiquette chaude et un bouchon clair. C'est un bon motif à conserver pour l'objectif central.
- Le [verre de tequila du HUD](../archives-originales/TheMexicanTequilaWar/Sprites/HUD/ShooterLife_Full_Icon.png) renforce le thème jusque dans les indicateurs de jeu.

### Menus et ambiance

- La sélection de personnages présente des panneaux verticaux couleur bois ou papier, des portraits carrés et des noms blancs très condensés.
- Une autre piste utilise des [planches dessinées au trait](../archives-originales/TheMexicanTequilaWar/Sprites/PersoSelectionScreen/PlankOfWood.png) et des [affiches de recherche](../archives-originales/TheMexicanTequilaWar/Sprites/PersoSelectionScreen/WantedPoster_Full.png).
- L'[écran de départ](../archives-originales/TheMexicanTequilaWar/Sprites/StartScreen/StartScreen.png) évoque un désert de western, avec mesas, ciel orange et grand soleil rouge.
- Ces fichiers explorent plusieurs traitements : pixel art détaillé, petits sprites à palette réduite et grands dessins au contour noir. Ils témoignent d'itérations ; ils ne forment pas encore une charte homogène.

## Informations techniques vérifiées

| Ressource | Observation |
| --- | --- |
| Fonds graphiques hors distribution exécutable | 282 fichiers ; 184 contenus uniques par SHA-256, soit 98 copies supplémentaires identiques. |
| Sources graphiques | 43 fichiers `.pyxel` et 47 `.psd`, copies comprises. |
| Portraits de base Poncho et Garcia | 96 × 96 pixels, avec plusieurs variantes et agrandissements. |
| Écran de sélection assemblé | 640 × 360 pixels. |
| Décors courants | Chaise, caisse et petite table : 32 × 32 ; grande table : 48 × 48 ; canapé : 96 × 32. |
| Tileset de sable exporté | 384 × 128 pixels ; les métadonnées de la source définissent des tuiles de 32 × 32. |
| Carte de sable | 36 × 22 tuiles de 32 pixels, soit 1152 × 704 pixels ; format JSON avec calques et références de tuiles. |
| Source Poncho dite animée | Canevas de 192 × 48, cellules de 48 × 48 ; calques fumée, arme, corps, jambes et ombre, plus un calque de base. Le champ `animations` est vide : les durées et l'enchaînement ne sont pas établis. |
| Effets exportés | Bandes de 16 pixels de haut : poussière sur 64 pixels, impact fumé sur 48, explosion sur 128. Le découpage en cellules de 16 pixels reste à vérifier dans les sources avant intégration. |
| Écran de départ | Source PNG de 120 × 80 et version de 1200 × 800 visiblement lissée. Privilégier la petite source pour étudier le pixel art. |

Sources techniques : [carte de sable](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/Sand_TileMap.json), [source du sable](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/Sand.pyxel), [source de Poncho](../archives-originales/TheMexicanTequilaWar/Sprites/Poncho/Poncho_animated.pyxel), [effets](../archives-originales/TheMexicanTequilaWar/Sprites/Effects/).

Les fichiers `.pyxel` examinés sont des archives ZIP comprenant un `docData.json`, des images de calques et des tuiles. Ils conservent donc des éléments éditables au-delà des seuls PNG exportés.

### Inventaire visuel du 22 novembre 2026

La galerie locale `output/anciens-graphismes/index.html` et son inventaire avec provenances `output/anciens-graphismes/inventaire.json` couvrent les fichiers graphiques locaux et les images extractibles des trois builds Unity, y compris `TheMexicanTequilaWar/dist/MexicanTekilaWar_0-0-3_Data`.

- 277 fichiers graphiques et typographiques recensés : 161 PNG, 2 JPG, 2 BMP, 47 PSD, 43 Pyxel, 20 polices et 2 fichiers de découpage `.tpsheet`. Ils représentent 181 contenus de fichiers distincts par SHA-256. Ce périmètre est plus restreint que le fonds documentaire de 282 fichiers décrit plus haut.
- 497 aperçus non vides distincts par dimensions et pixels RGBA, après extraction : images, composites, variantes, calques, tuiles et spécimens de polices. Une même image peut avoir plusieurs provenances ; les copies identiques sont regroupées.
- 26 planches de contact. Les vignettes sont recadrées sur le contenu visible ; l'image complète reste accessible au clic. Les aperçus Pyxel sont reconstitués à partir des calques, opacités et références de tuiles ; les composites PSD enregistrés sont privilégiés.
- Les builds v1 et v3 ont livré respectivement 85 et 71 entrées Texture2D/Sprite ; le build 0-0-3 en a livré 32. Ces nombres incluent les textures et leurs sprites, et ne désignent pas autant de graphismes uniques. Les atlas de police sans dimensions et les images vides sont consignés séparément.
- Limite : le fichier `sharedassets1.assets.resS` manque dans le build 0-0-3. Ses 54 entrées Texture2D/Sprite dépendantes restent non extractibles et sont nommées dans l'inventaire. Les huit sprites anciens dont le maillage n'était pas pris en charge ont été extraits par leur rectangle de texture, avec cette réserve indiquée dans leur provenance.

Les originaux n'ont pas été modifiés et aucun exécutable n'a été lancé. Cette galerie contient les archives historiques ; les concepts générés en novembre 2026 en sont exclus. Le script de reproduction est conservé dans [`scripts/archives/graphics_inventory.py`](../scripts/archives/graphics_inventory.py). Les [prérequis et la commande de reconstruction](../scripts/README.md#inventaire-des-archives) précisent ses dépendances Pillow, psd-tools et UnityPy.

## Base pixel art retenue

Base pixel art validée le 22 novembre 2026 dans [l’issue #12](https://github.com/noctambulart/tequila-kill/issues/12). Après son essai du 23 novembre, le producteur fixe la cible d’affichage à 1920 × 1080.

| Paramètre | Référence retenue |
| --- | --- |
| Tiles de terrain | **32 × 32 pixels** |
| Grille logique des scènes | **640 × 360 unités**, ratio 16:9 |
| Rendu à la taille cible | **1920 × 1080 pixels**, 3 pixels d’affichage par unité logique au zoom natif |
| Fenêtre initiale demandée | 1920 × 1080 |
| Mise à l'échelle | Facteurs entiers, ratio conservé, filtrage au plus proche voisin |

Les assets se dessinent à leur taille native ; l'agrandissement de l'image est assuré par Godot. La grille de terrain de 32 pixels n'impose pas cette taille à tous les objets : les formats historiques des personnages, du mobilier et des portraits restent des références à examiner et à harmoniser.

Après examen du rendu le 24 novembre 2026, la reprise [#58](https://github.com/noctambulart/tequila-kill/issues/58) augmente la densité des dessins des personnages : cellules source de 144 × 144 pixels, dessinées dans 48 × 48 unités logiques. Leurs silhouettes occupent toujours environ 32 unités de large ; les contours, franges et signes distinctifs disposent de plus de détails. À zoom natif en 1080p, un pixel de texture correspond à un pixel affiché. À 720p ou en vue d’ensemble, les textures sont réduites au plus proche voisin. Cette densité est propre aux personnages ; les tuiles de terrain restent à 32 × 32. Les anciens sprites restent disponibles pour comparaison et l’harmonisation avec le décor sera examinée en jouant.

Le 25 novembre, [l’intégration #60](https://github.com/noctambulart/tequila-kill/issues/60) harmonise Poncho, Garcia et vingt sprites de décor avec le [village retenu aux passages en fondu](../output/concept-art/2026-11-25/09-village-passages-fondu.png). Elle conserve les cellules de 144 pixels et les empreintes des personnages, avec une palette partagée sur chaque séquence et un ancrage au sol stable. Le nouveau tissu de Poncho couvre les pieds sans étirement. Les ressources de production sont dans les dossiers `assets/village/` des scènes de personnage et d’Arroyo Seco ; les sources originales, prompts et captures Godot sont conservés dans `output/arena/2026-11-25-integration/`. Les contours restent nets au plus proche voisin, tandis que les volumes et transitions de sol conservent les dégradés doux préférés par le producteur.

Le retour suivant sur la zone étalon demande une cohérence entre les couleurs chaleureuses du décor et celles des personnages. Une [itération chaude de Poncho et Garcia](../output/arena/2026-11-25-saloon-study/character-warm/README.md) prend la maison de cette zone comme référence de palette et d’ombrage : lumière miel/crème, médiums cuivrés, contours et ombres brun chocolat, avec des volumes plus lumineux. Les identités olive de Poncho et rouge/indigo de Garcia restent distinctes. Le producteur retient ce rendu et demande sa généralisation : il est désormais actif dans la visite, l’essai solo et la partie existante sur le [village V6 complet](../output/arena/2026-11-25-village-v6/README.md). La validation du rendu de référence ne remplace pas l’essai de la carte complète. Cellules, proportions et ancrage restent ceux du lot précédent.

Le 640 × 360 est attesté dans l’écran de sélection historique. Il sert de grille de composition pour les scènes actuelles. Le cadrage de l’arène et la lisibilité avec plusieurs joueurs devront être vérifiés dans une version jouable.

Le mode `canvas_items` dessine directement à la résolution de sortie. L’aspect `keep`, l’échelle `integer` et le filtrage au plus proche voisin préservent les pixels des sprites, avec des bandes autour de l’image aux tailles intermédiaires. Voir la [documentation Godot sur les résolutions multiples](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html).

## Direction proposée pour la nouvelle version

Conserver le pixel art, les silhouettes de sombreros, les portraits expressifs et le contraste entre village poussiéreux et bouteille verte. Utiliser la maquette d'arène comme référence du monde, et les portraits comme référence du caractère des personnages.

### Palette de départ

Ces valeurs proviennent des palettes enregistrées dans les sources `.pyxel` examinées. Elles constituent une proposition de départ, pas une mesure des couleurs dominantes de l'ensemble des images.

| Fonction proposée | Couleur |
| --- | --- |
| Sable et lumière | `#F7E26B` |
| Bois et ombres chaudes | `#493C2B` |
| Terre et cuir | `#A46422` |
| Soleil et accents chauds | `#EB8931` |
| Dégâts et accents rouges | `#BE2633` |
| Verre vert et végétation | `#A3CE27`, `#44891A` |
| Contours et ombres froides | `#1B2632`, `#2F484E` |

### Adapter la lecture à 16 joueurs

- Différencier les joueurs par la silhouette, la tenue et un marqueur ou numéro lisible. La couleur seule sera insuffisante pour identifier 16 personnages aux chapeaux proches.
- Donner à la bouteille et à son porteur un signal visuel prioritaire : contour, repère ou animation dédiée, à tester sur le sable comme sur le dallage.
- Réduire le contraste des textures de sol pour que les personnages, projectiles et objets à ramasser ressortent. Les nombreux détails des sols originaux risquent de concurrencer l'action.
- Rendre la direction de visée perceptible malgré les chapeaux. L'arme doit rester visible autour de la silhouette.
- Utiliser des effets courts et compacts. La poussière et les explosions doivent confirmer une action sans masquer les joueurs voisins.
- Réserver l'interface persistante à l'état de la bouteille, aux informations utiles du joueur et au score nécessaire. La composition exacte dépendra du mode local ou réseau retenu.

### Cohérence à établir

Appliquer la base de 32 pixels pour le terrain et vérifier la lisibilité dans la composition 640 × 360 affichée en 1080p. Les portraits et menus peuvent avoir leurs propres dimensions d’assets tout en partageant les couleurs et les matériaux du monde.

Pour le rendu du pixel art, privilégier les agrandissements entiers et le filtrage au plus proche voisin. Harmoniser les contours, la direction des ombres et le niveau de détail entre les sources avant de les intégrer.

Le bois usé et les affiches de recherche sont des motifs adaptés aux menus. Les noms et scores doivent conserver une typographie lisible aux petites tailles ; les caractères western très décoratifs peuvent servir aux titres.

## Références historiques

1. [Arène avec mobilier et ombres](../archives-originales/TheMexicanTequilaWar/MokeUp/HouseDark_with_enviro_shadow.png) : cadrage, matériaux et éclairage.
2. [Sélection de personnages](../archives-originales/TheMexicanTequilaWar/GUI/selection_perso_tekilla_kill.png) : personnalité et présentation des combattants.
3. [Poncho](../archives-originales/TheMexicanTequilaWar/Faces/Poncho.png) et [Garcia](../archives-originales/TheMexicanTequilaWar/Faces/SgtGarcia.png) : portraits et caractérisation.
4. [Bouteille](../archives-originales/TheMexicanTequilaWar/Faces/Tequila_Rectangle_3.png) : forme et couleur de l'objectif.
5. [Tileset](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/Sand_Tileset.png) et [sources des décors](../archives-originales/TheMexicanTequilaWar/Sprites/Enviro/) : construction modulaire du village.
