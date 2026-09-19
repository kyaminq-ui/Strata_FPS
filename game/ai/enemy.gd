class_name Enemy
extends CharacterBody3D
## Ennemi de base (tranche 3.1). Simulé UNIQUEMENT par le host (patrouille, mort, respawn) ;
## les clients interpolent `net_position` / `net_yaw` et affichent `Health.health` (répliqués).

const BASE_COLOR := Color(0.85, 0.15, 0.15)
const FLASH_COLOR := Color(1.0, 1.0, 1.0)

@export var config: EnemyConfig
## Nœud dont les enfants Marker3D forment la route de patrouille (boucle).
@export var route: Node3D

var net_position: Vector3
var net_yaw: float
var net_state: String = "PATROL"

var _waypoints: Array[Vector3] = []
var _wp_index := 0
var _wait_left := 0.0
var _home := Vector3.ZERO
var _layer := 0
var _last_health := -1.0
var _material := StandardMaterial3D.new()

@onready var _health: HealthComponent = $Health
@onready var _perception: Perception = $Perception
@onready var _agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label


func _ready() -> void:
	_layer = collision_layer
	_material.albedo_color = BASE_COLOR
	_mesh.material_override = _material
	_health.max_health = config.max_health
	_health.reset()
	_home = global_position
	net_position = _home
	net_yaw = rotation.y
	if not multiplayer.is_server():
		return
	_health.died.connect(_on_died)
	if route:
		for marker in route.get_children():
			if marker is Marker3D:
				_waypoints.append(marker.global_position)
	if not _waypoints.is_empty():
		_agent.target_position = _waypoints[0]


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or _health.is_dead():
		return
	velocity.y = velocity.y - config.gravity * delta if not is_on_floor() else 0.0
	var wish := _patrol_direction(delta)
	_show_perception()
	velocity.x = wish.x * config.walk_speed
	velocity.z = wish.z * config.walk_speed
	if wish != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-wish.x, -wish.z), config.turn_speed * delta)
	move_and_slide()
	net_position = global_position
	net_yaw = rotation.y


func _process(delta: float) -> void:
	var health := _health.health
	_mesh.visible = health > 0.0
	_label.visible = health > 0.0
	_label.text = "%s %d" % [net_state, ceili(health)]
	if _last_health > health and health > 0.0:
		_material.albedo_color = FLASH_COLOR
		create_tween().tween_property(_material, "albedo_color", BASE_COLOR, config.flash_time)
	_last_health = health
	if multiplayer.is_server():
		return
	if health <= 0.0:
		global_position = net_position
		return
	var t := 1.0 - exp(-config.net_smoothing * delta)
	global_position = global_position.lerp(net_position, t)
	rotation.y = lerp_angle(rotation.y, net_yaw, t)


func is_dead() -> bool:
	return _health.is_dead()


## Debug 3.2 : l'état affiché reflète ce que l'ennemi perçoit (les vrais états arrivent en 3.3).
func _show_perception() -> void:
	if _perception.seen_player:
		net_state = "SEES"
	elif _perception.heard_time_left > 0.0:
		net_state = "HEARD"


## Direction horizontale voulue (zéro = à l'arrêt/en attente).
func _patrol_direction(delta: float) -> Vector3:
	if _waypoints.is_empty():
		net_state = "IDLE"
		return Vector3.ZERO
	if _wait_left > 0.0:
		_wait_left -= delta
		net_state = "WAIT"
		return Vector3.ZERO
	net_state = "PATROL"
	var flat_to_target := _waypoints[_wp_index] - global_position
	flat_to_target.y = 0.0
	# « navigation terminée » couvre un waypoint hors navmesh (le chemin s'arrête au bord).
	if flat_to_target.length() <= config.waypoint_tolerance or _agent.is_navigation_finished():
		_wp_index = (_wp_index + 1) % _waypoints.size()
		_agent.target_position = _waypoints[_wp_index]
		_wait_left = config.wait_time
		return Vector3.ZERO
	var next := _agent.get_next_path_position() - global_position
	next.y = 0.0
	return next.normalized()


func _on_died(_by_peer: int) -> void:
	collision_layer = 0
	net_state = "DEAD"
	await get_tree().create_timer(config.respawn_delay).timeout
	_health.reset()
	global_position = _home
	net_position = _home
	_wp_index = 0
	_wait_left = 0.0
	if not _waypoints.is_empty():
		_agent.target_position = _waypoints[0]
	collision_layer = _layer
