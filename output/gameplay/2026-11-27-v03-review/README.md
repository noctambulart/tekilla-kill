# v0.3 — Corrections après essai du producteur

27 novembre 2026, suivi dans [#29](https://github.com/noctambulart/tequila-kill/issues/29). Ce lot corrige la taille des objets cassés et étend la substitution du tir par une crosse aux obstacles proches. Il prolonge la [livraison initiale](../2026-11-27-v03/README.md) ; la validation du jalon reste à donner.

## Demandes et choix confirmés

Le producteur signale des sprites cassés trop petits et demande une crosse lorsqu’un mur ou objet destructible proche intercepte le tir. Après clarification, il choisit :

- une taille globale équivalente à l’intact pour les objets cassés ;
- les mêmes dégâts qu’une balle sur un objet destructible ; une crosse sans dégâts devant un mur permanent.

## Corrections

La taille des débris était ajustée uniquement à la largeur de l’intact. Une chaise verticale de **15 × 25 unités** devenait ainsi un amas de **15 × 11,8 unités**. Le nouveau calcul considère l’enveloppe visible, sans les marges transparentes : sa dimension dominante et sa surface englobante ne diminuent plus. L’échelle reste uniforme, les proportions du dessin sont conservées et le bas visible reste au même point du sol. L’ombre est réajustée. La même chaise devient **25 × 19,6 unités**, avec un étalement latéral naturel. Caisses et pots bénéficient aussi de cette correction ; aucun PNG n’est modifié.

La recherche de crosse ne considérait que les personnages. Elle examine maintenant aussi le **premier obstacle sur le trajet réel de la balle**, dans les **30 premières unités**, en utilisant les mêmes couches physiques et exclusions du tireur. Le coup ne consomme aucune cartouche, même à vide. Il applique **25 dégâts** aux objets cassables, partage la cadence de **0,24 s**, peut interrompre la recharge par un nouvel appui et reprend le tir au maintien lorsque le passage est libéré. Les murs permanents reçoivent le geste et son effet sonore, sans dégâts.

Un objet proche sur le côté qui n’intercepte pas le tir ne déclenche pas de crosse. Un mur à plus de 30 unités laisse partir une balle. L’attaque respecte la première obstruction : un adversaire devant un mur reste une cible ; un mur devant l’adversaire l’empêche d’être frappé à travers. Les personnages conservent la portée et l’arc de 90° validés. La règle de substitution est partagée avec Garcia.

Fichiers : [objets cassables](../../../godot/scenes/arroyo_seco/breakable_prop.gd), [revolver commun](../../../godot/scenes/character/revolver.gd), [contrôle de review](../../../godot/tools/verify_v03_review.gd). Le test de manette historique utilise désormais une zone libre pour vérifier le tir ; les obstacles proches ont leur contrôle distinct.

## Vérification

**728 contrôles sans interface réussis** sur le combat et la partie : tir 47, recharge 53, boucle de partie 69, bouteille 330, étourdissement 47, parcours public v0.2 51, v0.3 109, corrections de review 22. **34 contrôles avec rendu natif réussis**, dont **12 captures**. Godot 4.7.2 standard / Compatibility, Apple M1 Pro, 1920 × 1080.

Le test de reproduction initial échoue bien devant le mur et la caisse, puis passe après correction. Les comparaisons mesurent la taille visible et l’appui au sol des objets de la vraie carte. Les captures ont été examinées. Les fixtures de review figent les joueurs et neutralisent la pause de perte de focus pour permettre les captures en arrière-plan ; le jeu public conserve sa pause automatique.

Rapports : [sans interface](verification-headless.json), [rendu natif](verification-rendered.json). Les journaux et la reproduction initiale sont dans `checks/`. L’erreur macOS connue `get_system_ca_certificates` peut apparaître dans le sandbox ; les exécutions finales n’ont aucune erreur de script.

```sh
python3 scripts/godot_tasks.py verifier combat partie
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_v03_review.gd
godot --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_v03_review.gd
```

## Comparaisons natives

| Objet | Intact | Cassé |
| --- | --- | --- |
| Caisse de rue | [Avant](street-crate-intact.png) | [Après](street-crate-broken.png) |
| Pot de l’épicerie | [Avant](shop-pot-intact.png) | [Après](shop-pot-broken.png) |
| Chaise nord | [Avant](saloon-west-n-intact.png) | [Après](saloon-west-n-broken.png) |
| Chaise ouest | [Avant](saloon-west-w-intact.png) | [Après](saloon-west-w-broken.png) |
| Chaise est | [Avant](saloon-west-e-intact.png) | [Après](saloon-west-e-broken.png) |

[Crosse devant un mur](wall-melee.png) et [contre une caisse](crate-melee.png).

Pour essayer : **F5 → Jouer**, ou `godot --path godot`. Les sensations et le rendu restent à apprécier par le producteur ; la manette physique reste à vérifier. Aucun commit ni push dans cette correction.
