# TASKS

## Milestone 0 — FOUNDATION
- [x] GDD lu, projet Godot inspecté, MCP godot-ai vérifié (disponible, Godot 4.7.2)
- [x] CLAUDE.md, ARCHITECTURE, NETWORK, ASSET_PIPELINE, AUDIO_PIPELINE, DECISIONS, MOVEMENT_METRICS, TASKS
- [x] Squelette de dossiers, PROVENANCE.csv
- [x] Scène de démarrage (menu debug), player minimal, multiplayer minimal (ENet host/join)
- [x] Lancement sans erreur bloquante vérifié (solo, host + client headless)

## Milestone 1 — MOVEMENT + TWO PLAYERS
- [x] Couche A : marche + caméra (solo) — vérifiée techniquement (déplacement, collision) ; **feel à valider en jouant**
- [x] Host/client : 2 joueurs qui apparaissent, se déplacent, visibles des deux côtés — vérifié avec host (éditeur) + client headless (`tests/net_probe.gd`)
- [ ] Test 2 instances **fenêtrées** validé par le développeur (regard, visuel du joueur distant, orientation)

## Couche B — Saut
- [x] Saut + coyote time + jump buffer (touche Espace physique), paramètres dans `MovementConfig`
- [x] Vérifié techniquement : apex 1.67 m, vol 0.73 s, buffer (rebond à l'atterrissage), coyote (saut 0.07 s après le bord), réplication host↔client (y max vu par le host : 1.64 m)
- [ ] **Feel à valider en jouant** (hauteur, gravité, tolérances) avant la couche D

## Couche D — Dash
- [x] Dash horizontal (Shift physique), sol ou air, direction = input (sinon avant), gravité suspendue pendant le dash, sortie à la vitesse de marche, cooldown
- [x] Vérifié techniquement : ≈ 6.3 m au sol et latéral, bloqué par le cooldown, y constant en l'air, réplication host↔client (pic 42 m/s vu par le host vs 8 m/s en marche)
- [ ] **Feel à valider en jouant** (distance, durée, cooldown, sortie de dash, enchaînement dash + saut) avant la couche E
- Note : le dash coupe la vélocité verticale en l'air ; enchaînement saut pendant le dash à décider au tuning.

## Couche E — Slide
- [x] Slide (Ctrl physique) depuis la marche au sol : élan conservé (≥ `slide_speed`), friction, capsule réduite, saut et dash possibles hors du slide, rampement si impossible de se relever sous un obstacle (poutre `LowBeam` de l'arène)
- [x] Vérifié techniquement : passage sous la poutre (marche bloquée à z≈-3.6), sortie et relevé, saut hors slide (élan 11 m/s conservé), dash coupe le slide, réplication visuelle host↔client (accroupi, tête, mesh)
- [ ] **Feel à valider en jouant** avant la couche F ; « compatible avec le tir » sera à revérifier avec le combat
- Bug trouvé/corrigé en test : joueur coincé accroupi sous l'obstacle quand la vitesse de slide tombait à 0 → mode ramper.

## Refactor + Couche F — Wall-run
- [x] `player.gd` éclaté en machine à états (`game/player/state_*.gd` : Walk, Dash, Slide, WallRun) ; comportements des couches B/D/E revérifiés identiques (apex 1.67 m, dash 6.26 m, cooldown, slide, tunnel)
- [x] Wall-run : accroche en l'air le long d'un mur (avant maintenu, vitesse ≥ 6), roulis caméra, durée max, saut de mur (élan conservé + poussée opposée), dash possible depuis le mur, cooldown de ré-accroche
- [x] Vérifié techniquement : accroche, 8° de roulis, saut de mur (vel 9.9 / 8.4 / +5.7 z), réplication host↔client (saut, dash, slide) après refactor
- [ ] **Feel à valider en jouant** (accroche, durée, chute, saut de mur, roulis) — le mur de 20 m de l'arène sert de test ; enchaînements complets (saut → wall-run → saut de mur → dash → slide)
- Limites connues : accroche seulement en longeant le mur (pas de face-mur), un seul mur détecté (pas de coins), pas de VFX/son de wall-run, le wall-run n'est pas répliqué comme état (seule la position l'est).

## Milestone 1 — validé (feel joué par le développeur : marche, saut, dash, slide, wall-run, 2 joueurs)

## Milestone 2 — COMBAT (premier tranche : tir)
- [x] `WeaponData` (Resource) + `pistol.tres` : hitscan, 25 dégâts, 0.25 s, 12 balles, rechargement 1.2 s
- [x] `WeaponController` (nœud `Player/Weapon`) : cadence/munitions/visée locales, tir résolu **par le host** (raycast serveur, dégâts = valeur de `WeaponData`), validation serveur (bon tireur, cadence, origine), confirmation au tireur, traits cosmétiques sur tous les peers
- [x] `HealthComponent` + `training_dummy` (3 mannequins dans l'arène, host-autoritaires, respawn 3 s, santé répliquée)
- [x] HUD minimal (viseur, munitions, hitmarker), viewmodel graybox
- [x] Vérifié : solo (100→0 en 4 coups, kill confirmé, respawn, rechargement, tir en slide), rate limit / origine falsifiée / faux tireur rejetés, host+client (client : 3 tirs, 3 hits confirmés, santé 25 identique chez host et client)
- [ ] **Feel du tir à valider en jouant** (cadence, viseur, hitmarker, recul absent, viewmodel) + test host/client fenêtré
- Limites : pas de recul/spread/son/VFX d'impact, pas de dégâts sur les joueurs (pas de PvP), pas de lag compensation (inutile tant que les cibles sont statiques ; à revoir avec l'IA mobile), munitions non validées côté host (le client est autoritaire sur son chargeur, la cadence est bornée par le host).
- Prochaines tranches : 2e arme, mêlée, gadget, santé/down du joueur (coop), puis IA (patrouille → suspicion → alerte → combat).

## Milestone 2 (part 2) — Santé du joueur, down, réanimation
- [x] `HealthComponent` sur le joueur ; `PlayerLife` (host-autoritaire) : à 0 PV → **down** s'il y a un partenaire vivant (15 s), sinon respawn immédiat au point d'apparition (solo, partenaire parti/down) ; `PlayerReviver` : maintenir **E** à ≤ 2.5 m d'un partenaire down (3 s) → relevé à 50 % PV ; expiration → respawn à 100 % PV
- [x] Joueur down : ne bouge plus, ne tire plus, mesh/caméra accroupis, visible des deux côtés ; HUD (PV, « DOWN Ns », progression de réanimation, invite « Hold E »)
- [x] `DamageZone` (piège rouge dans l'arène, 40 PV/s) = source de dégâts de test et élément de level design
- [x] Paramètres dans `LifeConfig` (`default_life.tres`)
- [x] Vérifié : solo (dégâts directs et zone → respawn direct, pas de down) ; host+client : client down (vu par le client), réanimation par input réel (0 % hors portée, 50 % après 1.5 s, relevé à 50 PV), expiration → respawn, dernier debout qui tombe → respawn immédiat, joueur down immobile malgré « avancer » maintenu ; aucun erreur script
- [ ] **À valider en jouant** : durées (down 15 s, réanimation 3 s), lisibilité HUD, feel du down ; test 2 fenêtres
- Limites : pas de checkpoints réels (respawn = marqueurs `spawn_points`), pas de mort « partie perdue », pas de marqueur monde sur le joueur down (visible seulement par son mesh accroupi), pas de sons/VFX, le partenaire down reste au sol si le dernier debout respawn (réanimable jusqu'à l'expiration).
- Prochaines tranches : 2e arme, mêlée, gadget, puis IA.

## Ajustements demandés après validation
- [x] Slide sur **Ctrl ou C** (touches physiques, les deux liées à l'action `slide`)
- [x] Arme répliquée visuellement : modèle 3e personne (`Head/GunMesh`) visible par les autres joueurs (inclinaison suivant le regard), viewmodel pour soi, flash de bouche cosmétique sur le tireur (déclenché par `show_shot` / tir local). Vérifié : host voit l'arme + 3 flashs du client, client voit l'arme + les flashs du host, solo OK, aucune erreur.
- Limite : une seule arme ; quand la 2e arrive, répliquer l'id de l'arme équipée (propriété `net_weapon`) et instancier le modèle correspondant.

## Milestone 2 (part 3) — 2e arme : fusil à pompe + changement d'arme
- [x] `WeaponData` étendu (`pellets`, `spread_degrees`, `equip_time`, présentation graybox) ; `shotgun.tres` (8 plombs × 12, 4° de dispersion, cadence 0.9 s, 6 obus, rechargement 2 s, portée 40 m)
- [x] `WeaponController` : `loadout` (pistolet, fusil), munitions **par arme**, changement d'arme (touches **1 / 2**, molette), changer annule le rechargement, arme équipée répliquée (`net_weapon`) → modèle 3e personne/viewmodel adaptés, HUD avec le nom de l'arme
- [x] Résolution host **par plomb** avec **graine partagée** (client et host tirent les mêmes plombs ; traits = vérité serveur) ; arme demandée validée (index) et cadence de l'arme ; confirmation de hit agrégée par tir
- [x] Vérifié : solo (96 dégâts à 4 m, 0 à 28 m sur 2 tirs, cadence, munitions conservées par arme, annulation du rechargement) ; host+client (client équipé fusil : 3 tirs, ammo 3, 2 hits confirmés, kill ; host voit l'arme du client et inversement) ; aucune erreur script
- [ ] **Feel à valider en jouant** (dispersion, dégâts par distance, cadence, encombrement viewmodel, changement d'arme)
- Limites : cadence serveur partagée entre armes (un cheater pourrait alterner pour tirer plus vite : à durcir si besoin), pas de recul/son/animations, pas d'échange d'arme ramassée.
- Prochaines tranches : mêlée (1 système simple), gadget (1), puis IA.

## Milestone 2 (part 4) — Mêlée
- [x] `MeleeController` (nœud `Player/Melee`, config `MeleeConfig` / `default_melee.tres`) : touche **V**, 40 dégâts, portée 2.4 m, cône ±50°, cooldown 0.55 s, bloque le tir pendant le coup, utilisable dans tous les états de mouvement (dont slide)
- [x] **Dash → mêlée** : dans les 0.5 s après le début d'un dash (`net_dashing`, répliqué et lu par le host) : ×1.5 dégâts (60) et +1 m de portée
- [x] **Finisseur** : cible à ≤ 30 % de PV → dégâts = PV max (kill)
- [x] Résolution host (cône + ligne de vue bloquée par le monde, cadence/origine/tireur validés, confirmation → hitmarker) ; animation du coup cosmétique, visible par les autres
- [x] Vérifié : solo (100→60→20→finisseur, cooldown, hors portée 3.6 m / hors cône / derrière un mur = 0 dégât, dash-mêlée = 60 à 3.1 m) ; host+client (client : 3 coups, 3 hits confirmés dont finisseur, host voit ses 3 coups ; host : le client voit ses 2 coups) ; aucune erreur script
- [ ] **Feel à valider en jouant** (portée, cône, cooldown, punch du viewmodel, enchaînement dash → mêlée, absence d'animation de recul)
- Limites : pas de knockback ni d'animation d'arme complète, pas de mêlée silencieuse/infiltration (élimination discrète) : à définir avec l'IA, pas de son.
- Prochaines tranches : gadget (1), puis IA (patrouille → suspicion → alerte → combat).

## Milestone 2 (part 5) — Gadget : grenade explosive
- [x] Touche **G** : lance une grenade (14 m/s + 3 m/s de lift), stock 2, recharge 1 toutes les 6 s, cooldown 0.7 s ; HUD `[G] grenades: n`
- [x] La grenade **explose à la fin de la mèche (2.5 s) ou dès qu'un tir la touche** (elle a un `HealthComponent` d'1 PV sur la couche projectiles ; les armes la touchent sans code spécial) ; clignote en fin de mèche ; **réaction en chaîne** (l'explosion détruit les grenades proches)
- [x] Explosion : rayon 5 m, 90 dégâts au centre décroissant linéairement, bloquée par les murs (ligne de vue), ×0.5 sur les joueurs (tir ami / dégâts sur soi) ; effet visuel sur tous les peers
- [x] **Réplication** : simulation 100 % host (RigidBody), `MultiplayerSpawner` (`GrenadeSpawner`, groupe `grenade_spawner`) + `net_position` interpolé chez les clients ; lancer = demande au host (validé : tireur, cadence, origine)
- [x] Vérifié : solo (lancer/mèche, dégâts 52 à ≈ 2.1 m, tir qui la fait exploser avec 1.4 s de mèche restante + hitmarker, chaîne, dégâts sur soi 30) ; host+client : **client lance / host tire dessus** (détruite après 1.25 s, mèche 1.3 s restante, hitmarker host), **host lance / client tire dessus** (hit confirmé au client), grenade visible et en mouvement chez le client, explosion blesse le client (100 → 70, vu des deux côtés) ; aucune erreur script
- [ ] **Feel à valider en jouant** (trajectoire, mèche, rayon, tir en l'air, dégâts sur les joueurs)
- Correctif (retour du développeur) : le clignotement rouge/vert de fin de mèche n'était visible que chez le host → la mèche restante est répliquée (`net_fuse_left`), le client calcule le clignotement (vérifié : 10 changements de couleur vus par le client, comme chez le host).
- Limites : stock géré côté propriétaire, pas d'inertie du joueur transmise à la grenade, pas de trajectoire prévisionnelle/son/VFX final.
- Prochaine étape : Milestone 3 — **IA** (patrouille → suspicion → alerte → combat), host-autoritaire.

## Milestone 3 (tranche 3.1) — Ennemi de base + navigation + patrouille
- [x] `game/ai/` : `EnemyConfig` (+ `default_enemy.tres` : 80 PV, marche 3 m/s, attente 1.5 s, respawn 5 s), `Enemy` (`enemy.tscn`, couche 3, enfant `Health`, `NavigationAgent3D`, label debug d'état), `nav_baker.gd`
- [x] Arène : `NavRegion` (bake host au chargement), `PatrolRoutes/RouteA|RouteB` (4 `Marker3D` chacune), `Enemies/Enemy1|Enemy2`
- [x] Simulation 100 % host ; réplication `net_position`, `net_yaw`, `net_state`, `Health:health` (synchronizer autorité 1)
- [x] Vérifié solo : les 2 ennemis bouclent sur les 4 waypoints (contournement du bloc, attente, pas de blocage) ; pistolet (80→55→30→5→mort sur cible mobile), mêlée (40 puis finisseur), grenade (80→4.8) les blessent ; mort → disparition → respawn au point de départ après 5 s ; aucune erreur
- [x] Vérifié host+client (`tests/net_probe_enemy.gd`) : positions/états vus par le client = ceux du host (écart ≤ 0.1 m) ; le client blesse un ennemi mobile (2 tirs confirmés sur 3, kill vu des deux côtés) ; mort et respawn répliqués
- [ ] **Feel à valider en jouant** (vitesse de marche, fluidité de l'interpolation, lisibilité de la capsule)
- Bugs trouvés/corrigés : navmesh à y=0.5 (premier point du chemin jamais « atteint ») → `path_height_offset` ; waypoint collé à la poutre basse hors navmesh → avance aussi sur `is_navigation_finished()`.
- Limites : **1 tir client sur 3 raté** sur cible mobile (positions du host ≠ ce que voit le client) → lag compensation/tolérance à traiter avant 3.4 ; pas de test avec latence artificielle ; ennemis toujours aveugles/inoffensifs (3.2+).

## Milestone 3 (tranche 3.2) — Perception
- [x] `NoiseBus` (nœud `NoiseBus` de l'arène, groupe `noise_bus`, `NoiseBus.emit_at(...)`) : bruits émis par le host à la résolution des tirs (`WeaponData.noise_radius` : 25 m pistolet, 40 m fusil) et des explosions (`GrenadeConfig.noise_radius` : 35 m)
- [x] `Perception` (enfant de `Enemy`, host seul) : vision = distance ≤ 20 m, cône 110°, ligne de vue (raycast monde) vers le joueur vivant le plus proche ; ouïe = abonnement au `NoiseBus` (distance ≤ rayon du bruit, sans atténuation par les murs) ; expose `seen_player`, `last_seen_position`, `last_heard_position`, signaux `player_spotted` / `noise_heard`. Joueurs dans le groupe `players`.
- [x] Debug : le label de l'ennemi affiche `SEES` / `HEARD` (`net_state` répliqué) ; aucun comportement encore (3.3)
- [x] Vérifié solo : vu à 10 m de face ; non vu derrière, à 90° de côté, à 25 m, derrière un mur ; vu sans mur ; tir pistolet entendu à 20 m, pas à 35 m ; explosion entendue à 30 m ; aucune erreur
- [x] Vérifié host+client (`net_probe_enemy.gd`) : les tirs du client sont entendus par les 2 ennemis, le client voit `HEARD`/`SEES` répliqués ; aucune erreur
- [ ] **À valider en jouant** (portée de vue 20 m, cône 110°, rayons de bruit)
- Limites : vision indépendante de la posture/vitesse/obscurité ; bruit non atténué par les murs ; pas encore de bruits de dash/slide ni de corps (3.5) ; un seul point de visée sur le joueur (poitrine).

## Ensuite (une couche à la fois, jouable et vérifiée)
Milestone 1 à valider en entier (jeu à 2 en fenêtres) → combat → IA/infiltration → contenu.

## Actions pour le développeur
- `git init` (pas de dépôt actuellement) puis premier commit.
- Valider le feel du mouvement en jouant.
