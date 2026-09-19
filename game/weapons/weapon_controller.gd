class_name WeaponController
extends Node
## Arme hitscan d'un joueur. Le peer propriétaire gère cadence, munitions et visée locale,
## puis envoie (origine, direction) au host. Le HOST résout le tir (raycast serveur), valide
## cadence et origine, applique les dégâts (valeur de WeaponData, jamais envoyée par le client)
## et confirme le résultat. Traits/hitmarkers = cosmétique local.

signal ammo_changed(current: int, magazine: int)
signal reload_started
signal hit_confirmed(killed: bool)

const HIT_MASK := 1 | 4  # monde (couche 1) + ennemis (couche 3)
const HEAD_HEIGHT := 1.6
const SERVER_ORIGIN_TOLERANCE := 5.0  # m : couvre latence + dash
const SERVER_RATE_TOLERANCE := 0.8  # tolère un peu de gigue sur la cadence
const MUZZLE_OFFSET := Vector3(0.25, -0.2, -0.5)

@export var data: WeaponData

var ammo := 0

var _cooldown_left := 0.0
var _reload_left := 0.0
var _server_last_shot_msec := -100000

@onready var _player: Player = get_parent()


func _ready() -> void:
	ammo = data.magazine_size


func _physics_process(delta: float) -> void:
	if not _player.is_multiplayer_authority():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			ammo = data.magazine_size
			ammo_changed.emit(ammo, data.magazine_size)
		return
	if not _player.can_act():
		return
	if Input.is_action_just_pressed("reload") and ammo < data.magazine_size:
		_start_reload()
		return
	var wants_fire := Input.is_action_pressed("fire") if data.automatic else Input.is_action_just_pressed("fire")
	if wants_fire and _cooldown_left <= 0.0:
		if ammo > 0:
			_fire()
		else:
			_start_reload()


func _start_reload() -> void:
	_reload_left = data.reload_time
	reload_started.emit()


func _fire() -> void:
	ammo -= 1
	_cooldown_left = data.fire_interval
	ammo_changed.emit(ammo, data.magazine_size)
	var camera := _player.camera
	var origin := camera.global_position
	var direction := -camera.global_basis.z
	var hit := _cast(origin, direction)
	var end: Vector3 = hit.position if not hit.is_empty() else origin + direction * data.max_range
	Tracer.spawn(_player.get_parent(), origin + camera.global_basis * MUZZLE_OFFSET, end)
	if multiplayer.is_server():
		_server_fire(multiplayer.get_unique_id(), origin, direction)
	else:
		server_fire.rpc_id(1, origin, direction)


func _cast(origin: Vector3, direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * data.max_range, HIT_MASK)
	return _player.get_world_3d().direct_space_state.intersect_ray(query)


@rpc("any_peer", "call_remote", "reliable")
func server_fire(origin: Vector3, direction: Vector3) -> void:
	if multiplayer.is_server():
		_server_fire(multiplayer.get_remote_sender_id(), origin, direction)


func _server_fire(shooter_id: int, origin: Vector3, direction: Vector3) -> void:
	if shooter_id != _player.get_multiplayer_authority() or direction.is_zero_approx():
		return  # seul le propriétaire tire avec son arme
	var now := Time.get_ticks_msec()
	if now - _server_last_shot_msec < data.fire_interval * 1000.0 * SERVER_RATE_TOLERANCE:
		return
	if origin.distance_to(_player.net_position + Vector3.UP * HEAD_HEIGHT) > SERVER_ORIGIN_TOLERANCE:
		return
	_server_last_shot_msec = now

	direction = direction.normalized()
	var hit := _cast(origin, direction)
	var end: Vector3 = hit.position if not hit.is_empty() else origin + direction * data.max_range
	var health: HealthComponent = null
	if not hit.is_empty():
		health = (hit.collider as Node).get_node_or_null("Health") as HealthComponent
	if health:
		var killed := health.take_damage(data.damage, shooter_id)
		if shooter_id == multiplayer.get_unique_id():
			hit_confirmed.emit(killed)
		else:
			confirm_hit.rpc_id(shooter_id, killed)

	var start := origin + Vector3.DOWN * 0.2 + direction * 0.5
	if shooter_id != multiplayer.get_unique_id():
		Tracer.spawn(_player.get_parent(), start, end)
	if not multiplayer.get_peers().is_empty():
		show_shot.rpc(start, end)


@rpc("any_peer", "call_remote", "reliable")
func confirm_hit(killed: bool) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		hit_confirmed.emit(killed)


@rpc("any_peer", "call_remote", "unreliable")
func show_shot(from: Vector3, to: Vector3) -> void:
	if multiplayer.get_remote_sender_id() == 1 and not _player.is_multiplayer_authority():
		Tracer.spawn(_player.get_parent(), from, to)
