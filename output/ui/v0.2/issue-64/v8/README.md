# V0.2 — Cadre ovale resserré, proposition V8

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). Retour sur la [V7](../v7/README.md) : le cadre prend trop de place par rapport à la bouteille. **Proposition à examiner.**

La bouteille conserve ses 88 pixels de hauteur. Le cadre passe d’environ 125 × 166 à 86 × 125 pixels : moins de marge, bordure de bois et filet doré plus fins, moulures simplifiées. Le haut reste sous les commandes existantes. La lecture du liquide reste sans chiffres.

- [Concept interactif](concept.html), [source éditable](concept.template.html), [assemblage](build.py), [manifeste](manifest.json).
- [Contrôle du script réel](render-check.cjs), [rapport](render-check.json), [aperçus](previews/) : les 18 compositions et les trois niveaux passent les contrôles hérités de V5. La scène rapprochée a été examinée visuellement.
- Les particules [V5 validées](../v5/validation.json), la bouteille du porteur et son animation sont conservées. Sources et dépendances de contrôle : [V4](../v4/README.md).

Ces rendus sont des compositions DOM/Canvas sur captures v0.1. Aucun lancement ou changement Godot et aucune génération d’image payante. Le cadre V8 reste à valider dans #64.

```sh
python3 output/ui/v0.2/issue-64/v8/build.py
node --check output/ui/v0.2/issue-64/v8/check-script.js
node output/ui/v0.2/issue-64/v8/render-check.cjs
```
