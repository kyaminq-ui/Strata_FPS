extends Node
## Cycle de vie de la connexion. Seul endroit qui connaît ENet : pour changer de
## transport (Steam...), remplacer le MultiplayerPeer créé ici. Aucun gameplay.
## Solo = aucun peer (OfflineMultiplayerPeer) : is_server() vrai, id 1.

signal connection_failed
signal server_disconnected

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 1


func _ready() -> void:
	multiplayer.connection_failed.connect(func() -> void: connection_failed.emit())
	multiplayer.server_disconnected.connect(func() -> void: server_disconnected.emit())


func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("Host impossible sur le port %d : %s" % [port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Join impossible vers %s:%d : %s" % [address, port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func leave() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
