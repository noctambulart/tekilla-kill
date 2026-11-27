# Transparence des maisons — correction du 25 novembre 2026

Retour du producteur dans [#60](https://github.com/noctambulart/tequila-kill/issues/60) : la maison ne doit pas devenir transparente lorsque le personnage est devant sa façade.

## Cause et correction

Le tri du bâtiment et le test d’atténuation utilisaient le bas de l’image, jusqu’au bout des marches. Un personnage devant la façade, à côté des marches, était donc classé comme derrière et dessiné sous la maison. La profondeur de la maison suit désormais le bord avant de la façade, 20 unités avant le bas de l’image, conformément à son emprise au sol. La condition du fondu utilise cette même profondeur et conserve la vérification du chevauchement et du monde 2D.

Le dégradé d’opacité reste progressif ; le bâtiment revient à son opacité complète lorsqu’aucun personnage ne passe derrière lui. Les collisions et la carte sont inchangées.

## Preuves natives

Même scène, caméra et position devant la façade : [avant](before-front.png), [après](after-front.png). Les captures ont été examinées. Avant correction, le banc signalait `alpha=0.60000002384186` et un personnage dessiné sous la maison ; après, `HOUSE OCCLUSION: PASS`.

Le [reproducteur ponctuel](reproduce.gd) charge le véritable essai solo avec Garcia éloigné, ce qui isole le déclenchement par Poncho. Il fige les personnages pour la capture. Reproduction après correction :

```sh
godot --path godot --audio-driver Dummy --fixed-fps 60 --script "$PWD/output/arena/2026-11-25-occlusion-fix/reproduce.gd" -- --after
```

Le contrôle permanent `godot/tools/verify_village.gd` ajoute pour chacune des quatre maisons : position libre devant la façade avec le rayon réel, opacité devant, ordre de dessin du personnage, atténuation derrière le toit et retour opaque en repassant devant. La position de contrôle conserve 12 unités de dégagement devant la façade pour le rayon physique 8.

`python3 scripts/godot_tasks.py verifier carte` passe : **130 contrôles, aucun échec**. Le contrôle du saloon de référence passe aussi : **55 contrôles, aucun échec**. [Village](checks/village.log) · [Saloon](checks/saloon_study.log). Les liens Markdown et `git diff --check` passent. Validation des sensations et du rendu en jouant par le producteur ; aucun commit/push effectué.
