# V0.2 — Bouteille au contact du bord intérieur, proposition V10

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). Correction de [V9](../v9/README.md) : aucun dépassement du cadre ; seuls les angles peuvent toucher ou chevaucher très légèrement le bord intérieur. **Bouteille fixe et cadre V10 validés par le producteur le 26 novembre 2026.**

La bouteille passe de 132 à 100 pixels, dans le cadre V8 conservé à environ 86 × 125 pixels. Elle reste entièrement à l’intérieur du contour extérieur ; ses angles inférieurs effleurent le bord intérieur. Le réglage est limité à une petite plage de 96 à 104 pixels.

- [Concept interactif](concept.html), [source éditable](concept.template.html), [assemblage](build.py), [manifeste](manifest.json).
- [Contrôle du script réel](render-check.cjs), [rapport](render-check.json), [aperçus](previews/) : 18 compositions et trois niveaux. Contrôle géométrique des pixels visibles de la bouteille à la taille proposée : tous restent dans l’ovale extérieur et seul un léger chevauchement de l’ovale intérieur est mesuré. Scène rapprochée examinée visuellement.
- [Particules V5 validées](../v5/validation.json), porteur et animation conservés. Sources et dépendances de contrôle : [V4](../v4/README.md).

Composition DOM/Canvas sur captures v0.1 ; aucun lancement ou changement Godot, aucune génération d’image payante. Accord du producteur : « Ok partons la dessus ». Voir [la validation](validation.json). Cet accord retient la bouteille fixe et son cadre ; les particules V5 restent validées et #64 reste ouverte pour les autres éléments. L’intégration Godot est à réaliser.

```sh
python3 output/ui/v0.2/issue-64/v10/build.py
node --check output/ui/v0.2/issue-64/v10/check-script.js
node output/ui/v0.2/issue-64/v10/render-check.cjs
```
