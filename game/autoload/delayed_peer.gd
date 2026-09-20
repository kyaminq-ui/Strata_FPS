class_name DelayedPeer
extends MultiplayerPeerExtension
## Enveloppe un MultiplayerPeer et retarde ses paquets SORTANTS (latence + gigue simulées, outil de test).
## RTT ≈ délai du host + délai du client. Activé par MultiplayerManager (--lag=<ms> [--jitter=<ms>]).

var _inner: MultiplayerPeer
var _delay := 0.0  # secondes
var _jitter := 0.0
var _queue: Array[Dictionary] = []  # {due, data, target, channel, mode}, ordre d'envoi conservé
var _target := 0
var _channel := 0
var _mode := MultiplayerPeer.TRANSFER_MODE_RELIABLE
var _last_due := 0.0


func setup(inner: MultiplayerPeer, delay_ms: float, jitter_ms: float) -> DelayedPeer:
	_inner = inner
	_delay = delay_ms / 1000.0
	_jitter = jitter_ms / 1000.0
	inner.peer_connected.connect(func(id: int) -> void: peer_connected.emit(id))
	inner.peer_disconnected.connect(_on_inner_peer_disconnected)
	return self


func _on_inner_peer_disconnected(id: int) -> void:
	_queue.assign(_queue.filter(func(packet: Dictionary) -> bool: return packet.target != id))
	peer_disconnected.emit(id)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _poll() -> void:
	var now := _now()
	while not _queue.is_empty() and _queue[0].due <= now:
		var packet: Dictionary = _queue.pop_front()
		_inner.set_target_peer(packet.target)
		_inner.transfer_channel = packet.channel
		_inner.transfer_mode = packet.mode
		_inner.put_packet(packet.data)
	_inner.poll()


func _put_packet_script(buffer: PackedByteArray) -> Error:
	# Jamais avant le paquet précédent : la gigue ne réordonne pas.
	_last_due = maxf(_now() + _delay + randf() * _jitter, _last_due)
	_queue.append({"due": _last_due, "data": buffer, "target": _target, "channel": _channel, "mode": _mode})
	return OK


func _get_packet_script() -> PackedByteArray:
	return _inner.get_packet()


func _get_available_packet_count() -> int:
	return _inner.get_available_packet_count()


func _get_max_packet_size() -> int:
	return _inner.get_max_packet_size()


func _get_packet_peer() -> int:
	return _inner.get_packet_peer()


func _get_packet_mode() -> MultiplayerPeer.TransferMode:
	return _inner.get_packet_mode()


func _get_packet_channel() -> int:
	return _inner.get_packet_channel()


func _set_target_peer(id: int) -> void:
	_target = id


func _set_transfer_channel(channel: int) -> void:
	_channel = channel


func _get_transfer_channel() -> int:
	return _channel


func _set_transfer_mode(mode: MultiplayerPeer.TransferMode) -> void:
	_mode = mode


func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
	return _mode


func _is_server() -> bool:
	return _inner.is_server()


func _get_unique_id() -> int:
	return _inner.get_unique_id()


func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
	return _inner.get_connection_status()


func _is_server_relay_supported() -> bool:
	return _inner.is_server_relay_supported()


func _set_refuse_new_connections(enable: bool) -> void:
	_inner.refuse_new_connections = enable


func _is_refusing_new_connections() -> bool:
	return _inner.refuse_new_connections


func _disconnect_peer(peer: int, force: bool) -> void:
	_inner.disconnect_peer(peer, force)


func _close() -> void:
	_queue.clear()
	_inner.close()
