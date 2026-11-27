# Zone étalon du saloon — 25 novembre 2026

Correction de [#60](https://github.com/noctambulart/tequila-kill/issues/60) après les six retours du producteur : proportions incohérentes, sprites couchés, fondu en bandes, lumière insuffisante, sols pauvres et blocages dans des espaces visuellement libres. Le producteur confirme les proportions du concept comme référence, les collisions aux pieds avec chevauchement visuel, et une reprise saloon–entrée–rue–maison avant généralisation.

## Essayer

**Itération actuelle des personnages :** [palette chaude cohérente avec la maison, avant/après et sources](character-warm/README.md). Elle est active dans cette scène ; les captures de la première zone ci-dessous sont conservées comme historique.

F5 → passer l’introduction → **Essayer le saloon retravaillé**. La scène démarre en vue d’ensemble. **F** passe à la caméra adaptative, **P** montre les empreintes solides en rouge, **F2** réinitialise et **Échap** revient au titre. Les commandes de déplacement, visée, tir, dash et rechargement sont celles de l’essai solo. Garcia reste immobile.

Cette scène est une zone jouable de référence, pas la nouvelle version de toute la carte. La visite et l’essai solo habituels conservent la V5, y compris les défauts encore présents ailleurs. L’extension à l’arène complète suit le retour du producteur sur cette zone.

## Captures réelles du premier lot

- [Saloon, entrée, Poncho et Garcia dans Godot](saloon-in-game.png).
- [Ensemble saloon–rue–maison](saloon-overview.png).
- [Détail du fondu à l’entrée](entrance-fade.png).
- [Passage dans la marge de la maison et chevauchement du décor](house-passage.png).
- [Empreintes physiques](footprints.png).
- [Nouvelle entrée au titre](title-entry.png).

Les images proviennent du rendu natif de la scène et de ses personnages réels. Elles ne sont pas des concept arts aplatis ou des captures retouchées. Le banc de vérification règle la caméra pour les plans de détail. Référence artistique : [concept09 retenu](../../concept-art/2026-11-25/09-village-passages-fondu.png).

## Correction réalisée

La pièce mesure 448 × 352 unités ; les trois ouvertures restent larges et séparées. Les objets conservent le rapport largeur/hauteur de leur dessin. Les quatre orientations de chaise ont été dessinées individuellement dans le même lot, avec une gravité et une lumière communes. Aucun meuble n’est tourné à 90° pour simuler une autre vue. Les murs utilisent des modules bois/adobe et des petites façades à fenêtres ; les modules finaux sont recadrés, sans étirer leurs motifs.

| Élément | Dimensions affichées, en unités du monde |
| --- | --- |
| Poncho, silhouette au repos | Environ 31,7 × 36 |
| Table | 40,3 × 42 |
| Tonneau | 22,3 × 28 |
| Comptoir | 208 × 36 |
| Maison | 160 × 153 |

Le sol utilise deux matériaux générés, sable chaud et dallage bleu-gris en longues assises. Les quelques pixels mélangés au bord de la planche source sont exclus de l’export ; l’échantillonnage miroir évite les raccords de répétition. Le shader mélange les matériaux de façon continue sur des bords légèrement irréguliers aux ouvertures, au lieu de juxtaposer douze bandes d’alpha. Il garde l’arrière du saloon plus frais et laisse entrer une lumière chaude depuis les façades ouvertes. Les ombres de mobilier suivent les silhouettes et se projettent vers le sol.

Dans cette scène, les centres physiques des deux personnages se trouvent sur les pieds visibles, à (0, 16) de leur pivot existant. Les composants de commande, arme, animation, dégâts et recharge sont réutilisés. La maison possède une empreinte de façade et de marches, distincte de son toit et de ses coins transparents. Le comptoir en L possède deux empreintes séparées ; son vide intérieur ne bloque plus le joueur. La profondeur d’affichage suit la position des pieds. Cette correction locale n’a pas déplacé les colliders des personnages dans les autres scènes.

## Sources graphiques

Outil de génération : **`image_gen.imagegen`, intégré à Codex**, sans CLI/API de remplacement. Les sources ci-dessous sont intactes. Les PNG de production, leur provenance, les dimensions et les SHA256 sont dans `godot/scenes/arroyo_seco/saloon_study/assets/`.

| Lot | Image originale | Prompt exact |
| --- | --- | --- |
| Mobilier, chaises et maison | [props-raw.png](props-raw.png) | [props.prompt.json](props.prompt.json) |
| Matériaux de sol | [floors-raw.png](floors-raw.png) | [floors.prompt.json](floors.prompt.json) |
| Murs et clôtures | [walls-raw.png](walls-raw.png) | [walls.prompt.json](walls.prompt.json) |
| Comptoir abaissé, remplaçant la cellule du premier lot | [bar-low-raw.png](bar-low-raw.png) | [bar-low.prompt.json](bar-low.prompt.json) |

Le script `scripts/arena/prepare_saloon_study.py` extrait les silhouettes complètes par composantes connexes pour éviter de couper un objet qui dépasse sa cellule ou d’inclure un fragment du voisin. Il conserve une échelle uniforme, un alpha binaire et un rééchantillonnage au plus proche voisin. Les couleurs cachées sous les pixels transparents sont remises à zéro. Les images originales ne sont pas repeintes. Le lot fournit 12 objets et 8 pièces architecturales, plus 2 matériaux de sol. Les cactus, rochers et charrette réutilisent les ressources V5 à échelle uniforme.

## Reproduire et vérifier

Depuis la racine du dépôt, avec Python + Pillow pour l’export uniquement :

```sh
python3 scripts/arena/prepare_saloon_study.py
godot --headless --path godot --import
godot --headless --path godot --script res://tools/verify_saloon_study.gd
godot --path godot --fixed-fps 60 --script res://tools/verify_saloon_study.gd
```

La dernière commande produit désormais les captures natives et le [rapport actuel](character-warm/verification.json) dans `character-warm/`. Le [rapport de la première zone](verification.json) et ses captures restent conservés ici. Le rendu est forcé pour que la capture aboutisse aussi lorsque macOS masque la fenêtre temporaire. Godot 4.7.2 standard, Compatibility, Apple M1 Pro.

- **Premier lot : 60 contrôles natifs, aucun échec final** : accès depuis le titre, personnages réels, pied physique aligné, maison et toit, passages complets, comptoir, murs, proportions, orientations, mouvement réel, profondeur, tir à travers l’entrée, recharge, dash, réinitialisation et retour au titre. L’essai solo V5 est également rouvert pour vérifier qu’il reste accessible. Les contrôles du lot chaud sont décrits dans son propre dossier.
- Le diagnostic initial a réellement échoué sur les deux symptômes de collision : pieds décalés de 16 unités et coin transparent bloquant à (232, 222). Le [rapport initial](before/footing.json), le [script de diagnostic historique](before/diagnose_saloon_footing.gd) et la géométrie V5 sont conservés dans `before/`. Ce script est une preuve du défaut V5, pas un contrôle devant passer sur l’ancienne carte.
- La préparation des ressources a été relancée : les 23 exports et manifeste ont les mêmes SHA256, relevés dans [reproduction.json](reproduction.json).
- `git diff --check` passe. Aucune instrumentation temporaire de diagnostic n’est laissée dans la scène.

Les tests peuvent signaler un passage bloqué ou un sprite déformé ; ils ne certifient pas la qualité artistique. Les captures ont été examinées pour corriger les raccords des matériaux, le comptoir trop haut et les murs initialement trop plats. La fidélité, la lecture en mouvement et les sensations restent à évaluer par le producteur. La destruction du mobilier et la compatibilité d’une manette physique ne sont pas validées par cette étude.
