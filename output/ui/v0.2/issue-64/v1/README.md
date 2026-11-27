# V0.2 — Concepts bouteille et résultat, proposition V1

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). **Propositions écartées par le producteur.** Elles sont conservées comme historique de l’exploration. La [V2](../v2/README.md) reprend la direction validée après entretien : bouteille graphique, ivresse et marquage du porteur sans affichage de quantités précises. Les autres réalisations de la v0.2 restent conditionnées à la validation de cette mission.

## Deux pistes

- **Scores près des joueurs** : réserve commune sous les commandes, pourcentages bus sous les indicateurs actuels de chaque personnage. Le score reste associé au personnage dans l’action.
- **Scores avec la réserve** : mêmes indicateurs actuels près des personnages, mais les deux pourcentages bus sont regroupés avec la réserve commune. Aucune interface fixe à portraits n’est introduite.

Les deux pistes montrent les cadrages rapproché et éloigné, bouteille au sol, Poncho puis Garcia porteur, Poncho fantôme, victoire de Poncho, victoire partagée et retour au titre. Les boutons du résultat simulent localement le rejeu et le retour au titre. Il ne s’agit pas d’une partie Godot ni d’un bot jouable.

## Contenu conservé et ajouts proposés

Vie, cartouches, dash, visée et commandes proviennent des captures de l’essai solo. Le libellé de cible est remplacé par J2 et les cartouches existantes sont illustrées pour Garcia actif. Les seuls nouveaux éléments de partie sont la réserve commune, les scores personnels, la bouteille et son repère de possession ; le résultat forme un écran distinct après la fin du round.

La bouteille de l’introduction est réutilisée comme référence visuelle de maquette. Son adaptation définitive aux dimensions du jeu devra suivre la référence retenue. Le fantôme est une simulation graphique translucide/désaturée de la présentation existante, avec vie partiellement restaurée ; aucune nouvelle logique de récupération n’est créée ici.

Les quantités sont **illustratives** : 28 % + 25 % + 47 % de réserve, puis 28 % + 31 % + 41 %. Le résultat montre 58 % / 42 % ou 50 % / 50 %. Ces états respectent la conservation du contenu initial et ne fixent ni vitesse de consommation ni équilibrage.

## Direction sonore proposée

Les fichiers seront produits dans [#65](https://github.com/noctambulart/tequila-kill/issues/65), après validation des concepts :

| Événement | Direction de placeholder local |
| --- | --- |
| Prise | Petit tintement sec, montant, immédiatement reconnaissable. |
| Perte | Contact bref plus grave, distinct du tir et de la recharge. |
| Bouteille vide | Dernière petite gorgée ou double tintement de conclusion, sans longue musique. |

Réemploi de sons à provenance connue ou synthèse locale simple, sans génération audio IA ni service payant. Aucun lot sonore n’est produit dans cette mission de concepts.

## Sources et fichiers

- [Manifeste](manifest.json) : sources, SHA-256, états et statut de validation.
- [Capture rapprochée d’origine](../../../../camera/2026-11-25-wider/after-close.png) et [capture éloignée](../../../../camera/2026-11-25-wider/after-far.png).
- [Bouteille d’introduction](../../../../../godot/scenes/intro/assets/bottle.png) et [titre courant](../../../2026-11-25-menu-intro-dash/title.png).
- [Fragment interactif autonome en ressources](concept.html), [source éditable](concept.template.html) et [assemblage](build.py). Le fragment est également présenté dans la conversation de production.
- [Aperçus locaux](previews/) : rendus des deux pistes et des états de jeu aux deux cadrages. Ces compositions sont des **maquettes sur captures**, pas des captures d’une v0.2 implémentée.
- [Contrôle de rendu](render-check.cjs) et [rapport](render-check.json).

## Contrôles et limites

Le script réel de la maquette a été exécuté dans un DOM local avec un moteur Canvas, sans navigateur ni lancement de Godot : **28 compositions** (2 pistes × 2 cadrages × 7 états), 4 ressources chargées, visibilité du résultat, égalité 50/50, Rejouer et Retour au titre contrôlés. Les aperçus de jeu ont été examinés ; des corrections ont évité le recouvrement des cartouches au dézoom et un fond rectangulaire sur le fantôme. Les scores et la réserve sont synchronisés dans chaque état.

La syntaxe JavaScript et le format du fragment sont vérifiés. Le fragment fait moins de 1 Mo et ne fait aucun appel API. L’aperçu par navigateur intégré sur localhost était inaccessible ; le contrôle visuel a donc porté sur les compositions Canvas locales. La disposition CSS du résultat reste à apprécier dans l’aperçu interactif de la conversation, et la lisibilité en mouvement ne sera validée qu’après intégration.

Reproduction depuis la racine du dépôt :

```sh
python3 output/ui/v0.2/issue-64/v1/build.py
node --check output/ui/v0.2/issue-64/v1/check-script.js
# Pour le contrôle local de rendu, dépendances installées uniquement sous /tmp :
npm install --prefix /tmp/tequila-concept-render --no-save --ignore-scripts @napi-rs/canvas@0.1.80 jsdom@22.1.0
node output/ui/v0.2/issue-64/v1/render-check.cjs
```

Les captures originales sont préservées ; leurs copies JPEG réduites servent uniquement à l’aperçu interactif. Aucun script de gameplay, aucune scène Godot et aucune configuration du projet n’ont été modifiés par cette proposition.
