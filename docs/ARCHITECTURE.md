# ARCHITECTURE

Principe : petites scènes, composants réutilisables, config en Resources, signaux plutôt que dépendances fortes.

## Arborescence
```
game/
  main.tscn / main.gd        scène de démarrage : menu de debug, crée le réseau puis charge l'arène
  autoload/                  singletons minces (MultiplayerManager uniquement pour l'instant)
  components/                composants réutilisables (vide pour l'instant)
  player/                    player.tscn/gd, movement_config.gd + default_movement.tres
  multiplayer/               player_spawner.gd
  world/                     arena_graybox.tscn (arène de test)
  weapons/ (WeaponData, WeaponController, Tracer, pistol.tres)   components/ (HealthComponent)   ui/ (player_hud)   ai/ (Enemy, EnemyConfig, EnemyState + états, EnemyAwareness, EnemyWeapon, Perception, NoiseBus, LagCompensator, EnemySpawner + ReinforcementConfig, nav_baker)   missions/ (vide)
assets/{generated,source,approved}   audio/{music,sfx}   tests/   docs/
```

## Flux de démarrage
`main.tscn` (menu) → choix Solo / Host / Join → `MultiplayerManager.host()` ou `.join()` (rien pour Solo) → `main.gd` instancie `arena_graybox.tscn` → `PlayerSpawner` (sur le host / en solo) instancie un `Player` par peer.
Ordre important : le réseau est créé **avant** l'arène, sinon `multiplayer.is_server()` est vrai à tort côté client (peer hors-ligne). Voir NETWORK.md.

## Player
`CharacterBody3D` (`player.gd`), trois couches séparées :

| Couche | Contenu | Où |
|---|---|---|
| État local | input, `velocity`, look | uniquement chez l'autorité |
| État répliqué | `net_position`, `net_yaw`, `net_pitch` | `MultiplayerSynchronizer` |
| Présentation | interpolation des remotes, mesh, label, caméra | tous les peers |

Le mouvement lit **uniquement** `MovementConfig` (Resource). Il est réparti en états enfants de `Player/States` (`PlayerState` : `enter/exit/physics_update`, transitions via `player.change_state(&"Nom")`) : `Walk` (sol + air, saut, coyote, buffer), `Dash`, `Slide`, `WallRun`. `Player` garde les entrées partagées (`wish_dir`, cooldowns), la réplication et la présentation ; `PlayerCrouch` gère la hauteur (collision/tête/mesh). Nouvelle capacité = nouvel état + champs de config.

## Combat
`WeaponData` (Resource, données seules) → `WeaponController` (enfant `Weapon` de `Player`, logique de tir + RPC) → `HealthComponent` (composant réutilisable, joueur/ennemis/cibles). `MeleeController` (+ `MeleeConfig`) : mêlée, même schéma réseau. `GrenadeThrower` + `Grenade` + `GrenadeSpawner` (multiplayer/) : gadget explosif (config `GrenadeConfig`). `Tracer` = trait cosmétique. HUD local (`game/ui/player_hud`) créé par `Player` pour l'autorité uniquement. Détails réseau : NETWORK.md.

## Vie du joueur
`Player` compose : `Health` (`HealthComponent`), `Life` (`PlayerLife` : down/respawn/réanimation, config `LifeConfig`), `Reviver` (`PlayerReviver` : demande de réanimation côté client). `Player.can_act()` (souris capturée et pas down) conditionne tir et réanimation ; `Player.respawn_at()` replace le joueur. Les marqueurs d'apparition sont dans le groupe `spawn_points` ; `Checkpoint` (`game/world/checkpoint.tscn`, Area3D) les remplace dès qu'un joueur en active un.

## Monde (`game/world/`)
`arena_graybox.tscn` et `arena_infiltration.tscn` (arènes de test), `hub_graybox.tscn` et `sector_bas_fonds.tscn` (blockout de la vertical slice, **générés** par `tools/build_bas_fonds.py`), `checkpoint.tscn`, `damage_zone`, `training_dummy`. Brief du secteur : `SECTOR_BRIEF.md`.

## Collision layers
1 = monde · 2 = joueurs · 3 = ennemis · 4 = projectiles/hitboxes.

## Autoloads
- `MultiplayerManager` : cycle de vie de la connexion ENet, signaux `player_connected/disconnected`, `connection_failed`, `server_disconnected`. Aucun gameplay.
- `GameSession` : autoload mince, décidé par le host. Dernier checkpoint actif (`set_checkpoint`), `respawn_position(slot)` (checkpoint sinon marqueurs `spawn_points`), `reset_encounter()` (appelle `reset_encounter` de tous les ennemis). Reset appelé par `main.gd` en entrant/quittant une arène. Le checkpoint y est non typé exprès (dépendance circulaire avec `Checkpoint`). L'état de mission viendra ici (4.4).
- `_mcp_game_helper` : addon godot-ai (ne pas toucher).

## Dette / hypothèses
- `PlayerCrouch` (composant) gère hauteur de collision/tête/mesh ; la géométrie debout (1.8 m / tête 1.6 m) est en constantes, doit rester alignée avec `player.tscn`.
- Interpolation des remotes basique (lerp exponentiel), pas de prédiction ni réconciliation.
- Arène et menu = debug/graybox, jetables.
