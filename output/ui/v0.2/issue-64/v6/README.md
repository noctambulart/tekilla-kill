# V0.2 — Bouteille fixe harmonisée, proposition V6

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). Réponse au retour : la bouteille fixe dénote par rapport à celle au-dessus de la tête. **Ajustement de bouteille à examiner.**

La maquette utilisait déjà la même image pour les deux bouteilles, mais la réserve fixe mesurait 130 pixels contre environ 69 pour le porteur en cadrage rapproché. La V6 ramène la réserve à 88 pixels et applique exactement le même halo chaud aux deux emplacements, via la fonction commune `markedBottle`. Dessin, palette et composition du niveau de liquide restent partagés. La bouteille fixe est encore légèrement plus grande pour lire la réserve, et son réglage permet d’essayer de 68 à 104 pixels.

Le [concept interactif](concept.html) conserve les situations pleine, intermédiaire, presque vide et vide, sans pourcentage, ainsi que les cadrages et l’animation. Les fonctions de particules validées de [V5](../v5/README.md) sont conservées à l’identique ; [l’accord](../v5/validation.json) reste limité aux particules.

- [Source éditable](concept.template.html), [assemblage](build.py), [manifeste et empreintes](manifest.json).
- [Contrôle du script réel](render-check.cjs), [rapport](render-check.json) et [aperçus](previews/) : 18 compositions et trois niveaux d’ivresse ; mêmes contrôles de trajectoire, fantôme, possession, animation et résultat que V5.
- Scène rapprochée à réserve intermédiaire et faible examinée visuellement. Contrôle DOM et Canvas local ; ces images sont des compositions sur captures, pas un gameplay v0.2 implémenté. Aucun lancement ni changement Godot et aucune génération d’image payante.
- Sources et dépendances de contrôle : [V4](../v4/README.md).

```sh
python3 output/ui/v0.2/issue-64/v6/build.py
node --check output/ui/v0.2/issue-64/v6/check-script.js
node output/ui/v0.2/issue-64/v6/render-check.cjs
```

#64 reste ouverte : la bouteille et l’ensemble des concepts attendent l’accord du producteur. La référence de particules retenue reste V5.
