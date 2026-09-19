# DECISIONS

Format : date · décision · raison. Ajouter en haut.

## 2026-09-19 — Mouvement
30. **C / Ctrl = slide si rapide, sinon accroupi** (même action) ; **saut possible pendant le dash** avec élan réduit (`dash_jump_speed`) plutôt que la vitesse de dash complète (33 m/s).

## 2026-09-19 — Milestone 3 (IA)
35. **Renforts = `EnemySpawner` (MultiplayerSpawner) déclenché par `become_alert`, si l'alerte dure encore après un délai** : pas de vagues sans fin (cooldown + max vivants), pas de respawn (le corps disparaît). Résout la décision « pas de spawner » (22) : il en faut un dès qu'un système crée des ennemis dynamiquement.
34. **Cadavre = ennemi mort visible, pas d'objet séparé** : découverte → suspicion seulement (« jamais échec si détecté »).
33. **Élimination silencieuse = contrat `can_be_silenced(from)` sur la cible** (duck-typing, comme `Health`) : la mêlée ne connaît pas `Enemy` ; calme/suspicion + dans le dos = kill.
32. **Lag compensation par rembobinage fixe** (0.15 s, `LagCompensator`) plutôt qu'un timestamp/RTT par client : simple, suffit en coop 2 joueurs ; à ajuster/tester avec latence artificielle. Seuls les tirs de clients rembobinent (le host tire sur l'état courant).
31. **Réaction avant tir (0.7 s de vue continue) et faibles dégâts (8)** : lisibilité et liberté d'approche plutôt que difficulté (pilier « jamais échec si détecté »).
29. **Alerte globale = `call_group("enemies", "receive_alert")` avec rayon** (60 m ≈ toute l'arène), pas de nœud d'alerte central : simple, host seul.
28. **Jauge de détection** (vue continue 1 s → alerte) plutôt qu'alerte instantanée : laisse une marge de réaction au joueur (pilier « jamais échec si détecté »). Bruit = suspicion, jamais alerte directe ; être touché = alerte.
27. **États d'ennemi en nœuds enfants** (patron `PlayerState`), transitions via `enemy.change_state()` ; `Enemy` porte le mouvement navmesh (`move_to`) et la conscience.
26. **Rayons de bruit dans les données d'arme/grenade** (`noise_radius`), émis par le host à la résolution ; ouïe = simple distance (pas de murs), suffisant pour le MVP.
25. **Vision = cône + distance + 1 raycast monde vers la poitrine du joueur, toutes les 0.1 s** ; `Perception` n'expose que l'état perçu, les décisions sont dans les états (3.3).
24. **`NoiseBus` = nœud de l'arène trouvé par groupe** (pas d'autoload), comme `grenade_spawner`.
23. **Navmesh baké au chargement par le host** (`nav_baker.gd` : parse des colliders statiques de l'arène, pas de fichier `.res` à maintenir). Le client ne bake rien : l'IA ne tourne que chez le host. `NavigationAgent3D.path_height_offset = 0.5` (= rayon de l'agent) car le navmesh baké est surélevé de l'agent_radius.
22. **Ennemis placés dans la scène** (comme les mannequins), pas de spawner tant qu'aucune mission n'en crée dynamiquement ; route = nœud `Marker3D` enfants (`@export var route`).
21. **Ennemi = `CharacterBody3D` simulé par le host seul**, autorité 1 par défaut ; les clients interpolent `net_position/net_yaw` (10 Hz, non fiable) et reçoivent `net_state` (fiable, à chaque changement) + `Health:health`. Waypoint atteint = distance plate ≤ tolérance **ou** navigation terminée (waypoint hors navmesh).

## 2026-09-19 — Combat / vie
20. **Gadget = grenade explosive destructible par les tirs** (choix du développeur). Elle a un `HealthComponent` : « touchée par un tir » = dégâts, sans cas particulier dans les armes ; 0.5× de dégâts sur les joueurs (tir ami/auto-dégâts) à ajuster au feel.
19. **Graine partagée pour les plombs** (client → host) plutôt que d'envoyer chaque direction : petit message, host autoritaire, traits fidèles. `WeaponData.damage` est par plomb.
15. **Tir résolu par le host** (raycast serveur, dégâts issus de `WeaponData`, validations cadence/origine/tireur) ; le client garde chargeur et trait immédiat. Raison : GDD (dégâts host) + sensation locale.
16. **Deuxième synchronizer à autorité 1 sur le joueur** (`SyncServer`) pour la vie/le down : le propriétaire simule sa position, mais la santé appartient au host.
17. **Down seulement s'il reste un partenaire vivant** ; sinon respawn immédiat (couvre solo, partenaire déconnecté, dernier debout). Raison : solo sans système down (GDD) et aucun état bloquant.
18. **Respawn = marqueurs du groupe `spawn_points`** en attendant de vrais checkpoints.

## 2026-09-19 — Milestone 0
13. **Spawn via `spawn_function` + données explicites** (peer_id, position) plutôt que réplication `spawn = true` : cette dernière ignore les propriétés dont l'autorité est le client (bug observé).
14. **Actions d'input écrites à la main dans `project.godot`** : l'outil MCP `input_map_manage` ne sait pas créer de touches physiques. Éviter de re-modifier ces actions via MCP (risque de perdre le mode physique) ; en cas de besoin, redonner `physical_keycode`.
1. **Transport ENet via MultiplayerAPI haut niveau**, isolé dans `MultiplayerManager`. Raison : le plus simple ; Steam/WebRTC = autre `MultiplayerPeer` plus tard.
2. **Solo = host sans client**, même code que le host. Raison : évite deux chemins de code et garantit que le solo reste jouable.
3. **Un seul autoload** (`MultiplayerManager`). `GameSession` reporté jusqu'au besoin (checkpoints/missions).
4. **Mouvement client-authoritative** (peer propriétaire) pour le MVP. Validation host ajoutée avec le combat.
5. **Autorité du joueur déduite du nom du nœud** (`str(peer_id)`) posé par le spawner.
6. **Le réseau est créé avant l'arène**, pour que la scène cliente existe avant les spawns et que `is_server()` soit correct.
7. **Scène de démarrage pilotée par `main.gd`** (instanciation de l'arène en enfant, pas de `change_scene`), pour un ordre d'initialisation déterministe.
8. **Touches physiques** dans l'InputMap (AZERTY/QWERTY).
9. **MovementConfig = une Resource** ; les champs dash/slide/wall-run seront ajoutés avec chaque couche (pas de champs morts).
10. **Arborescence sous `game/`**, non sous `scripts/` comme dans l'exemple du GDD, plus proche de la structure demandée.
11. **GDD en PDF** (`docs/GDD_Strata_FPS.pdf`) : `GDD.md` du GDD n'existe pas ; le PDF fait foi.
12. **Git** : le dossier n'est pas un dépôt. À initialiser par le développeur (voir TASKS.md).

## Points ouverts (GDD §16, non bloquants)
Titre définitif · nom/voix des opérateurs · structure hub/continue · séparation max entre joueurs · drop-in · progression commune/individuelle · fin · financement.
