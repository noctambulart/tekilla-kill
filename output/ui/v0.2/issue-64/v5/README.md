# V0.2 — Étoiles à départs variés, proposition V5

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). **Particules d’ivresse validées par le producteur le 26 novembre 2026**, après le retour sur la [V4](../v4/README.md) : faire sortir les étoiles d’endroits différents.

Les points d’émission sont répartis sur la silhouette : chapeau, épaules, torse et côtés. Chaque réémission choisit un autre point, avec un petit décalage et une vitesse variée. Le point de départ reste stable pendant toute la trajectoire. Les étoiles montent en cloche puis retombent ; elles s’effacent près des pieds pour préserver les indicateurs existants.

Le [concept interactif](concept.html) conserve les trois niveaux animables, les réglages de V4, la bouteille et ses effets de possession distincts. Aucun changement de règle, de score ou de gameplay. Cette itération reste une maquette sur captures v0.1, sans lancement de Godot ni génération d’image payante.

- [Source éditable](concept.template.html), [assemblage](build.py), [manifeste et empreintes](manifest.json).
- [Contrôle du script réel](render-check.cjs) et [rapport](render-check.json) : 18 compositions et trois niveaux ; origines réparties sur la silhouette, variation au renouvellement, stabilité en vol, montée puis chute, animation effective, absence d’étoiles pour Sobre, fantôme puis retour et indépendance de la possession.
- [Aperçus](previews/) : deux instants de la vue agrandie Bien ivre examinés visuellement. Contrôle local DOM et Canvas ; la validation dans le client puis dans Godot reste distincte.
- Sources, contraintes conservées et installation des dépendances temporaires de contrôle : [livraison V4](../v4/README.md).

```sh
python3 output/ui/v0.2/issue-64/v5/build.py
node --check output/ui/v0.2/issue-64/v5/check-script.js
node output/ui/v0.2/issue-64/v5/render-check.cjs
```

Référence retenue pour les particules d’ivresse : **V5**, avec les départs variés et les trajectoires en cloche. Accord explicite du producteur : « C’est mieux partons la dessus pour les particules. » Voir [la validation consignée](validation.json). Les valeurs numériques de la maquette restent des réglages de présentation à adapter et vérifier lors de l’intégration Godot.

Cette validation porte sur les particules ; elle ne vaut pas validation de l’ensemble bouteille, résultat et sons. #64 reste ouverte pour ces éléments.
