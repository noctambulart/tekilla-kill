# V0.2 — Bouteille graphique, ivresse et cible, proposition V2

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). **Direction validée après entretien ; maquette V2 à examiner.** Les deux pistes chiffrées de la [V1](../v1/README.md) sont écartées. Aucune référence graphique finale n’est encore validée et la mission reste ouverte.

## Direction retenue

- Bouteille commune fixe en haut : le liquide matérialise la réserve. Aucun pourcentage ni barre auxiliaire.
- Ivresse cumulative : petits scintillements autour du corps, d’abord absents puis plus présents lorsque le personnage a davantage bu. Effet plafonné, purement visuel, conservé après perte de bouteille.
- Fantôme : aucune paillette d’ivresse ; la quantité bue est conservée et l’effet revient au même niveau après récupération.
- Porteur : bouteille oscillant verticalement au-dessus de la tête et éclats plus francs autour d’elle. Ce marquage dure pendant toute la possession, disparaît à la perte et ne dépend pas de l’ivresse. Le porteur doit être la cible la plus évidente.
- Résultat : vainqueur ou victoire partagée, Rejouer et Retour au titre, sans quantités chiffrées. La règle de victoire à la quantité réellement bue reste inchangée.

Vie, cartouches, visée, dash et commandes actuels sont conservés. Aucun portrait, nouvelle arme, compétence ou changement de sensations n’est introduit.

## Examiner la maquette

Le [fragment interactif](concept.html) est présenté dans la conversation de production. Les situations illustrent départ, Poncho porteur, transfert à Garcia, Poncho fantôme puis de retour, faible réserve, victoire, égalité et retour au titre. Les deux cadrages sont proposés. **Animer les effets** lance volontairement l’oscillation et les scintillements ; ils sont à l’arrêt au chargement. Changer de situation arrête l’animation, afin de comparer les états.

Le transfert à Garcia conserve les mêmes quantités illustratives : Poncho reste plus ivre, mais Garcia reçoit immédiatement le marquage de possession. Le passage en fantôme masque l’ivresse de Poncho ; le retour la restaure. Les deux catégories de paillettes diffèrent par leur forme, leur taille et leur emplacement.

Les niveaux de liquide et seuils d’ivresse sont des exemples pour juger la lecture. Ils ne fixent pas l’équilibrage ni la durée du round. Aucune quantité exacte n’est affichée dans le produit, y compris dans le résultat et la description accessible du rendu.

## Fichiers et vérifications

- [Source éditable](concept.template.html), [assemblage](build.py), [manifeste et empreintes](manifest.json).
- [Aperçus locaux](previews/) : compositions sur captures existantes, **pas des captures d’une partie Godot implémentée**.
- [Contrôle du script réel](render-check.cjs) et [rapport](render-check.json) : 18 compositions (9 situations × 2 cadrages), trois captures chargées, résultat sans scores chiffrés, séparation possession/ivresse, disparition puis retour des paillettes après fantôme, oscillation verticale, arrêt de l’animation, égalité, Rejouer et Retour au titre.
- Captures et copies JPEG de référence réutilisées depuis la V1 ; les originaux sont inchangés. La nouvelle bouteille et ses effets sont dessinés par code dans la maquette, sans génération d’image IA.

Les aperçus rapprochés et éloignés ont été examinés. Le contrôle local utilise DOM et Canvas ; il ne vaut pas essai dans Godot. La mise en page CSS du résultat reste à examiner dans la conversation, puis la lisibilité en mouvement sera évaluée après intégration. Aucun fichier de gameplay ni aucune scène Godot n’ont été modifiés et Godot n’a pas été lancé.

Reproduction depuis la racine :

```sh
python3 output/ui/v0.2/issue-64/v2/build.py
node --check output/ui/v0.2/issue-64/v2/check-script.js
# Dépendances de contrôle locales uniquement, si /tmp a été nettoyé :
npm install --prefix /tmp/tequila-concept-render --no-save --ignore-scripts @napi-rs/canvas@0.1.80 jsdom@22.1.0
node output/ui/v0.2/issue-64/v2/render-check.cjs
```

## Sons placeholders

Les directions de prise, perte et bouteille vide de la V1 restent proposées pour [#65](https://github.com/noctambulart/tequila-kill/issues/65) : tintement bref de prise, contact plus grave pour la perte, petite conclusion pour la dernière gorgée. Les fichiers seront produits par réemploi ou synthèse locale après validation des concepts, sans génération audio payante. Aucun fichier sonore n’est créé ici.
