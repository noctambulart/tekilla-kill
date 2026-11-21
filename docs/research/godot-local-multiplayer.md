# Godot : jeu local sur écran commun et exports bureau

Recherche du **21 novembre 2026 (Europe/Paris)** pour [le ticket nº 5](https://github.com/noctambulart/tekilla-kill/issues/5), dans [la carte de préparation](https://github.com/noctambulart/tekilla-kill/issues/2). Sources primaires uniquement, consultées à cette date ; documentation versionnée 4.7 et code au tag `4.7.2-stable`. Aucun export ni essai de périphérique n'a été réalisé.

## Ce que cette recherche permet de retenir

- La dernière version stable publiée est **Godot 4.7.2**, sortie le **18 août 2026** ; la 4.8 est encore en **beta 4** depuis le 18 novembre. Cela fournit une référence d'étude reproductible, sans décider de la version du projet. [Archive officielle](https://godotengine.org/download/archive/), [annonce 4.7.2](https://godotengine.org/article/maintenance-release-godot-4-7-2/).
- Windows, macOS et Linux possèdent des exports natifs, en GDScript comme en C#. Leur comparaison ci-dessous ne les transforme pas en trois cibles de livraison. [Exports](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html), [support C#](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/index.html#c-platform-support).
- **Quatre humains à la manette constituent un objectif à vérifier sur une configuration précise. Huit humains à la manette restent une capacité à démontrer**, surtout sous Windows : la documentation et le code ne fournissent pas une garantie homogène pour tous les périphériques. Le détail des divergences est conservé ci-dessous.

## Compter les joueurs et les périphériques séparément

Le cadrage de la carte et le glossaire du projet définissent un joueur comme un participant humain ou bot : boucle complète à **2 joueurs**, livraison visée à **4**, extension éventuelle à **8**. Le jeu est local, sur écran commun ; le réseau est hors de cette recherche. Une personne seule avec des bots fait partie des usages. [Carte nº 2](https://github.com/noctambulart/tekilla-kill/issues/2).

| Exemple de partie | Joueurs au total | Humains | Bots | Manettes nécessaires si chaque humain en utilise une |
| --- | ---: | ---: | ---: | ---: |
| Première boucle en solo | 2 | 1 | 1 | 1 |
| Livraison jouée seul | 4 | 1 | 3 | 1 |
| Livraison entre amis | 4 | 4 | 0 | 4 |
| Extension avec bots | 8 | 4 | 4 | 4 |
| Extension entièrement humaine | 8 | 8 | 0 | 8 |

**Inférence pour le projet :** un bot n'a pas besoin de périphérique physique. Une limite de quatre manettes ne serait donc pas une limite de quatre joueurs au total. Un humain au clavier-souris réduit également le nombre de manettes requis. Aucun de ces calculs ne démontre la performance, la lisibilité ou la qualité d'une partie à huit : ce sont d'autres critères de validation.

## Exports et conditions de distribution

Installer les modèles d'export correspondant à la version/édition utilisée et définir un preset par cible/architecture. L'export de projet produit une version jouable avec exécutable ; un simple export PCK/ZIP de ressources ne suffit pas. **Recommandation :** conserver la version exacte de l'éditeur, des modèles et les presets utilisés dans les livraisons. [Exporting projects](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html).

| Plateforme candidate | Capacités et prérequis documentés | Conséquence à prévoir |
| --- | --- | --- |
| Windows | Exports `x86_64`, `x86_32`, `arm64` ; exécutable et données du jeu. La signature automatique demande un certificat et Windows SDK/SignTool sous Windows, ou `osslsigncode` depuis un autre OS. | Choisir une architecture réellement testée ; la signature est une étape de distribution distincte de l'export de base. [Export Windows](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html). |
| macOS | Modèles officiels : application Universal 2, Intel et Apple Silicon. `.app` ou ZIP ; DMG seulement depuis macOS. Bundle identifier valide requis. Depuis Windows, préférer ZIP : un bundle `.app` directement exporté perd les droits exécutables. | Un téléchargement non signé/non notarié peut être bloqué par Gatekeeper. Pour une diffusion fluide hors magasin : certificat Developer ID, signature, notarisation et agrafage du ticket. Outils Xcode sur Mac ; `rcodesign` permet aussi un chemin depuis Linux/Windows. [Export macOS](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html). |
| Linux | Exécutable et données ; architectures classiques `x86_64`, `x86_32`, `arm64`, `arm32`. Le guide mentionne aussi RISC-V, PowerPC et LoongArch, mais sans modèles officiels : compilation nécessaire. | Sélectionner une distribution et une architecture d'essai ; préserver les droits d'exécution dans le paquet transmis. La présence d'une option d'architecture n'est pas une promesse de compatibilité avec toutes les distributions. [Export Linux](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_linux.html). |

Les exigences minimales publiées pour un projet natif simple sont Windows 10, macOS 11 sur Intel / 13 sur Apple Silicon et une distribution Linux sortie après 2018 ; le rendu choisi impose aussi ses API graphiques (Compatibility : OpenGL 3.3 ou Direct3D 11 sous Windows ; autres moteurs : Vulkan/Metal/Direct3D 12 selon plateforme). Ce sont des bases indicatives, pas les exigences de Tequila Kill. **À tester :** démarrage, rendu, son et cadence sur le matériel retenu. [System requirements, projets exportés](https://docs.godotengine.org/en/4.7/about/system_requirements.html#exported-godot-project).

## GDScript ou C# : conséquences sans choix imposé

**GDScript :** le chemin standard utilise l'éditeur et les modèles standards ; aucune chaîne de compilation .NET n'est ajoutée. **C# :** utiliser l'édition .NET de Godot, les modèles .NET et installer séparément le SDK .NET pour construire le jeu. Le runtime nécessaire aux jeux compilés est fourni ; demander au joueur d'installer le SDK n'est donc pas un prérequis normal. Le guide cite .NET 8 ou ultérieur à partir de Godot 4.5 : vérifier et figer le SDK compatible avec la version et les dépendances finalement choisies. [C# basics, prérequis](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/c_sharp_basics.html#prerequisites), [éditions et modèles Windows](https://godotengine.org/download/windows/).

Les trois plateformes bureau sont prises en charge en C#. Il faut ajouter les exigences du runtime .NET à celles de Godot et vérifier les bibliothèques natives éventuelles. Le code d'export 4.7.2 publie les sorties .NET pour l'OS et l'architecture demandés et les inclut au paquet : distribuer tout le résultat d'export, pas seulement l'exécutable et le PCK. [Support C# par plateforme](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/index.html#c-platform-support), [ExportPlugin.cs 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/mono/editor/GodotTools/GodotTools/Export/ExportPlugin.cs).

Ni ces contraintes d'export ni les API d'entrée examinées n'imposent un langage pour ce jeu local. Le choix reste ouvert et doit aussi tenir compte de la maintenance et de l'expérience de l'équipe.

## Manettes : capacités, backends et divergence des sources

Depuis Godot 4.5, **SDL 3** assure les manettes sur les trois OS bureau. Ce changement ne remplace pas le système de fenêtres, clavier ou souris de Godot. [Guide des manettes 4.7](https://docs.godotengine.org/en/4.7/tutorials/inputs/controllers_gamepads_joysticks.html).

Il faut conserver trois niveaux de preuve distincts :

1. **Documentation Godot :** la [liste des fonctions 4.7](https://docs.godotengine.org/en/4.7/about/list_of_features.html#input) annonce huit manettes simultanées ; le [guide des manettes](https://docs.godotengine.org/en/4.7/tutorials/inputs/controllers_gamepads_joysticks.html#my-controller-isn-t-recognized-by-godot) affirme encore quatre maximum sous Windows à cause de XInput. Ces textes ne constituent pas une garantie cohérente de huit sur Windows.
2. **Code de la stable étudiée :** [`Input::JOYPADS_MAX = 16`](https://github.com/godotengine/godot/blob/4.7.2-stable/core/input/input.h) ; [`get_unused_joy_id()`](https://github.com/godotengine/godot/blob/4.7.2-stable/core/input/input.cpp) attribue une place libre ; le [pilote SDL](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/sdl/joypad_sdl.cpp) ouvre les périphériques remontés par SDL et refuse si les places sont épuisées. **Inférence :** le stockage moteur ne bloque pas huit ; cela ne garantit pas que l'OS, le backend et le matériel remontent huit appareils utilisables.
3. **API de plateforme :** Microsoft documente quatre indices XInput, de 0 à 3. Cette limite concerne XInput, pas tous les modes d'entrée possibles sous Windows. [XInputGetState](https://learn.microsoft.com/en-us/windows/win32/api/xinput/nf-xinput-xinputgetstate).

| OS | Différence pertinente | Lecture pour quatre / huit manettes humaines |
| --- | --- | --- |
| Windows | SDL peut utiliser divers pilotes. Son pilote Raw Input pour appareils compatibles XInput est désactivé par défaut selon le wiki ; le mainteneur SDL confirme la limite XInput et la possibilité d'autres chemins. Un signalement SDL rapporte six manettes après activation de Raw Input. | Quatre restent à essayer avec les appareils prévus. Huit ne doivent pas être promis sur le chemin XInput seul. Raw Input/GameInput/HIDAPI constituent des pistes de vérification ; le cas SDL à six n'est pas un test Godot à huit. [Hint Raw Input](https://wiki.libsdl.org/SDL3/SDL_HINT_JOYSTICK_RAWINPUT), [échange mainteneur SDL nº 13831](https://github.com/libsdl-org/SDL/issues/13831). |
| macOS | SDL propose notamment GCController, activé par défaut, et HIDAPI selon les périphériques et la configuration. | La limite XInput ne s'applique pas à ces backends. Aucune garantie universelle de huit appareils réels n'est établie ici. [Hint GCController](https://wiki.libsdl.org/SDL3/SDL_HINT_JOYSTICK_MFI), [HIDAPI](https://wiki.libsdl.org/SDL3/SDL_HINT_JOYSTICK_HIDAPI). |
| Linux | Détection et accès aux périphériques dépendent aussi des permissions et d'udev ; SDL documente ces causes de non-détection. | Même distinction : absence de limite XInput ne vaut pas validation à huit. Vérifier la distribution, les permissions, les pilotes et le transport. [SDL Linux, joystick](https://wiki.libsdl.org/SDL3/README-linux#joystick-does-not-work). |

**Recommandation :** conserver huit joueurs comme option de jeu, tout en ne publiant un nombre d'humains pris en charge qu'après essais. Ne pas assimiler huit bots/humains mélangés à huit manettes. Ne pas changer les variables de backend pour la livraison sans vérifier les régressions sur les autres modèles.

## Identifier et router chaque humain

L'[API Input](https://docs.godotengine.org/en/4.7/classes/class_input.html) fournit `get_connected_joypads()`, le signal `joy_connection_changed`, la lecture axes/boutons par identifiant et `get_joy_info()` (nom brut, fabricant, produit, numéro de série si disponible ; indices XInput/Steam Input selon le cas). Ces métadonnées servent au diagnostic ; leur présence ne constitue pas une identité persistante garantie. [`InputEvent.device`](https://docs.godotengine.org/en/4.7/classes/class_inputevent.html#class-inputevent-property-device) identifie l'origine d'un événement ; filtrer aussi son type pour distinguer manette, clavier et souris.

**Inférence de conception :** maintenir une association explicite « place humaine ↔ périphérique », avec rejoindre/quitter et réaffectation après reconnexion. Ne pas assimiler l'indice détecté à un numéro de joueur définitif : le moteur réutilise les places libres. Deux manettes de même modèle doivent rester deux périphériques. [Allocation des identifiants 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/core/input/input.cpp).

`Input` expose un état global ; une même action lue par tous les personnages ne crée pas automatiquement des contrôles individuels. **Recommandation :** actions distinctes avec périphériques assignés, ou routage central des événements/états filtrés par identifiant vers les commandes de chaque joueur. Séparer aussi les commandes de menu et de jeu : marquer un événement traité n'efface pas l'état global consulté par `Input`. [Description d'Input](https://docs.godotengine.org/en/4.7/classes/class_input.html#description). Prévoir des zones mortes par action et la politique hors focus ; le guide documente les deux. [Guide des manettes](https://docs.godotengine.org/en/4.7/tutorials/inputs/controllers_gamepads_joysticks.html).

## Clavier-souris partagé

La documentation décrit les événements de touches et de souris, avec une position pour la souris ; elle avertit que certaines combinaisons de touches simultanées disparaissent par ghosting. [Input examples](https://docs.godotengine.org/en/4.7/tutorials/inputs/input_examples.html#keyboard-events). Le code d'Input conserve un état de touches et une position de souris globaux. [Input 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/core/input/input.h).

**Inférence et limite de la recherche :** plusieurs humains peuvent se répartir des groupes de touches si les combinaisons et l'ergonomie le permettent ; cela ne fournit pas plusieurs visées souris indépendantes. Brancher plusieurs claviers ou souris ne démontre pas des identités séparées dans le chemin standard Godot. Aucune garantie officielle de ce fonctionnement multipériphérique n'a été établie ici ; ne pas le promettre à partir de la seule propriété `device`.

**Recommandation :** évaluer d'abord un humain clavier-souris avec les autres à la manette. Si un clavier partagé est souhaité, éprouver ensemble déplacement, tir, dash et rechargement sur le clavier réel, dispositions AZERTY/QWERTY comprises. La faisabilité matérielle ne décide pas de l'équité entre visée souris et stick ; cela reste une question de game design.

## Vérifications nécessaires avant engagement de livraison

Ces essais constituent un protocole proposé, **pas des résultats obtenus** :

1. Sur chaque OS/architecture finalement retenu, exporter la version exacte choisie puis lancer le paquet reçu sur une autre machine, sans éditeur ni SDK de développement. Vérifier droits exécutables et parcours de téléchargement/signature, particulièrement Gatekeeper.
2. Journaliser version Godot, OS, modèles de manettes, connexion USB/Bluetooth/adaptateur, éventuel Steam Input, identifiants et métadonnées disponibles. Tester d'abord 1, puis 2 et 4 manettes simultanées, notamment plusieurs exemplaires identiques.
3. Pour l'option huit humains, brancher huit manettes physiques et contrôler simultanément les huit personnages dans **l'export**. Sous Windows, identifier les appareils XInput et tester séparément tout backend alternatif ; consigner ses paramètres et ses régressions. Une simple détection de huit noms ne suffit pas.
4. Vérifier l'absence de commandes croisées, les menus, l'ajout/retrait à chaud, l'ordre de connexion, la reconnexion, le retour de veille et la perte de focus. Tester axes, gâchettes, zones mortes et boutons réellement utilisés.
5. Valider un humain avec bots à 2 puis 4 joueurs, les mélanges humains/bots, et éventuellement 8 joueurs. Mesurer cadence et lisibilité sur écran commun séparément de la compatibilité des périphériques ; le producteur valide les sensations en jouant.

**Décisions encore ouvertes :** version retenue, GDScript/C#, OS et architectures de livraison, appareils et connexions pris en charge, contrôles clavier, nombre maximal d'humains garanti. Aucun choix produit ni architecture réseau n'est introduit par ce rapport.
