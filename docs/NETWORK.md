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
| IA, objectifs, boss, dégâts ennemis, loot | Host (à venir) |
| VFX, audio | Local |

Client-authoritative pour le mouvement : choix simple et fluide pour du coop non compétitif. Validation host (anti-téléport, dégâts) à ajouter avec le combat.

## Réplication du joueur
`MultiplayerSynchronizer` réplique `net_position`, `net_yaw`, `net_pitch` (mode « toujours », unreliable). Le peer autoritaire écrit ces valeurs après `move_and_slide()` ; les autres peers interpolent visuellement (`player.gd::_process`).

## Spawn
`PlayerSpawner` (nœud dans l'arène) : le host appelle `spawn({peer_id, position})` ; `spawn_function` crée `player.tscn` nommé `str(peer_id)` sous `Players` sur tous les peers avec les mêmes données. (Piège : la réplication `spawn = true` des propriétés n'est pas envoyée quand l'autorité est le client, d'où les données explicites.) L'autorité est déduite du nom du nœud (`_enter_tree`), donc aucun état « joueur 1 » implicite.

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
Sonde automatisée (client headless, avance 6 s puis affiche ce qu'il voit) : `godot --headless --path . -s tests/net_probe.gd -- --join=127.0.0.1` pendant qu'un host tourne.
Vérifier : 2 joueurs visibles des deux côtés, positions/orientations cohérentes, déconnexion propre (le client retourne au menu si le host part), solo intact.

## À faire plus tard
Latence artificielle de test, validation host du mouvement, GameSession, reconnexion, drop-in (hors MVP initial).
