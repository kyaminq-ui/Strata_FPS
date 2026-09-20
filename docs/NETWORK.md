# NETWORK

## Modèle
- Listen server : le host est aussi un joueur (peer id 1). 1 client max au MVP.
- Transport : ENet via `MultiplayerAPI` haut niveau. Isolé dans `MultiplayerManager` : remplacer par Steam plus tard = changer le `MultiplayerPeer` créé dans `host()`/`join()`.
- **Solo = host sans client.** Sans peer, Godot utilise `OfflineMultiplayerPeer` : `is_server()` vrai, `get_unique_id()` = 1. Le code de jeu est identique.
- Port par défaut : 7777. Pas de Steam, pas de matchmaking.

## Autorité
| Élément | Autorité |
|---|---|
| Mouvement/regard d'un joueur | Son peer (client-authoritative pour le MVP) |
| Spawn/despawn des joueurs | Host (`PlayerSpawner`) |
| Résolution des tirs et dégâts (mannequins, puis ennemis) | Host |
| IA (ennemis : patrouille, mort, respawn), objectifs, boss, loot | Host |
| VFX, audio | Local |

Client-authoritative pour le mouvement : choix simple et fluide pour du coop non compétitif. Validation host (anti-téléport, dégâts) à ajouter avec le combat.

## Réplication du joueur
`MultiplayerSynchronizer` réplique `net_position`, `net_yaw`, `net_pitch` (mode « toujours », unreliable). Le peer autoritaire écrit ces valeurs après `move_and_slide()` ; les autres peers interpolent visuellement (`player.gd::_process`).

## Spawn
`PlayerSpawner` (nœud dans l'arène) : le host appelle `spawn({peer_id, position})` ; `spawn_function` crée `player.tscn` nommé `str(peer_id)` sous `Players` sur tous les peers avec les mêmes données. (Piège : la réplication `spawn = true` des propriétés n'est pas envoyée quand l'autorité est le client, d'où les données explicites.) L'autorité est déduite du nom du nœud (`_enter_tree`), donc aucun état « joueur 1 » implicite.

