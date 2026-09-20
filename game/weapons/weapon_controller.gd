class_name WeaponController
extends Node
## Armes hitscan d'un joueur (loadout, munitions par arme, changement d'arme). Le peer
## propriétaire gère cadence, munitions et visée locale, puis envoie (arme, origine, direction,
## graine) au host. Le HOST résout le tir : mêmes plombs que le client (graine partagée),
## raycasts serveur, validation arme/cadence/origine/tireur, dégâts de WeaponData (jamais
## envoyés par le client), confirmation au tireur. Traits, flash, viewmodel = cosmétique.

signal ammo_changed(current: int, magazine: int)
signal weapon_changed(weapon: WeaponData)
signal reload_started
signal hit_confirmed(killed: bool)

const HIT_MASK := 1 | 4 | 8  # monde (couche 1) + ennemis (couche 3) + projectiles (couche 4)
const ENEMY_LAYER := 4
const HEAD_HEIGHT := 1.6
const SERVER_ORIGIN_TOLERANCE := 5.0  # m : couvre latence + dash
const SERVER_RATE_TOLERANCE := 0.8  # tolère un peu de gigue sur la cadence
const FLASH_DURATION := 0.05

@export var loadout: Array[WeaponData] = []

var current := 0
var data: WeaponData:
	get:
		return loadout[current]
var ammo: int:
	get:
		return _ammo[current]

var _ammo: Array[int] = []
var _cooldown_left := 0.0
var _reload_left := 0.0
var _server_last_shot_msec := -100000

@onready var _player: Player = get_parent()
@onready var _viewmodel: MeshInstance3D = _player.get_node("Head/Camera3D/Viewmodel")
@onready var _gun_mesh: MeshInstance3D = _player.get_node("Head/GunMesh")
@onready var _flash_first_person: Node3D = _viewmodel.get_node("Flash")
@onready var _flash_third_person: Node3D = _gun_mesh.get_node("Flash")


func _ready() -> void:
	for weapon in loadout:
		_ammo.append(weapon.magazine_size)
	for view: MeshInstance3D in [_viewmodel, _gun_mesh]:
		view.mesh = view.mesh.duplicate()  # sous-ressource partagée entre instances
		view.material_override = StandardMaterial3D.new()
	_apply_visuals()


func _process(_delta: float) -> void:
	# Autres joueurs : suivre l'arme équipée répliquée.
	if not _player.is_multiplayer_authority() and _player.net_weapon != current:
		_set_current(_player.net_weapon)


func _physics_process(delta: float) -> void:
	if not _player.is_multiplayer_authority():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _player.can_act():
		_handle_switch_input()
	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_ammo[current] = data.magazine_size
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


## Empêche de tirer pendant `seconds` (ex. coup de mêlée).
func block_for(seconds: float) -> void:
	_cooldown_left = maxf(_cooldown_left, seconds)


func _handle_switch_input() -> void:
	if Input.is_action_just_pressed("weapon_1"):
		equip(0)
	elif Input.is_action_just_pressed("weapon_2"):
		equip(1)
	elif Input.is_action_just_pressed("weapon_next"):
		equip((current + 1) % loadout.size())


## Propriétaire : change d'arme (annule le rechargement), répliqué via net_weapon.
func equip(index: int) -> void:
	if index == current or index < 0 or index >= loadout.size():
		return
	_reload_left = 0.0
	_set_current(index)
	_cooldown_left = data.equip_time
	_player.net_weapon = index
	ammo_changed.emit(ammo, data.magazine_size)


func _set_current(index: int) -> void:
	current = clampi(index, 0, loadout.size() - 1)
	_apply_visuals()
	weapon_changed.emit(data)


func _apply_visuals() -> void:
	var weapon := data
	for pair: Array in [[_viewmodel, _flash_first_person], [_gun_mesh, _flash_third_person]]:
		var view: MeshInstance3D = pair[0]
		(view.mesh as BoxMesh).size = weapon.view_size
		(view.material_override as StandardMaterial3D).albedo_color = weapon.view_color
		(pair[1] as Node3D).position.z = -weapon.view_size.z * 0.5 - 0.03


func _start_reload() -> void:
	_reload_left = data.reload_time
	reload_started.emit()


func _fire() -> void:
	_ammo[current] -= 1
	_cooldown_left = data.fire_interval
	ammo_changed.emit(ammo, data.magazine_size)
	var camera := _player.camera
	var origin := camera.global_position
	var direction := -camera.global_basis.z
	var seed_value := randi()
	var muzzle := origin + camera.global_basis * Vector3(0.25, -0.2, -0.3 - data.view_size.z * 0.5)
	for pellet_direction in pellet_directions(direction, data, seed_value):
		var hit := _cast(origin, pellet_direction, data.max_range)
		var end: Vector3 = hit.position if not hit.is_empty() else origin + pellet_direction * data.max_range
		Tracer.spawn(_player.get_parent(), muzzle, end)
	_flash()
	if multiplayer.is_server():
		_server_fire(multiplayer.get_unique_id(), current, origin, direction, seed_value)
	else:
		server_fire.rpc_id(1, current, origin, direction, seed_value)


