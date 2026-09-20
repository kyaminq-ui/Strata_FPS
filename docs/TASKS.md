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

## Milestone 3 (tranche 3.3) — États : calme → suspicion → alerte → combat
- [x] Machine à états en nœuds enfants (`Enemy/States/Calm|Suspicious|Alert|Combat`, base `EnemyState`, même patron que `PlayerState`) ; `net_state` répliqué, label coloré par état (debug)
- [x] **Calm** : patrouille. **Suspicious** : va à la dernière position perçue (vue/bruit), regarde autour 4 s, puis retour au calme. **Alert** : poursuit (5.5 m/s), retombe en suspicion après 6 s sans voir le joueur. **Combat** : à ≤ 12 m avec vue, s'arrête et fait face (tir en 3.4) ; retour en alerte après 1 s sans vue ou si le joueur s'éloigne de > 15 m
- [x] Détection progressive : un joueur vu remplit une jauge (1 s de vue continue → alerte, décroît en 3 s) ; un bruit ou une vue → suspicion immédiate
- [x] **Alerte globale partagée** : un ennemi qui passe en alerte prévient tous les autres à ≤ 60 m ; être touché alerte l'ennemi et révèle la position du tireur
- [x] Tout dans `EnemyConfig` (vitesses, délais, rayons, distances de combat)
- [x] Vérifié solo : calme→suspicion→alerte→combat sur vue continue (Enemy1 alerté par partage) ; combat→alerte→suspicion→calme après perte de vue ; un tir hors de vue fait enquêter puis trouver le joueur ; dégâts → alerte ; aucune erreur
- [x] Vérifié host+client (`net_probe_enemy.gd`) : les tirs du client font passer Enemy1 en combat, Enemy2 est alerté par partage puis passe en combat ; le client voit tous les états répliqués ; aucune erreur
- Bug trouvé/corrigé en test réseau : une alerte reçue sans vue (partage, bruit, dégâts) retombait aussitôt en suspicion car `time_since_seen` n'était pas remis à zéro → `Alert.enter()` le réinitialise.
- [ ] **Feel à valider en jouant** (temps de détection, vitesse de poursuite, durée de fouille, rayon de partage)
- Limites : le combat ne tire pas encore (3.4) ; pas de retour au poste après alerte (reprend la patrouille au waypoint courant) ; `enemy.gd` ≈ 200 lignes (> objectif ~150) : extraire la conscience/alerte en composant si 3.4 le fait grossir.

## Mouvement — accroupi et saut de dash (demande du développeur)
- [x] **Accroupi volontaire** : maintenir C / Ctrl (action `slide`) au sol. Rapide (≥ 5 m/s) = slide comme avant ; lent ou à l'arrêt = état `Crouch` (`state_crouch.gd`, 4 m/s). Fin de slide avec la touche encore maintenue → reste accroupi ; relâcher → se relève s'il y a la place. Saut et dash possibles depuis l'accroupi (une fois relevable)
- [x] **Saut pendant le dash** : jump pendant un dash au sol → saut immédiat qui garde 12 m/s (`dash_jump_speed`) dans la direction du dash ; saut juste après la fin du dash OK
- [x] `net_sliding` renommé `net_crouched` (slide ou accroupi), pilote la hauteur/mesh des autres joueurs
- [x] Vérifié solo : accroupi à l'arrêt (capsule 1.0 m, relevé au relâchement), slide 10.9 m/s → accroupi → relevé, dash-jump (vy 8.8, 12 m/s), saut après dash ; host+client (`tests/net_probe_crouch.gd`) : le host voit le client accroupi pendant 3 s puis relevé ; aucune erreur
- [ ] **Feel à valider en jouant** (vitesse accroupi 4 m/s, élan du dash-jump 12 m/s)

