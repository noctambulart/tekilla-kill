# V0.2 — Bouteille de tequila et comparaison d’ivresse, V3

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). Proposition issue des retours sur la [V2](../v2/README.md), **à examiner ; aucune référence graphique finale validée**.

## Changements demandés

- Réemploi de la bouteille verte à étiquette rouge et or du jeu, pour la réserve commune et le porteur. Le niveau est composé entre une version de verre éclaircie et l’image pleine ; bouchon et étiquette restent visibles. L’asset original est conservé.
- Oscillation verticale plus rapide : un aller-retour en environ 1,65 seconde, contre 2,51 secondes en V2, à amplitude identique. Valeur proposée pour juger le mouvement, ajustable dans la maquette.
- Trois vues agrandies du même Poncho : **Sobre**, **Quelques gorgées**, **Bien ivre**. Elles utilisent les sprites réels et le même dessin de paillettes que la scène. Aucun effet de possession dans cette comparaison. Ce sont des vues d’examen, pas des éléments supplémentaires du HUD.

La direction approuvée reste celle de la V2 : réserve graphique sans chiffres, ivresse cumulative purement visuelle et plafonnée, conservée après perte, masquée pendant le fantôme puis restaurée. La bouteille et ses éclats de possession sont distincts, indépendants de l’ivresse et présents pendant toute la possession. Le résultat annonce vainqueur ou victoire partagée sans quantité exacte. Les seuils illustratifs ne fixent ni l’équilibrage ni la durée du round.

## Examiner

Le [concept interactif](concept.html) est présenté en conversation. **Animer les effets** lance l’oscillation et les scintillements, y compris les trois comparaisons ; l’animation est arrêtée au chargement. Les situations et les deux cadrages de V2 sont conservés, avec transfert, fantôme puis retour, faible réserve et résultats. Vie, cartouches, visée, dash et commandes actuels restent visibles.

## Sources et vérifications

- [Source éditable](concept.template.html), [assemblage](build.py), [manifeste et empreintes](manifest.json).
- Bouteille : `godot/scenes/intro/assets/bottle.png`, copie réduite dans [assets](assets/). Poncho : sprites `saloon_warm/poncho` du jeu, corps, bras et chapeau.
- Fonds : captures v0.1 réutilisées depuis la V1. Les [aperçus](previews/) sont des compositions de maquette, pas des captures de gameplay v0.2.
- [Contrôle du script réel](render-check.cjs) et [rapport](render-check.json) : 18 compositions, sept images chargées, trois niveaux agrandis rendus, bouteille originale utilisée, indépendance possession/ivresse, suppression/restauration des paillettes pendant/après fantôme, animation et arrêt, absence de score chiffré, égalité, Rejouer et Retour au titre.

La scène rapprochée et les trois niveaux agrandis ont été examinés visuellement. Les contrôles utilisent DOM et Canvas localement ; ils ne constituent pas un essai de Godot et ne vérifient pas toute la mise en page dans le client. Aucun gameplay ni scène Godot modifié, aucun lancement de Godot, aucune génération d’image ou d’audio payante.

Reproduction depuis la racine :

```sh
python3 output/ui/v0.2/issue-64/v3/build.py
node --check output/ui/v0.2/issue-64/v3/check-script.js
# Dépendances de vérification locales uniquement :
npm install --prefix /tmp/tequila-concept-render --no-save --ignore-scripts @napi-rs/canvas@0.1.80 jsdom@22.1.0
node output/ui/v0.2/issue-64/v3/render-check.cjs
```

Les directions de sons placeholders de V1 restent proposées pour [#65](https://github.com/noctambulart/tequila-kill/issues/65), par réemploi ou synthèse locale après validation. Cette V3 ne contient aucun son nouveau. La validation créative est attendue avant clôture de #64 ou démarrage des réalisations suivantes.
