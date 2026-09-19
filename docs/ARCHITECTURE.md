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
  weapons/ (WeaponData, WeaponController, Tracer, pistol.tres)   components/ (HealthComponent)   ui/ (player_hud)   ai/ missions/ (vides)
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
`WeaponData` (Resource, données seules) → `WeaponController` (enfant `Weapon` de `Player`, logique de tir + RPC) → `HealthComponent` (composant réutilisable, joueur/ennemis/cibles). `MeleeController` (+ `MeleeConfig`) : mêlée, même schéma réseau. `Tracer` = trait cosmétique. HUD local (`game/ui/player_hud`) créé par `Player` pour l'autorité uniquement. Détails réseau : NETWORK.md.

## Vie du joueur
`Player` compose : `Health` (`HealthComponent`), `Life` (`PlayerLife` : down/respawn/réanimation, config `LifeConfig`), `Reviver` (`PlayerReviver` : demande de réanimation côté client). `Player.can_act()` (souris capturée et pas down) conditionne tir et réanimation ; `Player.respawn_at()` replace le joueur. Les marqueurs d'apparition sont dans le groupe `spawn_points` (pas de checkpoints réels pour l'instant).

## Collision layers
1 = monde · 2 = joueurs · 3 = ennemis · 4 = projectiles/hitboxes.

## Autoloads
- `MultiplayerManager` : cycle de vie de la connexion ENet, signaux `player_connected/disconnected`, `connection_failed`, `server_disconnected`. Aucun gameplay.
- `GameSession` (GDD) : **reporté** tant qu'il n'y a ni checkpoints ni état de mission.
- `_mcp_game_helper` : addon godot-ai (ne pas toucher).

## Dette / hypothèses
- `PlayerCrouch` (composant) gère hauteur de collision/tête/mesh ; la géométrie debout (1.8 m / tête 1.6 m) est en constantes, doit rester alignée avec `player.tscn`.
- Interpolation des remotes basique (lerp exponentiel), pas de prédiction ni réconciliation.
- Arène et menu = debug/graybox, jetables.
