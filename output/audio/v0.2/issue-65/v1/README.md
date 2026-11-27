# V0.2 — Trois sons rétro locaux, V1

Mission [#65](https://github.com/noctambulart/tequila-kill/issues/65). Le producteur approuve les intentions prise/perte/dernière gorgée et demande des sons de style SNES, au moindre coût de production. **Fichiers préparés, vérifiés et validés par le producteur le 26 novembre 2026** ; [accord consigné](validation.json).

| Événement | Fichier | Intention | Durée |
| --- | --- | --- | --- |
| Prise | [take.wav](take.wav) | Petit tintement ascendant, clair | 0,27 s |
| Perte | [drop.wav](drop.wav) | Contact plus grave, descendant | 0,24 s |
| Bouteille vide | [empty.wav](empty.wav) | Trois notes graves évoquant les dernières gorgées | 0,44 s |

Les sons originaux sont synthétisés localement avec [build.py](build.py), uniquement avec la bibliothèque standard Python. Aucun sample tiers, achat, abonnement, service de génération ou génération audio IA. Le style est une évocation rétro, pas une émulation du matériel SNES. La livraison utilise des WAV PCM16 mono à 22 050 Hz, avec légère quantification du timbre.

Le [manifeste](manifest.json) indique empreintes, durées, crêtes et niveaux RMS. Vérification des fichiers : format et trois durées bornées, aucune boucle, crête à environ −4,15 dBFS, pas d’écrêtage. Point de départ d’intégration conseillé : −3 dB, à ajuster face aux tirs/rechargements existants. L’accord créatif porte sur les fichiers présentés ; l’audibilité et l’équilibre en jeu restent à vérifier dans #66.

Les trois lecteurs sont proposés dans la [maquette V11](../../../../ui/v0.2/issue-64/v11/concept.html), sans lecture automatique. L’intégration aux événements réels appartient à #66 ; aucun fichier Godot n’est modifié ici.

```sh
python3 output/audio/v0.2/issue-65/v1/build.py
```
