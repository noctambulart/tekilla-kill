# V0.2 — Bouteille dans un tableau ovale, proposition V7

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). Retour du producteur : l’écart tient à l’incrustation plutôt qu’à la taille ; essayer un cadre de tableau ovale. **Proposition à examiner.**

La réserve fixe est placée dans un cadre ovale en bois patiné avec une bordure dorée et un fond chaud. Le cadre est dessiné à petite résolution, avec relief et ombre, puis agrandi sans lissage. Il ancre la réserve dans l’interface au lieu de laisser la bouteille seule sur le décor. La bouteille conserve son image et son niveau de liquide sans chiffres ; son halo de possession ne figure pas dans le tableau. Le cadre reste sous les commandes du haut lorsque sa taille est ajustée.

Le [concept interactif](concept.html) conserve les situations et les deux cadrages. Les particules validées de [V5](../v5/README.md), leur [accord](../v5/validation.json) et les effets du porteur sont conservés.

- [Source éditable](concept.template.html), [assemblage](build.py), [manifeste](manifest.json).
- [Contrôle du script réel](render-check.cjs), [rapport](render-check.json), [aperçus](previews/) : 18 compositions et trois niveaux. Trajectoires, fantôme, possession, animation et commandes de résultat contrôlés comme dans V5.
- La scène rapprochée avec cadre a été examinée visuellement. Le rendu est une composition DOM/Canvas sur captures v0.1, pas une capture de gameplay v0.2. Aucun lancement ou changement Godot et aucune génération d’image payante.
- Sources et dépendances de vérification : [V4](../v4/README.md).

```sh
python3 output/ui/v0.2/issue-64/v7/build.py
node --check output/ui/v0.2/issue-64/v7/check-script.js
node output/ui/v0.2/issue-64/v7/render-check.cjs
```

Le tableau ovale reste à valider ; la référence de particules validée reste V5. #64 reste ouverte.
