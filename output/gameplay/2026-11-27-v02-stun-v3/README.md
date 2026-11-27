# Essai v0.2 · Étourdissement à 0,8 s

27 novembre 2026. À la demande du producteur, étourdissement porté de **0,65 à 0,8 s**. Projection conservée à **150 unités en 0,22 s**. Les autres comportements de l’[essai précédent](../2026-11-27-v02-stun-v2/README.md) sont conservés.

Vérification : `python3 scripts/godot_tasks.py verifier partie --output /private/tmp/tequila-stun-v3 --timeout 180`. Quatre suites sans rendu, **497 assertions** : partie 69, pertes 330, étourdissement 47, parcours public 51. Reprise bloquée à 0,79 s puis possible à 0,8 s ; combat, recharge, bot, pause, fantôme et rejeu couverts. [Résumé](checks/summary.json), rapports et journaux dans les sous-dossiers de ce lot.

Fermer l’ancienne fenêtre puis relancer le jeu et choisir **Jouer**. Suivi et validation des sensations dans [#24](https://github.com/noctambulart/tequila-kill/issues/24) et [#26](https://github.com/noctambulart/tequila-kill/issues/26).

## Validation du producteur

Le 27 novembre 2026, après essai : **« Ok on valide la v0.2 🍾 ! »**. Cet accord valide l’ensemble assemblé et le réglage final de ce lot. Accord, clôture des missions et transition vers v0.3 consignés dans [#26](https://github.com/noctambulart/tequila-kill/issues/26).
