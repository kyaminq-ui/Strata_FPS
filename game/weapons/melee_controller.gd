class_name MeleeController
extends Node
## Mêlée d'un joueur : coup rapide au contact, plus fort et de plus longue portée juste
## après un dash, finisseur sur cible affaiblie. Même modèle que le tir : le propriétaire
## lance le coup (animation immédiate) et prévient le HOST, qui résout la cible (cône +
## ligne de vue), valide cadence/origine/tireur, applique les dégâts et confirme.

signal hit_confirmed(killed: bool)
signal swing_started  # coup joué sur ce joueur (soi ou un autre) : animation cosmétique

const ENEMY_MASK := 4  # couche 3
const WORLD_MASK := 1
const HEAD_HEIGHT := 1.6
const TARGET_HEIGHT := 0.9  # centre approximatif d'une cible (pieds + 0.9 m)
const RANGE_SLACK := 0.5  # tient compte du rayon des cibles
const SERVER_ORIGIN_TOLERANCE := 5.0
const SERVER_RATE_TOLERANCE := 0.8
const PUNCH_DISTANCE := 0.25

@export var config: MeleeConfig

var _cooldown_left := 0.0
var _server_last_msec := -100000
var _viewmodel_base := Vector3.ZERO
var _gun_base := Vector3.ZERO
var _tween: Tween

@onready var _player: Player = get_parent()
@onready var _weapon: WeaponController = $"../Weapon"
@onready var _viewmodel: Node3D = _player.get_node("Head/Camera3D/Viewmodel")
@onready var _gun_mesh: Node3D = _player.get_node("Head/GunMesh")


func _ready() -> void:
	_viewmodel_base = _viewmodel.position
	_gun_base = _gun_mesh.position


func _physics_process(delta: float) -> void:
	if not _player.is_multiplayer_authority():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _player.can_act() and _cooldown_left <= 0.0 and Input.is_action_just_pressed("melee"):
		_swing()


func _swing() -> void:
	_cooldown_left = config.cooldown
	_weapon.block_for(config.swing_time)
	_play_swing()
	var camera := _player.camera
	var origin := camera.global_position
	var direction := -camera.global_basis.z
	if multiplayer.is_server():
		_server_melee(multiplayer.get_unique_id(), origin, direction)
	else:
		server_melee.rpc_id(1, origin, direction)


@rpc("any_peer", "call_remote", "reliable")
func server_melee(origin: Vector3, direction: Vector3) -> void:
	if multiplayer.is_server():
		_server_melee(multiplayer.get_remote_sender_id(), origin, direction)


func _server_melee(shooter_id: int, origin: Vector3, direction: Vector3) -> void:
	if shooter_id != _player.get_multiplayer_authority() or direction.is_zero_approx():
		return
	var now := Time.get_ticks_msec()
	if now - _server_last_msec < config.cooldown * 1000.0 * SERVER_RATE_TOLERANCE:
		return
	if origin.distance_to(_player.net_position + Vector3.UP * HEAD_HEIGHT) > SERVER_ORIGIN_TOLERANCE:
		return
	_server_last_msec = now

	var after_dash := _player.net_dashing
	var reach := config.range + (config.dash_range_bonus if after_dash else 0.0)
	var target := _find_target(origin, direction.normalized(), reach)
	var health := target.get_node_or_null("Health") as HealthComponent if target else null
	if health:
		var damage := config.damage * (config.dash_damage_multiplier if after_dash else 1.0)
		if health.health <= health.max_health * config.finisher_health_fraction:
			damage = health.max_health  # finisseur
		if target.has_method("can_be_silenced") and target.can_be_silenced(origin):
			damage = health.max_health  # élimination silencieuse (dans le dos d'un ennemi non alerté)
		var killed := health.take_damage(damage, shooter_id)
		if shooter_id == multiplayer.get_unique_id():
			hit_confirmed.emit(killed)
		else:
			confirm_hit.rpc_id(shooter_id, killed)
	if shooter_id != multiplayer.get_unique_id():
		_play_swing()
	if not multiplayer.get_peers().is_empty():
		show_melee.rpc()


## Cible ennemie la plus proche dans le cône devant `direction`, sans obstacle du monde entre les deux.
func _find_target(origin: Vector3, direction: Vector3, reach: float) -> Node3D:
	var space := _player.get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = reach * 0.5 + RANGE_SLACK
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, origin + direction * reach * 0.5)
	query.collision_mask = ENEMY_MASK
	var min_dot := cos(deg_to_rad(config.half_angle_degrees))
	var best: Node3D = null
	var best_distance := INF
	for result in space.intersect_shape(query, 16):
		var candidate := result.collider as Node3D
		if candidate == null:
			continue
		var center := candidate.global_position + Vector3.UP * TARGET_HEIGHT
		var to_target := center - origin
		var distance := to_target.length()
		if distance > reach + RANGE_SLACK or direction.dot(to_target / distance) < min_dot:
			continue
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, center, WORLD_MASK)).is_empty():
			continue  # mur entre nous
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


@rpc("any_peer", "call_remote", "reliable")
func confirm_hit(killed: bool) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		hit_confirmed.emit(killed)


@rpc("any_peer", "call_remote", "unreliable")
func show_melee() -> void:
	if multiplayer.get_remote_sender_id() == 1 and not _player.is_multiplayer_authority():
		_play_swing()


## Coup cosmétique : le viewmodel (soi) ou le modèle d'arme (autres) part vers l'avant puis revient.
func _play_swing() -> void:
	swing_started.emit()
	var mine := _player.is_multiplayer_authority()
	var view := _viewmodel if mine else _gun_mesh
	var base_z := (_viewmodel_base if mine else _gun_base).z
	if _tween:
		_tween.kill()
	view.position.z = base_z
	_tween = create_tween()
	_tween.tween_property(view, "position:z", base_z - PUNCH_DISTANCE, config.swing_time * 0.4)
	_tween.tween_property(view, "position:z", base_z, config.swing_time * 0.6)
