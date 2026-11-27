# V0.2 — Bouteille agrandie devant le cadre, proposition V9

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). Retour sur [V8](../v8/README.md) : agrandir la bouteille dans le cadre, avec chevauchement de la bordure autorisé. **Proposition à examiner.**

La bouteille passe de 88 à 132 pixels de hauteur. Le cadre conserve ses dimensions et sa position V8 (environ 86 × 125 pixels). La bouteille est dessinée devant la bordure, sans découpe ovale ; elle la chevauche en haut et en bas. Le réglage de taille agit désormais sur la bouteille seule, de 112 à 140 pixels, indépendamment du cadre.

- [Concept interactif](concept.html), [source éditable](concept.template.html), [assemblage](build.py), [manifeste](manifest.json).
- [Contrôle du script réel](render-check.cjs), [rapport](render-check.json), [aperçus](previews/) : 18 compositions et trois niveaux vérifiés. Scène rapprochée examinée visuellement.
- Les [particules V5 validées](../v5/validation.json), le porteur et son animation sont conservés. Sources et dépendances de contrôle : [V4](../v4/README.md).

Composition DOM/Canvas sur captures v0.1. Aucun lancement ni changement Godot, aucune génération d’image payante. La bouteille V9 reste à valider dans #64.

```sh
python3 output/ui/v0.2/issue-64/v9/build.py
node --check output/ui/v0.2/issue-64/v9/check-script.js
node output/ui/v0.2/issue-64/v9/render-check.cjs
```
