# V0.2 — Petites étoiles en cloche, proposition V4

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). **Essai créatif à examiner**, suite à la demande d’étoiles qui sortent du personnage en cloche puis tombent. La [V3](../v3/README.md) reste conservée pour comparaison. Aucune référence finale sélectionnée.

## Mouvement proposé

Les petites étoiles à cinq branches partent du haut du corps, montent en s’écartant à gauche et à droite, puis retombent et s’effacent. Chaque trajectoire dure environ 1,35 seconde, avec rotation légère et émissions décalées. La quantité reste plafonnée : aucune étoile pour Sobre, quelques émissions pour Quelques gorgées, davantage pour Bien ivre. Ces valeurs illustrent le mouvement et ne fixent pas l’équilibrage.

Le [concept interactif](concept.html) conserve les situations et les deux cadrages de V3. **Animer les effets** démarre les étoiles dans la scène et les trois vues agrandies sous celle-ci. Le mouvement est à l’arrêt au chargement. Les réglages d’examen permettent de modifier hauteur de cloche, écartement et taille.

La bouteille d’origine et son oscillation accélérée sont conservées. Ses grands éclats de possession restent distincts des petites étoiles d’ivresse. L’ivresse persiste après perte, disparaît pendant le fantôme et revient après récupération. La réserve et le résultat restent sans quantité chiffrée. Les vues agrandies ne sont pas un nouveau HUD.

## Sources et contrôle

- [Source éditable](concept.template.html), [assemblage](build.py), [manifeste et empreintes](manifest.json).
- Sources réutilisées depuis V3 : captures v0.1, bouteille de tequila du jeu et sprites Poncho. Forme et mouvement des étoiles dessinés par code, sans génération IA.
- [Contrôle du script réel](render-check.cjs), [rapport](render-check.json) et [aperçus](previews/) : 18 compositions, trois niveaux, trajectoires montant puis tombant au-dessous du point de départ, départ vers les deux côtés, modification effective du rendu animé, absence d’étoiles dans la vue Sobre, masquage/restauration du fantôme, indépendance de la possession et actions de résultat.

La scène rapprochée et deux instants de la vue Bien ivre ont été examinés visuellement. Contrôle local DOM et Canvas ; mise en page du client et sensations de l’intégration restent à examiner. Ce sont des compositions sur captures, pas un effet de particules déjà intégré dans Godot. Aucun lancement du moteur, aucun changement de gameplay, aucune génération payante.

```sh
python3 output/ui/v0.2/issue-64/v4/build.py
node --check output/ui/v0.2/issue-64/v4/check-script.js
# Dépendances de contrôle dans /tmp uniquement, si nécessaire :
npm install --prefix /tmp/tequila-concept-render --no-save --ignore-scripts @napi-rs/canvas@0.1.80 jsdom@22.1.0
node output/ui/v0.2/issue-64/v4/render-check.cjs
```

La validation créative de #64 reste attendue avant les réalisations suivantes. Les directions sonores placeholders de V1 pour #65 sont conservées.
