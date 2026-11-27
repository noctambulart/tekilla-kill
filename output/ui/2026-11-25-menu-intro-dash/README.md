# Menu, introduction et dash — retour v0.1

Mission [#63](https://github.com/noctambulart/tequila-kill/issues/63), suite à la demande du producteur du 25 novembre 2026.

Le titre conserve **Jouer**, **Revoir l’introduction** et **Quitter**. Jouer ouvre l’essai solo actif, avec le focus clavier/manette sur ce bouton au retour au titre. Les scènes de test, visite, saloon étalon et partie prototype restent accessibles directement dans Godot sans boutons publics.

Un clic gauche n’importe où sur l’image passe l’introduction. Le clic est consommé et ne lance pas la partie en arrivant au titre. Clavier, manette, fin naturelle et relecture sont conservés.

Une recharge déjà lancée continue pendant le dash, sans pause ni remise à zéro du temps de cartouche. Les nouveaux appuis pendant le dash restent ignorés ; le tir après dash demande toujours un nouvel appui. Les annulations à zéro PV, perte de focus et déconnexion restent vérifiées. Cette demande remplace la règle antérieure d’interruption de #6/#21.

## Vérification

Les tests utilisent les vraies scènes et le dispatcher d’entrée Godot. Les scénarios ajoutés ont échoué avant la correction : [intro avant](before-intro.log), [recharge avant](before-reload.log).

Après correction :

- `python3 scripts/godot_tasks.py verifier` : toutes les étapes passent. [Journaux](checks/). Déplacement 53, tir 47, recharge 53, village 110, saloon 55, sprites 31 pour chaque lot, partie 48 contrôles ; introduction et import réussis.
- `python3 scripts/godot_tasks.py capturer intro` : contrôle natif réussi, dix captures. [Journal natif](intro-native.log). Fin naturelle, clavier/manette, clic au début/milieu/fin, absence d’activation accidentelle, trois boutons seulement et lancement/retour de l’essai solo vérifiés.
- [Capture native du titre](title.png), examinée en 640 × 360.
- `python3 scripts/check_markdown_links.py` et `git diff --check` passent.

Le contrôle du rechargement vérifie une cartouche ajoutée pendant un dash avec son délai déjà entamé, puis le remplissage jusqu’au plein malgré un tir maintenu depuis le dash. Un nouvel appui de recharge pendant le dash sans recharge en cours ne déclenche rien après sa fin.

Les manettes sont simulées ; l’essai sur matériel physique et les sensations restent à examiner par le producteur. Aucun commit/push effectué.
