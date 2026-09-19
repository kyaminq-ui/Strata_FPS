class_name GrenadeThrower
extends Node
## Lancer de grenades d'un joueur. Le propriétaire gère le stock (recharge lente) et demande
## le lancer au HOST, qui valide (tireur, cadence, origine) et fait apparaître la grenade
## via GrenadeSpawner ; la grenade est ensuite simulée par le host et répliquée.

signal count_changed(count: int)

const HEAD_HEIGHT := 1.6
const SPAWN_FORWARD_OFFSET := 0.6
const SERVER_ORIGIN_TOLERANCE := 5.0
const SERVER_RATE_TOLERANCE := 0.8

@export var config: GrenadeConfig

var count := 0

var _cooldown_left := 0.0
var _recharge_left := 0.0
var _server_last_msec := -100000

@onready var _player: Player = get_parent()


func _ready() -> void:
	count = config.max_carried


func _physics_process(delta: float) -> void:
	if not _player.is_multiplayer_authority():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if count < config.max_carried:
		_recharge_left -= delta
		if _recharge_left <= 0.0:
			count += 1
			_recharge_left = config.recharge_time
			count_changed.emit(count)
	if _player.can_act() and count > 0 and _cooldown_left <= 0.0 and Input.is_action_just_pressed("grenade"):
		_throw()


func _throw() -> void:
	if count == config.max_carried:
		_recharge_left = config.recharge_time
	count -= 1
	_cooldown_left = config.throw_cooldown
	count_changed.emit(count)
	var camera := _player.camera
	var origin := camera.global_position
	var direction := -camera.global_basis.z
	if multiplayer.is_server():
		_server_throw(multiplayer.get_unique_id(), origin, direction)
	else:
		server_throw.rpc_id(1, origin, direction)


@rpc("any_peer", "call_remote", "reliable")
func server_throw(origin: Vector3, direction: Vector3) -> void:
	if multiplayer.is_server():
		_server_throw(multiplayer.get_remote_sender_id(), origin, direction)


func _server_throw(thrower_id: int, origin: Vector3, direction: Vector3) -> void:
	if thrower_id != _player.get_multiplayer_authority() or direction.is_zero_approx():
		return
	var now := Time.get_ticks_msec()
	if now - _server_last_msec < config.throw_cooldown * 1000.0 * SERVER_RATE_TOLERANCE:
		return
	if origin.distance_to(_player.net_position + Vector3.UP * HEAD_HEIGHT) > SERVER_ORIGIN_TOLERANCE:
		return
	var spawner := get_tree().get_first_node_in_group("grenade_spawner") as GrenadeSpawner
	if spawner == null:
		return
	_server_last_msec = now
	direction = direction.normalized()
	var velocity := direction * config.throw_speed + Vector3.UP * config.throw_lift
	spawner.throw(origin + direction * SPAWN_FORWARD_OFFSET, velocity, thrower_id)