## Combat (tir)
Le peer propriétaire gère cadence, chargeur et visée, dessine son trait immédiatement, puis envoie `server_fire(origine, direction)` au host (RPC fiable, `any_peer`). Le host rejette le tir si l'émetteur n'est pas le propriétaire du joueur, si la cadence est violée (×0.8) ou si l'origine est à plus de 5 m de la tête répliquée du joueur ; sinon il refait le raycast (couches monde + ennemis), applique les dégâts de `WeaponData` via `HealthComponent.take_damage()` (jamais envoyés par le client), envoie `confirm_hit` au tireur (hitmarker) et `show_shot` aux autres (trait cosmétique, non fiable). Le host tirant appelle la même fonction directement ; en solo aussi (pas de branche solo).
Multi-plombs : le tireur tire au sort une graine (`randi()`) envoyée avec `server_fire(arme, origine, direction, graine)` ; client et host dérivent les mêmes directions de plombs (`WeaponController.pellet_directions`), donc les traits locaux correspondent à la résolution serveur. Le host valide l'index d'arme et utilise les données de cette arme (dégâts, cadence, portée). `net_weapon` (index équipé, autorité propriétaire) est répliqué pour afficher le bon modèle chez les autres.
Présentation de l'arme : chaque joueur a un modèle d'arme 3e personne (visible par les autres) et un viewmodel (visible par soi). Le flash de bouche est cosmétique : le tireur le déclenche localement, les autres peers sur réception de `show_shot`, le host pour un tireur distant à la résolution du tir. Munitions et rechargement restent locaux au propriétaire.
Grenades : le propriétaire demande un lancer (`GrenadeThrower.server_throw`, RPC vers le host), le host valide et fait apparaître la grenade via `GrenadeSpawner` (MultiplayerSpawner + `spawn_function`, données explicites). La grenade est un RigidBody **simulé uniquement par le host** ; les clients la gèlent et interpolent `net_position` (synchronizer autorité host). Elle a un `HealthComponent` : tout tir résolu par le host qui la touche (n'importe quel joueur) la détruit -> `_explode()` (host) applique les dégâts de zone, puis `GrenadeSpawner.explosion_fx` joue l'effet chez tous.
Mêlée : même schéma que le tir (`MeleeController.server_melee` → host). Le host trouve la cible (sphère + filtre de cône + rayon de ligne de vue), applique les dégâts (renforcés si `net_dashing`, finisseur sous le seuil de PV) et confirme au tireur ; `show_melee` déclenche l'animation chez les autres.
`HealthComponent.health` est répliqué par le `MultiplayerSynchronizer` de la scène propriétaire (mode « toujours », 10 Hz pour les mannequins).

## Lean
`net_lean` (-1..1, propriétaire, `Sync`, non fiable) : cible de penchement déjà limitée par les murs côté propriétaire. `PlayerLean` lisse et applique décalage/roulis sur la tête et le mesh chez tous les peers ; purement présentation, la hitbox ne bouge pas. Sonde : `tests/net_probe_lean.gd`.

## Vie, down et réanimation
Le `Player` a deux synchronizers : `Sync` (autorité = propriétaire : `net_position/yaw/pitch/sliding`) et `SyncServer` (autorité forcée à **1**, 10 Hz : `Health:health`, `Life:downed`, `Life:down_time_left`, `Life:revive_progress`). Le host applique tous les dégâts (`HealthComponent.take_damage`, serveur uniquement) et pilote `PlayerLife` (down / respawn / réanimation). Le réanimateur envoie seulement `request_revive(active)` (RPC vers le host, identifié par l'émetteur) ; le host vérifie que le réanimateur est vivant et à portée (×1.5 de tolérance) et fait progresser la jauge. Un respawn demande au propriétaire de se téléporter (`Player.teleport`, RPC accepté uniquement de l'id 1) puisque le propriétaire simule sa position.

## Ennemis (IA)
`Enemy` (`game/ai/`) est placé dans la scène de l'arène : chaque peer a la même instance, autorité 1 (host). Seul le host exécute `_physics_process` (patrouille via `NavigationAgent3D`, navmesh baké chez lui seulement). Le `Sync` réplique `net_position`/`net_yaw` (10 Hz, non fiable), `net_state` (fiable, sur changement, label debug) et `Health:health`. Les clients interpolent et masquent l'ennemi quand `health <= 0` (en se collant à `net_position` pour éviter un glissement au respawn). Mort/respawn décidés par le host (`HealthComponent.died`). Les tirs/mêlée/explosions le touchent via le contrat `Health` (couche 3). Perception (host seul) : `NoiseBus` reçoit les bruits émis par la résolution host des tirs et explosions ; `Perception` lit les positions des joueurs côté host. Le client ne voit que le résultat (`net_state`). Tir ennemi : `EnemyWeapon` (host) raycast + `take_damage` sur le joueur touché ; trait cosmétique par RPC non fiable `show_shot`. **Lag compensation** : `LagCompensator` (enfant de chaque ennemi) garde un historique de positions ; pour un tir de client, `WeaponController._resolve_pellet` teste le monde/projectiles par physique et les ennemis **analytiquement** (rayon contre capsule à leur position d'il y a `window` = 0.3 s). Un rembobinage par `global_position` + raycast ne marche PAS (le serveur de physique n'applique le déplacement qu'au pas suivant) : c'était le cas avant la phase 4.0, la lag comp était sans effet. Le tir du host lui-même reste physique. Renforts : `EnemySpawner` (host) crée des ennemis via `spawn_function` (données explicites) ; ils sont répliqués comme les autres (`net_*`, `Health`) et le host les supprime à leur mort. Cadavres : état `DEAD` + `Health.health = 0`, le client couche la capsule. États : `Enemy/States/*` exécutés par le host ; le client ne reçoit que `net_state` (label/couleur). Alerte partagée et détection = host seul. Sonde : `tests/net_probe_enemy.gd`.

## Piège connu : ordre de connexion
Le client doit créer son peer **avant** d'ajouter l'arène : la scène existe alors quand les spawns du host arrivent, et `is_server()` est faux dès `_ready()`.

## Tester (deux instances)
Arguments utilisateur après `--` :
```
godot --path . -- --host          # host (ouvre l'arène directement)
godot --path . -- --join=127.0.0.1
godot --path . -- --solo
```
Sans argument : menu de debug (Solo / Host / Join + adresse). Depuis l'éditeur : Debug → Run Multiple Instances (2), ou `project_run` (MCP) pour le host + un exécutable Godot lancé à la main pour le client.
Sonde de vie (journal du client pendant que le host inflige down/réanimation) : `godot --headless --path . --log-file <fichier> -s tests/net_probe_life.gd -- --join=127.0.0.1`.
Sonde de tir : `godot --headless --path . -s tests/net_probe_fire.gd -- --join=127.0.0.1` (le client vise Dummy1 et tire 3 fois ; affiche hits confirmés et santé vue).
Sonde de mouvement (client headless, avance 6 s puis affiche ce qu'il voit) : `godot --headless --path . -s tests/net_probe.gd -- --join=127.0.0.1` pendant qu'un host tourne.
Vérifier : 2 joueurs visibles des deux côtés, positions/orientations cohérentes, déconnexion propre (le client retourne au menu si le host part), solo intact.

## Checkpoints et reset de rencontre
`Checkpoint` (Area3D statique dans l'arène, mêmes chemins chez tous) : seul le host détecte le passage d'un joueur debout et appelle `GameSession.set_checkpoint`, qui envoie le RPC `set_active` (autorité host, `call_local`, fiable) au nouveau et à l'ancien checkpoint (affichage seulement). Le respawn reste ordonné par le host (`Player.respawn_at(GameSession.respawn_position(slot))`, slot = index du joueur sous `Players`, 2 emplacements écartés de `slot_spacing`). Quand le dernier joueur debout tombe (solo, ou tous down), `PlayerLife._respawn` appelle `GameSession.reset_encounter()` : ennemis remis à leur poste (vivants ou morts), renforts supprimés (le `EnemySpawner` les despawn chez le client). Un joueur qui respawn seul (partenaire debout) ne reset rien.

## Latence simulée (test)
`DelayedPeer` (`game/autoload/delayed_peer.gd`, enveloppe du peer ENet créée par `MultiplayerManager`) retarde les paquets SORTANTS de l'instance : `-- --lag=<ms> [--jitter=<ms>]` (ou `MultiplayerManager.lag_ms`/`jitter_ms` avant `_start_host()`). RTT ≈ lag du host + lag du client. Le peer ne réordonne jamais. Mesures (`net_probe_enemy.gd`, 5 tirs sur un ennemi mobile) : sans latence 4/5 ; RTT 100 ms (50+50, gigue 10) 4/5 ; RTT 200 ms (100+100, gigue 30) 4/5 avec `window` 0.3 (2/5 avec 0.15). Vie/down/réanimation sous RTT 260 ms : OK (client voit down puis réanimé à 50 PV).

## À faire plus tard
Validation host du mouvement, GameSession, reconnexion, drop-in (hors MVP initial).
