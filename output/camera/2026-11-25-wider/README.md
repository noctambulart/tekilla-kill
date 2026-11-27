# Caméra plus large — 25 novembre 2026

Retour du producteur dans [#46](https://github.com/noctambulart/tequila-kill/issues/46) : davantage de marge aux bords et une caméra plus éloignée lorsque les deux personnages sont côte à côte.

Le zoom rapproché maximal passe de 1,00 à **0,85**, soit des personnages 15 % plus petits à l’écran et environ 18 % de champ supplémentaire en largeur et en hauteur. Dans l’essai solo, la marge du groupe passe de 48–112 à **72–160 unités** selon l’éloignement. La partie prototype utilise la même limite de zoom et une marge de 120 au lieu de 80. L’anticipation du mouvement, le dézoom immédiat, le retour progressif, F et F2 sont conservés.

## Comparaisons natives

Même scène réelle, mêmes positions et fenêtre 1920 × 1080. Les personnages sont figés pour rendre la comparaison reproductible ; les captures utilisent le cadrage adaptatif réel.

| Situation | Avant | Après |
| --- | --- | --- |
| Côte à côte | [Capture](before-close.png), zoom 1,00 | [Capture](after-close.png), zoom 0,85 |
| Éloignés horizontalement | [Capture](before-far.png), zoom 0,484 | [Capture](after-far.png), zoom 0,450 |

[Relevé avant](before.json) · [Relevé après](after.json) · [Banc de capture ponctuel](capture_review.gd).

Vérifié dans la vraie scène : groupe serré, écart horizontal et vertical, proximité du bord de carte, dézoom immédiat après déplacement rapide et retour de la vue d’ensemble. Tous les personnages restent dans la zone sûre. Le zoom vertical passe de 0,349 à 0,317 ; au bord, la limite de rapprochement reste 0,85. Captures rapprochée et éloignée examinées.

`python3 scripts/godot_tasks.py verifier carte partie` passe : import, village **110 contrôles** et partie **48 contrôles**, aucun échec. [Journaux](checks/). `git diff --check` et les liens Markdown passent.

Pour reproduire après réglage :

```sh
godot --path godot --audio-driver Dummy --fixed-fps 60 --script "$PWD/output/camera/2026-11-25-wider/capture_review.gd" -- --after
```

Jouer via F5 → clic pour passer l’intro → **Jouer**. Le producteur doit encore essayer les sensations du nouveau cadrage. Aucun commit/push effectué.