## Directions des plombs : tirage déterministe selon la graine (client et host obtiennent les mêmes).
static func pellet_directions(direction: Vector3, weapon: WeaponData, seed_value: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if weapon.pellets <= 1 and weapon.spread_degrees <= 0.0:
		result.append(direction)
		return result
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var right := direction.cross(Vector3.UP)
	right = right.normalized() if right.length_squared() > 0.0001 else Vector3.RIGHT
	var up := right.cross(direction).normalized()
	var max_radius := tan(deg_to_rad(weapon.spread_degrees))
	for i in weapon.pellets:
		var angle := rng.randf() * TAU
		var radius := max_radius * sqrt(rng.randf())
		result.append((direction + right * cos(angle) * radius + up * sin(angle) * radius).normalized())
	return result


## Résolution host d'un plomb : {end, health}. Pour un tireur distant, les ennemis sont testés à leur
## position passée (LagCompensator) et non par physique ; le monde et les projectiles restent physiques.
func _resolve_pellet(origin: Vector3, direction: Vector3, max_range: float, remote_shooter: bool) -> Dictionary:
	var mask := HIT_MASK & ~ENEMY_LAYER if remote_shooter else HIT_MASK
	var hit := _cast(origin, direction, max_range, mask)
	var distance := origin.distance_to(hit.position) if not hit.is_empty() else max_range
	var health: Node = null
	if not hit.is_empty():
		health = (hit.collider as Node).get_node_or_null("Health")
	if remote_shooter:
		for comp: LagCompensator in get_tree().get_nodes_in_group("lag_comp"):
			var enemy_distance := comp.ray_hit_distance(origin, direction, distance)
			if enemy_distance >= 0.0 and enemy_distance < distance:
				distance = enemy_distance
				health = comp.get_parent().get_node("Health")
	return {"end": origin + direction * distance, "health": health}


func _cast(origin: Vector3, direction: Vector3, max_range: float, mask: int = HIT_MASK) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_range, mask)
	return _player.get_world_3d().direct_space_state.intersect_ray(query)


@rpc("any_peer", "call_remote", "reliable")
func server_fire(weapon_index: int, origin: Vector3, direction: Vector3, seed_value: int) -> void:
	if multiplayer.is_server():
		_server_fire(multiplayer.get_remote_sender_id(), weapon_index, origin, direction, seed_value)


func _server_fire(shooter_id: int, weapon_index: int, origin: Vector3, direction: Vector3, seed_value: int) -> void:
	if shooter_id != _player.get_multiplayer_authority() or direction.is_zero_approx():
		return  # seul le propriétaire tire avec son arme
	if weapon_index < 0 or weapon_index >= loadout.size():
		return
	var weapon := loadout[weapon_index]
	var now := Time.get_ticks_msec()
	if now - _server_last_shot_msec < weapon.fire_interval * 1000.0 * SERVER_RATE_TOLERANCE:
		return
	if origin.distance_to(_player.net_position + Vector3.UP * HEAD_HEIGHT) > SERVER_ORIGIN_TOLERANCE:
		return
	_server_last_shot_msec = now
	NoiseBus.emit_at(get_tree(), origin, weapon.noise_radius, NoiseBus.GUNSHOT)

	direction = direction.normalized()
	var ends := PackedVector3Array()
	var any_hit := false
	var killed := false
	var remote_shooter := shooter_id != multiplayer.get_unique_id()
	for pellet_direction in pellet_directions(direction, weapon, seed_value):
		var shot := _resolve_pellet(origin, pellet_direction, weapon.max_range, remote_shooter)
		ends.append(shot.end)
		var health := shot.health as HealthComponent
		if health:
			any_hit = true
			killed = health.take_damage(weapon.damage, shooter_id) or killed
	if any_hit:
		if shooter_id == multiplayer.get_unique_id():
			hit_confirmed.emit(killed)
		else:
			confirm_hit.rpc_id(shooter_id, killed)

	var start := origin + Vector3.DOWN * 0.2 + direction * 0.5
	if shooter_id != multiplayer.get_unique_id():
		_show_tracers(start, ends)
		_flash()
	if not multiplayer.get_peers().is_empty():
		show_shot.rpc(start, ends)


@rpc("any_peer", "call_remote", "reliable")
func confirm_hit(killed: bool) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		hit_confirmed.emit(killed)


@rpc("any_peer", "call_remote", "unreliable")
func show_shot(from: Vector3, ends: PackedVector3Array) -> void:
	if multiplayer.get_remote_sender_id() == 1 and not _player.is_multiplayer_authority():
		_show_tracers(from, ends)
		_flash()


func _show_tracers(from: Vector3, ends: PackedVector3Array) -> void:
	for end in ends:
		Tracer.spawn(_player.get_parent(), from, end)


## Flash de bouche cosmétique : viewmodel pour le tireur, modèle 3e personne pour les autres.
func _flash() -> void:
	var flash := _flash_first_person if _player.is_multiplayer_authority() else _flash_third_person
	flash.show()
	get_tree().create_timer(FLASH_DURATION).timeout.connect(flash.hide)
