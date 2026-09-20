extends Node
## Cycle de vie de la connexion. Seul endroit qui connaît ENet : pour changer de
## transport (Steam...), remplacer le MultiplayerPeer créé ici. Aucun gameplay.
## Solo = aucun peer (OfflineMultiplayerPeer) : is_server() vrai, id 1.

signal connection_failed
signal server_disconnected

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 1

## Latence simulée sur les paquets sortants de CETTE instance (test) : --lag=<ms> [--jitter=<ms>].
var lag_ms := 0.0
var jitter_ms := 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lag="):
			lag_ms = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--jitter="):
			jitter_ms = arg.get_slice("=", 1).to_float()
	multiplayer.connection_failed.connect(func() -> void: connection_failed.emit())
	multiplayer.server_disconnected.connect(func() -> void: server_disconnected.emit())


func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("Host impossible sur le port %d : %s" % [port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = _with_lag(peer)
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Join impossible vers %s:%d : %s" % [address, port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = _with_lag(peer)
	return OK


func _with_lag(peer: MultiplayerPeer) -> MultiplayerPeer:
	if lag_ms <= 0.0:
		return peer
	return DelayedPeer.new().setup(peer, lag_ms, jitter_ms)


func leave() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
