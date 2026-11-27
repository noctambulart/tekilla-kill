# V0.2 — Fantôme gris, résultat provisoire et sons rétro, V11

Mission [#64](https://github.com/noctambulart/tequila-kill/issues/64). **Référence globale V11 validée par le producteur le 26 novembre 2026**, accord consigné dans [validation.json](validation.json). Retours intégrés :

- Porteur et bouteille au sol : présentation validée.
- Fantôme : réduire fortement les couleurs, proche du noir et blanc.
- Résultat temporaire : afficher le pourcentage du gagnant ; refonte de cet écran dans une version ultérieure.
- Sons : intentions validées, production locale économique avec une esthétique de type SNES.

La bouteille fixe et son cadre [V10 validés](../v10/validation.json) sont conservés. Les étoiles gardent la forme et les départs variés [V5 validés](../v5/validation.json), avec les réglages envoyés par le producteur : rythme de bouteille 4 rad/s, hauteur de cloche 1,1, écartement 1,05 et taille d’étoile 1,1.

## Examiner

Le [concept interactif](concept.html) démarre sur Poncho fantôme, rendu en gris neutre à partir du masque de ses sprites, sans étoiles d’ivresse. Le retour restaure couleurs et ivresse. Examiner aussi les deux cadrages. Au résultat, Poncho ou Garcia peut gagner ; seule la part de bouteille bue par le gagnant est affichée. En égalité, les deux gagnants ont « 50 % chacun ». Aucun pourcentage pendant le round.

Le pourcentage est la quantité bue par le gagnant divisée par le contenu initial de la bouteille, multipliée par cent. La maquette affiche au maximum une décimale ; l’arrondi est uniquement visuel, la victoire et l’égalité restent calculées sur les quantités exactes. Les scores illustratifs ne fixent pas l’équilibrage.

Trois lecteurs sous la scène présentent les [sons rétro locaux](../../../../audio/v0.2/issue-65/v1/README.md), sans lecture automatique. Aucun service de production audio payant. Le producteur a confirmé le fantôme, le résultat et les trois sons, en complément des références déjà retenues.

## Sources et vérifications

- [Source éditable](concept.template.html), [assemblage](build.py), [manifeste](manifest.json).
- [Contrôle du script réel](render-check.cjs) et [rapport](render-check.json) : 20 compositions (10 situations × 2 cadrages), pourcentages uniquement au résultat, victoire de chacun, égalité, corps du fantôme en gris neutre, masquage puis retour de l’ivresse, géométrie bouteille/cadre, trois fichiers audio embarqués sans lecture automatique et actions de résultat.
- [Aperçus](previews/) : fantômes rapproché et éloigné examinés visuellement. Le contrôle DOM et Canvas de l’agent ne vérifie pas tout le rendu CSS du client ni la lecture audible dans ce client. Les propriétés et textes du résultat sont contrôlés ; le producteur a donné son accord créatif en conversation.
- Sources réutilisées depuis V10 : captures v0.1, bouteille et sprites du jeu. Ce sont des compositions de maquette, pas une partie v0.2 implémentée. Aucun lancement ni changement de gameplay Godot.

```sh
python3 output/audio/v0.2/issue-65/v1/build.py
python3 output/ui/v0.2/issue-64/v11/build.py
node --check output/ui/v0.2/issue-64/v11/check-script.js
node output/ui/v0.2/issue-64/v11/render-check.cjs
```

Les dépendances temporaires du contrôle sont celles de [V4](../v4/README.md). Les concepts et fichiers sonores sont validés pour clôture de #64 et #65 ; le branchement aux états réels et l’équilibre sonore en jeu restent à réaliser dans #66. Cette validation ne lance pas automatiquement une mission et ne valide pas la v0.2 assemblée.