## Milestone 3 (tranche 3.4) — Combat ennemi + lag compensation
- [x] `EnemyWeapon` (enfant `Weapon` de l'ennemi, host) : tir hitscan sur le joueur vu (monde + joueurs), 8 dégâts, cadence 0.9 s, dispersion 3°, **temps de réaction 0.7 s** de vue continue avant le premier tir ; dégâts via `Health.take_damage` (joueur : down/respawn existants) ; trait cosmétique (`Tracer`) local + RPC `show_shot` aux clients
- [x] `Combat` : fait face au joueur, s'approche au-delà de 8 m (3.5 m/s), strafe latéral en deçà (2.5 m/s, change de côté toutes les 1.8 s ou sur obstacle), tire
- [x] **Lag compensation** (`LagCompensator`, enfant `LagComp`, groupe `lag_comp`) : historique de positions ; à la résolution d'un tir **de client**, le host rembobine les ennemis de 0.15 s puis les remet (`WeaponController._server_fire`)
- [x] Refactor : `enemy.gd` 250 → 150 lignes (`EnemyAwareness` = détection/alerte/bruit/dégâts ; `LagCompensator`)
- [x] Vérifié solo : le joueur immobile à 9 m perd 8 PV/s, l'ennemi strafe (x oscille de 4 m), down/respawn du joueur sans erreur, mort/respawn de l'ennemi, rembobinage (0.47 m, raycast touche l'ancienne position, restauration exacte) ; host+client (`net_probe_enemy.gd`, 5 tirs) : **4/4 tirs valides du client touchent** l'ennemi mobile (avant : 2/3), kill vu des deux côtés, le client voit sa santé baisser sous les tirs ennemis (100→68), alerte partagée, aucune erreur
- [ ] **Feel à valider en jouant** (dégâts/cadence/précision/réaction des ennemis, lisibilité du strafing, difficulté avec 2 ennemis)
- Limites : **toujours pas de test avec latence artificielle** (tout en 127.0.0.1) ; tir ennemi sans son ni flash ; le strafing peut mener au bord de l'arène (pas de garde-fou) ; pas de couverture ; l'ennemi ne tire que le joueur vu (pas de tir de suppression) ; le tracer côté client non vérifié visuellement.

## Milestone 3 (tranche 3.5) — Infiltration
- [x] **Élimination silencieuse** : mêlée dans le dos (`takedown_back_dot` −0.2) d'un ennemi **calme ou suspicieux** = kill en un coup (`MeleeController` lit le contrat `can_be_silenced(from)` de la cible) ; un coup mortel ne prévient personne (`EnemyAwareness._on_damaged` ignore si mort) ; de face, ou contre un ennemi en alerte/combat = mêlée normale (40 dégâts, alerte)
- [x] **Cadavres** : un ennemi mort reste visible, couché, grisé, pendant `respawn_delay` (30 s), groupe `enemy_bodies` ; `Perception` détecte les cadavres (cône, distance, ligne de vue) → **suspicion** (jamais alerte directe), un seul déclenchement par cadavre et par ennemi
- [x] **Renforts** (`EnemySpawner`, `ReinforcementConfig` : délai 8 s, 2 ennemis, cooldown 60 s, 3 max) : alerte frontale qui dure → 2 ennemis arrivent des points `ReinforcementPoints` déjà en alerte vers le joueur ; spawn répliqué (`MultiplayerSpawner` + `spawn_function`) ; sans respawn, le cadavre disparaît (`queue_free`) ; pas de renforts si l'alerte est retombée avant la fin du délai
- [x] Arène : **couloir gardé** (2 murs, `Enemy3` patrouille dedans, ouvert aux deux bouts) → face (vu), ou contournement par l'arrière pour l'élimination silencieuse
- [x] Vérifié solo : takedown dans le dos (kill, autres ennemis restent calmes), refusé de face / en alerte / en combat (règle testée état par état), mêlée de face = 40 dégâts + combat ; cadavre découvert → suspicion → retour au calme sans re-déclenchement ; renforts (vus après ~8 s de combat), disparition d'un renfort mort ; host+client (`net_probe_enemy.gd`, 22 s) : Reinforcement0/1 apparaissent chez le client en alerte puis en combat, la santé du client baisse (il meurt à t=20 sans erreur)
- Bug trouvé/corrigé : `points` du spawner nul (un export de nœud dans un `.tscn` écrit à la main exige `node_paths=PackedStringArray(...)`) ; couloir garde visible depuis le point d'apparition → reculé.
- [ ] **Feel à valider en jouant** (angle du dos, portée, lisibilité des cadavres, délai/nombre des renforts, difficulté du couloir)
- Limites : takedown vérifié côté host (même code pour un client, non rejoué en réseau) ; le corps n'est pas « fouillé »/caché ; pas de vrai chemin alternatif vertical (toit/conduit) dans l'arène ; les renforts arrivent toujours des mêmes points ; le bruit n'est toujours pas atténué par les murs ; les traits de tir ennemis sont enfants de `Enemies` (cosmétique).

## Milestone 3 (tranche 3.6) — Contenu : archétypes, élite, arène d'infiltration
- [x] `EnemyConfig` étendue (`display_name`, `body_color`, `pellets`, `silent_takedown`) ; `EnemyWeapon` multi-plombs (un seul RPC `show_shot(from, ends)`) ; 3 archétypes en `.tres` :
  - **GARDE** (`default_enemy.tres`) : 80 PV, pistolet 8 dégâts, rouge
  - **AGENT** (`security_agent.tres`) : 140 PV, plus lent, fusil 6 plombs × 4 (dispersion 7°, cadence 1.5 s), s'approche à 5 m, détecte plus vite (0.7 s), cône 130° / 16 m, bleu
  - **ELITE** (`elite.tres`) : 220 PV, rapide (poursuite 6.5), tir précis 10 dégâts / 0.6 s (dispersion 1.5°), voit à 26 m, détecte en 0.45 s, fouille plus longtemps, **pas d'élimination silencieuse dans le dos**, violet
- [x] **Renforts mixtes** : `ReinforcementConfig.unit_types` (arène d'infiltration : AGENT puis GARDE en alternance)
- [x] **Arène d'infiltration** (`arena_infiltration.tscn`, choix dans le menu ou `--arena=infiltration`, host et client doivent choisir la même) : enceinte avec **porte frontale** (2 gardes), **porte latérale est** (garde qui patrouille dehors), **passage bas à l'ouest** (linteau à 1.3 m : accroupi/slide seulement, les ennemis ne peuvent pas y passer), agent dans le hall, élite au terminal, couvertures dehors, renforts au sud
- [x] Vérifié solo : chargement (136 polygones de navmesh, 4 ennemis, types/PV/couleurs), élite non silençable / garde et agent silençables, mêlée sur élite = 40 dégâts sans kill, **slide sous le linteau** de l'ouest vers l'intérieur, combat de l'agent (≈ 24-30 par volée à 4 m) et de l'élite (≈ 17-24 dps à 10 m), renforts AGENT + GARDE, arène d'origine intacte ; host+client (`tests/net_probe_types.gd --arena=infiltration`) : le client voit les 4 archétypes, leurs états et patrouilles, volées à plombs multiples sans erreur
- [ ] **Feel à valider en jouant** (létalité de l'agent et de l'élite, tailles des cônes, difficulté des trois routes, lisibilité des couleurs/étiquettes)
- Limites : pas d'objectif réel dans l'arène (le terminal n'est qu'un repère : missions = phase suivante) ; les archétypes ne diffèrent que par leurs valeurs et leur arme (pas de comportement scripté propre : couverture, grenade, etc.) ; navmesh non vérifié sur une éventuelle route par le toit

## Corrections (retours du développeur, après 3.5)
- [x] **Accroupi / slide en l'air** : C / Ctrl en l'air → `Crouch` aérien (hitbox réduite, élan conservé, contrôle aérien normal) ; atterrissage à ≥ 5 m/s = slide, plus lent = reste accroupi ; relâcher → se relève. Fin de slide / chute d'un slide avec la touche maintenue → reste accroupi. Vérifié solo (saut → C → atterrissage 8 m/s = Slide ; atterrissage lent = Crouch ; relâchement = Walk, capsule 1.8)
- [x] **Arme visible sur les ennemis** : modèle (boîte sombre côté droit), point de bouche (`Muzzle`), flash au tir (local + `show_shot`), le trait part du canon ; vérifié par capture d'écran + flash à 0.06 s
- [x] **Down du dernier joueur debout** : avant, un joueur qui tombait sans partenaire *vivant* respawnait immédiatement (cas typique : le client est déjà down → le host « ne pouvait pas » tomber). Maintenant il tombe aussi en down ; **si tous sont down, respawn de tous après `all_down_respawn_delay` (3 s)** ; solo / partenaire parti = respawn immédiat. Vérifié host+client (client down puis host down : les deux down, respawn ensemble à ~3 s, PV 100) et solo. Non reproduit : « host qui respawn alors que le client est vivant » (il tombe bien en down dans mes tests)

## Phase 4.0 — Lean (demande du développeur)
- [x] **Penchement gauche/droite maintenu** : actions `lean_left` / `lean_right` (touches physiques Q/E = « A »/« E » en AZERTY, + Mouse5 (gauche) / Mouse4 (droite)). `PlayerLean` (`game/player/player_lean.gd`) décale la tête latéralement (0.35 m), l'incline (12°) et incline le mesh du corps ; le peer propriétaire lit l'input, limite le décalage contre les murs (raycast couche 1, marge 0.25 m) et réplique la cible dans `net_lean` ; tous les peers lissent. Réglages dans `MovementConfig` (groupe Lean). La caméra tire depuis la tête penchée (le host valide toujours l'origine à ≤ 5 m).
- [x] **Conflit de touche** : E servait à réanimer → l'action `interact` passe sur **F**.
- [x] Vérifié : host (lean ±1 → tête ±0.35 m), client headless (`tests/net_probe_lean.gd`, le host voit `net_lean`, décalage et roulis du client, les deux sens), limite mur (rapport 0.57, tête à 0.25 m du mur), capture d'écran (vue inclinée), aucune erreur de log
- [ ] **Feel à valider en jouant** (amplitude, vitesse, mapping souris). Limites : la capsule de collision et la cible des ennemis ne bougent pas (pas d'avantage de couverture) ; pas de lean bloqué en état dash/wall-run (le roulis s'ajoute)

## Phase 4.0 — Latence artificielle
- [x] `DelayedPeer` + options `--lag` / `--jitter` (voir NETWORK.md § Latence simulée). Bug trouvé et corrigé pendant le test : paquets en attente vers un pair déconnecté (purgés à la déconnexion)
- [x] **Bug réel trouvé : la lag compensation n'avait aucun effet** (raycast après `global_position` ne voit pas le déplacement avant le pas de physique suivant, prouvé par éval). Remplacée par un test analytique rayon-capsule à la position passée ; fenêtre 0.3 s
- [x] Vérifié host+client (`net_probe_enemy.gd`, 5 tirs) : 0 ms 4/5, RTT 100 ms 4/5 (1/5 avant le correctif), RTT 200 ms 4/5 (2/5 avec 0.15) ; down/réanimation sous RTT 260 ms OK ; solo (tir sur ennemi) OK, aucune erreur de log. La sonde d'ennemi a été corrigée (le joueur est placé 0.4 s avant le tir, sinon la validation d'origine rejette)
- [ ] Reste 4.0 : passe de feel sur le Milestone 3 avec le développeur (valeurs `.tres`) ; interpolation des ennemis non mesurée finement (seulement via les tirs)
- [x] Lean : mapping corrigé sur demande (Mouse5 = gauche, Mouse4 = droite ; Q/E inchangés)

## Phase 4.1 — GameSession + checkpoints
- [x] `GameSession` (autoload), `Checkpoint` (scène + script), un checkpoint dans l'arène d'infiltration (7, 0, -2) ; `PlayerLife` respawn via `GameSession.respawn_position` ; `Enemy.reset_encounter()` (+ garde contre le timer de respawn périmé) ; `main.gd` reset la session à l'entrée/sortie d'arène
- [x] Vérifié solo : départ sur le marqueur (z=20), passage sur le checkpoint → actif, mort → réapparition au checkpoint (6.25, -2) et ennemi mort remis à son poste. Vérifié host+client : le client voit le checkpoint actif (`cp=true`), tous down → respawn ensemble sur le checkpoint (slots 6.25 / 7.75), ennemi ressuscité, 0 erreur ; le client retombe ensuite et respawn à nouveau sur le checkpoint
- [x] Sondes de test : plus de références aux classes du jeu (compilation headless avant les autoloads), toutes compilent (`--check-only`), sonde de tir/ennemis revalidée (4/5)
- [ ] Non vérifié : suppression des renforts au reset (code `queue_free`, pas déclenché en test) ; `Enemy` `_on_died` encore en attente pendant un reset : le nouveau garde `is_dead()` évite le double reset mais un ennemi qui meurt à nouveau avant la fin du vieux timer pourrait ressusciter un peu tôt (cas rare)
- [ ] À voir en jouant : un seul checkpoint dans le prototype, placé arbitrairement (les vrais viendront avec le secteur 4.3)

## Phase 4.2 — Métriques de niveau
- [x] Valeurs de mouvement verrouillées (feel validé par le développeur) ; capacités **mesurées dans le jeu** (saut 6.0 m, hauteur 1.75 m max, pas de marche, pente 44° max, dash 5.7 m, dash-saut 7.3 m, saut+dash 12 m, slide 7.9 m, wall-run 1.5 s / 15 m / +2.2 m, saut de mur +1.7 m et ~1 m latéral, wall-run + saut de mur 4.06 m) ; règles de blockout dans `MOVEMENT_METRICS.md`
- [x] Constats utiles : aucune marche franchie (même 0.2 m) → pas d'escaliers ; le saut de mur ne sert pas au wall-to-wall
- [ ] Non mesuré : slide/dash en pente, wall-run sur mur courbe ou incliné, distances à deux joueurs

## Phase 4.3 — Blockout du secteur Bas-fonds + hub
- [x] Brief (`SECTOR_BRIEF.md`), générateur `tools/build_bas_fonds.py` (positions dans le script) → `game/world/sector_bas_fonds.tscn` (36 × 88 m, 4 niveaux) et `hub_graybox.tscn` ; sélectionnables dans le menu de debug (`--arena=hub` / `--arena=sector`)
- [x] Vérifié solo (simulation d'entrées) : rampes jusqu'à la terrasse (ouest et est), wall-run est → mezzanine est, marches à sauter, conduit bas, passerelle ; navmesh baké (284 sommets), 10 ennemis patrouillent sur les 4 niveaux ; hub chargé (capture)
- [x] Vérifié host+client : le client rejoint (`--arena=sector`), voit 10 ennemis et 3 checkpoints, checkpoint actif chez lui, tous down → respawn ensemble sur le checkpoint ; aucun spawn sous le feu (barricade)
- [x] **Révision 1 (retour : trop ouvert)** : entrepôt, ateliers, salles des machines, ravin en tunnel, salle du boss fermée, néons (`SECTOR_BRIEF.md`) ; 13 ennemis. Vérifié : conduit → entrepôt, entrepôt → tour (2 portes), place → ateliers, tunnel, toit → salle du boss, tour → ravin, wall-run est encore valide ; les ennemis rejoignent la cour depuis la terrasse (navmesh relie les 4 niveaux) ; host+client (13 ennemis, checkpoint, respawn)
- [ ] **À jouer par le développeur** : tout le level design (lisibilité, longueur, difficulté, routes discrète/verticale, exposition de CP1, ravin, toits)
- Note : l'alerte partagée a un rayon de 60 m (`alert_share_radius`) et ignore les murs : dans un secteur de 88 m, une alerte à la cour réveille presque tout ; à régler en jouant (par exemple 30 m)
- [ ] Non fait : ascenseur/changement de scène hub → secteur, boss, objectifs, décor ; pas de parapets sur les toits ; ennemis de toit/terrasse jamais testés en combat ; wall-run est vérifié une fois (timing d'un joueur réel à valider)

## Ensuite (une couche à la fois, jouable et vérifiée)
Milestone 1 à valider en entier (jeu à 2 en fenêtres) → combat → IA/infiltration → contenu.

## Actions pour le développeur
- `git init` (pas de dépôt actuellement) puis premier commit.
- Valider le feel du mouvement en jouant.
