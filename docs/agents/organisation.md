# Organisation de la production

Organisation validée avec le producteur le 21 novembre 2026. Elle sert de référence aux conversations qui contribuent à Tequila Kill. Le premier objectif collectif est une petite version cohérente qu'une autre personne puisse lancer, comprendre et jouer jusqu'au bout. Des assets provisoires peuvent servir aux étapes intermédiaires. Le [contexte de reprise et l'objectif de livraison](../concept.md) guident le cadrage. L'organisation sera ajustée à partir de cette expérience.

## Responsabilités

| Rôle ou conversation | Responsabilité |
| --- | --- |
| Producteur humain | Porte la vision et la direction créative, fixe les priorités, choisit les missions à lancer et arbitre les règles, la direction artistique et le périmètre. Valide les résultats créatifs en jouant. |
| Production | Coordonne le travail, prépare les missions dans les Issues avec les spécialistes, suit les dépendances, recommande leur affectation et présente les résultats et arbitrages au producteur. |
| Game design | Propose et précise les règles, les comportements, l'équilibrage et les critères permettant d'évaluer l'expérience en jouant. |
| Direction artistique et assets | Définit la cohérence visuelle et produit les graphismes et animations avec leurs contraintes de livraison et d'intégration. |
| Développement Godot | Évalue la faisabilité, implémente le code, intègre les règles et les assets validés, vérifie le fonctionnement technique et livre une version jouable. |

L'agent interlocuteur reste responsable de la réalisation et de l'intégration auprès du producteur. Les spécialités, conversations dédiées, sous-agents et skills sont des moyens d'organiser ce travail. Le producteur porte l'intention et arbitre les choix créatifs ; l'agent prend en charge les décisions techniques courantes.

## Issues et conversations

Les tâches et spécifications vivent dans les Issues GitHub, selon les [conventions du tracker](issue-tracker.md). Chaque mission d'exécution part d'une Issue contenant ses instructions, son objectif, ses contraintes, ses dépendances et ses critères d'acceptation. Consigner les résultats et décisions utiles à la reprise dans l'Issue et les documents de référence concernés.

La Production s'appuie sur les Issues pour préparer et affecter les missions. Les conversations servent à les réaliser et à discuter des décisions. Les échanges exploratoires peuvent rester libres jusqu'à ce qu'une mission soit définie.

L'organisation des conversations est hybride :

- Production, Game design et Direction artistique constituent des points de référence durables.
- Une mission peut avancer dans une conversation spécialisée existante ou disposer d'une conversation dédiée, quelle que soit sa discipline.
- La Production recommande une conversation dédiée lorsque la mission demande beaucoup d'exploration, risque d'encombrer les autres échanges ou peut avancer indépendamment. Le producteur garde le choix.
- Une conversation dédiée conserve la mission jusqu'à sa validation et aux corrections éventuelles. Une mission peut regrouper plusieurs petites Issues étroitement liées.

« Développement Godot » désigne la spécialité chargée du code et de l'intégration. Une mission de création graphique relève de la Direction artistique ; son import et son branchement dans le jeu peuvent faire l'objet d'une Issue d'intégration distincte.

## Lancement et autonomie

La Production prépare les missions et recommande où les réaliser. Le producteur choisit celles à lancer et maîtrise le nombre de travaux simultanés.

Une fois la mission lancée, l'agent prend les décisions d'exécution dans le cadre de l'Issue et avance jusqu'à un résultat vérifié. Il rend compte des choix importants. Un changement de règle, de direction artistique ou de périmètre revient à la Production pour arbitrage par le producteur.

## Sous-agents et skills

Une conversation peut déléguer des contributions délimitées à des sous-agents lorsque cela aide la mission : recherche technique, examen de références, analyse d'un problème ou revue d'un changement. La conversation qui délègue reste responsable du résultat, rassemble les contributions et présente les arbitrages au producteur.

Les instructions de rôle définissent les responsabilités. Les skills définissent les méthodes de travail. Suivre les workflows des skills de Matt Pocock adaptés à la situation : clarification, recherche, prototype, spécification ou implémentation. Choisir le chemin selon la mission. Pour Godot, appliquer les skills Game Studio uniquement lorsque leur workflow convient au moteur.

Commencer avec les skills existants adaptés. Créer des skills propres au jeu lorsque des procédures répétitives sont identifiées, par exemple préparer une animation pour son intégration dans Godot.

## Labels de discipline

Les labels suivants identifient les tâches par discipline :

| Label retenu | Travail |
| --- | --- |
| `discipline:code` | Godot, intégration et corrections techniques |
| `discipline:art` | Graphismes, animations et assets visuels |
| `discipline:game-design` | Règles, équilibrage et expérience de jeu |

La discipline complète le triage lorsqu'il est utilisé. Appliquer les [labels de triage](triage-labels.md) et les conventions de labels propres au skill suivi.

## Intégration et validation

Le Développement Godot est responsable de réunir le code, les assets et les règles validées dans une version jouable, avec des Issues d'intégration explicites lorsque nécessaire. Par exemple, la Direction artistique livre une animation conforme aux contraintes convenues ; le Développement l'importe, la branche au comportement et vérifie le résultat dans le jeu.

Chaque objectif jouable reçoit deux validations :

1. L'agent vérifie le fonctionnement technique et l'intégration.
2. Le producteur joue pour évaluer le rendu, les sensations et l'intention créative.

La Production traduit les retours du producteur en corrections ou en prochain objectif dans les Issues concernées.
