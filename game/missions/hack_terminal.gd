class_name HackTerminal
extends StaticBody3D
## Objectif « pirater » : maintenir « interact » à portée. Schéma du réanimateur : le joueur local prévient
## le host (request_hack), le HOST valide portée/vie et fait progresser la jauge, puis la diffuse (cosmétique).
## Un seul joueur suffit (pas d'objectif qui exige deux joueurs). Silencieux : le risque est d'être vu.

signal hacked

@export var config: HackConfig
@export var prompt_text := "[F] Pirater"
@export var progress_text := "PIRATAGE"
@export var done_text := "TERMINAL PIRATÉ"

var progress := 0.0  # 0..1
var done := false

var _hackers: Dictionary[int, bool] = {}  # host : peer_id -> actif
var _local_active := false
var _sync_left := 0.0

@onready var _label: Label3D = $Label


func _physics_process(delta: float) -> void:
	_update_local()
	if multiplayer.is_server():
		_update_host(delta)


func _process(_delta: float) -> void:
	if done:
		_label.text = done_text
	elif progress > 0.0:
		_label.text = "%s %d%%" % [progress_text, roundi(progress * 100.0)]
	else:
		_label.text = prompt_text


@rpc("any_peer", "call_remote", "reliable")
func request_hack(active: bool) -> void:
	if multiplayer.is_server():
		set_hacker(multiplayer.get_remote_sender_id(), active)


func set_hacker(peer_id: int, active: bool) -> void:
	_hackers[peer_id] = active


@rpc("authority", "call_remote", "unreliable")
func sync_state(value: float, is_done: bool) -> void:
	progress = value
	done = is_done


func _update_local() -> void:
	var player := _local_player()
	var wanted := player != null and not done and player.can_act() \
			and player.global_position.distance_to(global_position) <= config.range \
			and Input.is_action_pressed("interact")
	if wanted == _local_active:
		return
	_local_active = wanted
	if multiplayer.is_server():
		set_hacker(multiplayer.get_unique_id(), wanted)
	else:
		request_hack.rpc_id(1, wanted)


func _update_host(delta: float) -> void:
	if done:
		return
	if _valid_hacker_count() > 0:
		progress = minf(progress + delta / config.hack_time, 1.0)
	else:
		progress = maxf(progress - delta / config.decay_time, 0.0)
	if progress >= 1.0:
		done = true
		hacked.emit()
	_sync_left -= delta
	if _sync_left <= 0.0 or done:
		_sync_left = config.sync_interval
		sync_state.rpc(progress, done)


func _valid_hacker_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("players"):
		var player := node as Player
		if player != null and _hackers.get(player.name.to_int(), false) and not player.life.downed \
				and player.net_position.distance_to(global_position) <= config.range * config.server_tolerance:
			count += 1
	return count


func _local_player() -> Player:
	for node in get_tree().get_nodes_in_group("players"):
		var player := node as Player
		if player != null and player.is_multiplayer_authority():
			return player
	return null
