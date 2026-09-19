class_name Perception
extends Node
## Perception d'un ennemi (host uniquement) : vision (cône + distance + ligne de vue vers
## chaque joueur vivant) et ouïe (bruits du NoiseBus). Ne décide de rien : expose l'état perçu,
## les états de l'ennemi (tranche 3.3) s'en servent.

signal player_spotted(player: Player)
signal noise_heard(position: Vector3, kind: StringName)
signal body_spotted(position: Vector3)

const WORLD_MASK := 1

var seen_player: Player  # joueur actuellement visible (le plus proche), sinon null
var last_seen_position := Vector3.ZERO

var _enemy: Enemy
var _known_bodies := {}  # cadavres déjà découverts (id d'instance) : un seul déclenchement chacun
var _vision_timer := 0.0


func _ready() -> void:
	_enemy = get_parent() as Enemy
	if not multiplayer.is_server():
		set_physics_process(false)
		return
	add_to_group("perception")
	var bus := get_tree().get_first_node_in_group("noise_bus") as NoiseBus
	if bus:
		bus.noise_emitted.connect(_on_noise)


func _physics_process(delta: float) -> void:
	if _enemy.is_dead():
		seen_player = null
		return
	_vision_timer -= delta
	if _vision_timer > 0.0:
		return
	_vision_timer = _enemy.config.vision_interval
	_scan_players()
	_scan_bodies()


func _scan_players() -> void:
	var config := _enemy.config
	var eye := _enemy.global_position + Vector3.UP * config.eye_height
	var forward := -_enemy.global_transform.basis.z
	var min_dot := cos(deg_to_rad(config.view_fov_degrees * 0.5))
	var space := _enemy.get_world_3d().direct_space_state
	var best: Player = null
	var best_distance := config.view_distance
	for node in get_tree().get_nodes_in_group("players"):
		var player := node as Player
		if player == null or player.health.is_dead():
			continue
		var target := player.global_position + Vector3.UP * config.target_height
		var to_target := target - eye
		var distance := to_target.length()
		if distance > best_distance or forward.dot(to_target / distance) < min_dot:
			continue
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, target, WORLD_MASK)).is_empty():
			continue  # ligne de vue bloquée
		best = player
		best_distance = distance
	if best != null and seen_player == null:
		player_spotted.emit(best)
	seen_player = best
	if best != null:
		last_seen_position = best.global_position


func _scan_bodies() -> void:
	var config := _enemy.config
	var eye := _enemy.global_position + Vector3.UP * config.eye_height
	var forward := -_enemy.global_transform.basis.z
	var min_dot := cos(deg_to_rad(config.view_fov_degrees * 0.5))
	var space := _enemy.get_world_3d().direct_space_state
	for node in get_tree().get_nodes_in_group("enemy_bodies"):
		var body := node as Enemy
		if body == null or body == _enemy or _known_bodies.has(body.get_instance_id()):
			continue
		var target := body.global_position + Vector3.UP * config.body_height
		var to_target := target - eye
		var distance := to_target.length()
		if distance > config.view_distance or forward.dot(to_target / distance) < min_dot:
			continue
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, target, WORLD_MASK)).is_empty():
			continue
		_known_bodies[body.get_instance_id()] = true
		body_spotted.emit(body.global_position)


func forget_body(body: Enemy) -> void:
	_known_bodies.erase(body.get_instance_id())


func _on_noise(position: Vector3, radius: float, kind: StringName) -> void:
	if _enemy.is_dead() or _enemy.global_position.distance_to(position) > radius:
		return
	noise_heard.emit(position, kind)
