# Tequila Kill v0.3 — Livraison validée

Le producteur valide explicitement la version assemblée le **27 novembre 2026** : « Ok on valide cette version, tu peux commiter et tagguer ». Cet accord couvre les corrections essayées de taille des débris, de crosse devant les obstacles, d’ivresse et de ramassage. Suivi et SHA final dans [#29](https://github.com/noctambulart/tequila-kill/issues/29). La livraison est conservée par le [tag annoté v0.3](https://github.com/noctambulart/tequila-kill/tree/v0.3).

## Jouer

Importer `godot/project.godot` dans Godot **4.7.2 standard**, puis **F5 → Jouer**. Depuis la racine : `godot --path godot`. Le duel public oppose Poncho humain à Garcia bot jusqu’au résultat, avec pause et rejeu.

## Contenu retenu

- Carte actuelle d’Arroyo Seco, ses sources graphiques, sprites chauds et caméra commune.
- Caisses, chaises et pots destructibles : 5, 3 et 1 impacts. Les débris libèrent les passages et lignes de tir ; leur taille globale, leurs proportions et leur appui au sol sont conservés.
- Dash au-dessus des petits objets intacts, avec arrivée vérifiée et gestion des interruptions.
- Crosse commune à 30 unités / 90°, même à vide, et contre un obstacle proche qui intercepte le tir. Une crosse retire la même vie qu’une balle, sans cartouche ; les murs restent permanents. Cadence de 0,24 s.
- Vie en quatre segments, récupération sur cinq secondes en fantôme et son à chaque unité terminée.
- Particules d’ivresse progressivement plus nombreuses, jusqu’à environ 24, avec cycle rapide de 0,8 s.
- Ramassage facilité dans un rayon de 28 unités, avec respect du décor et des exclusions après blessure.
- Bouteille, sons et présentation validés en v0.2, pause, résultat, retour au titre et rejeu conservés.

Les réglages et preuves intermédiaires restent dans les lots datés : [livraison initiale](../../gameplay/2026-11-27-v03/README.md), [débris et crosse](../../gameplay/2026-11-27-v03-review/README.md), [ivresse](../../gameplay/2026-11-27-ivresse/README.md), [ramassage](../../gameplay/2026-11-27-ramassage/README.md). Leurs mentions d’attente de validation décrivent leur état au moment de ces livraisons ; l’accord final est consigné ici.

## Vérification finale

**14 suites réussies, aucune en échec**, sur une copie isolée du projet complet. Elles couvrent l’introduction, les déplacements, le tir, la recharge, la carte, le saloon, les deux jeux de sprites, la boucle de partie, les pertes de bouteille, l’étourdissement, le parcours public, la v0.3 et les corrections de review.

```sh
python3 scripts/godot_tasks.py verifier
python3 scripts/check_markdown_links.py
```

[Validation et résultats par suite](validation.json). Les rapports JSON de cette dernière exécution sont conservés dans `verification/`. [Empreintes SHA-256 des sources et ressources Godot livrées](runtime-sha256.json). Les captures natives précédemment examinées restent dans les lots liés ci-dessus. La compatibilité avec les modèles de manette physiques reste un essai matériel distinct ; les contrôles automatisés simulent leurs événements.

Le commit conserve aussi les assets, sources et preuves des étapes précédentes encore non commitées, pour permettre de retrouver ce jeu complet. Les caches Godot, fichiers temporaires, archives originales et journaux locaux restent exclus selon `.gitignore`. Le cadrage documentaire de la v0.4 est conservé ; son implémentation ne fait pas partie de cette livraison. Son prochain travail reste le [grill et les concepts du salon #67](https://github.com/noctambulart/tequila-kill/issues/67).
