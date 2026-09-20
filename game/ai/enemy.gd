class_name Enemy
extends CharacterBody3D
## Ennemi (host-autoritaire). Simulé UNIQUEMENT par le host : perception, états (Calm → Suspicious →
## Alert → Combat, enfants de $States), mort, respawn. Les clients interpolent `net_position` /
## `net_yaw` et affichent `net_state` + `Health.health` (répliqués).

const FLASH_COLOR := Color(1.0, 1.0, 1.0)
const CORPSE_COLOR := Color(0.3, 0.3, 0.32)
const CORPSE_ROTATION_X := -PI / 2.0  # capsule couchée
const CORPSE_Y := 0.45  # rayon de la capsule
const STANDING_Y := 0.9
const STATE_COLORS := {
	"CALM": Color(0.7, 0.7, 0.7),
	"SUSPICIOUS": Color(1.0, 0.9, 0.2),
	"ALERT": Color(1.0, 0.55, 0.1),
	"COMBAT": Color(1.0, 0.15, 0.15),
	"DEAD": Color(0.4, 0.4, 0.4),
}

signal was_reset  # remis à son poste (reset de rencontre / respawn) : le boss repasse en phase 1

@export var config: EnemyConfig
## Nœud dont les enfants Marker3D forment la route de patrouille (boucle).
@export var route: Node3D
## Faux pour les renforts : pas de respawn, le cadavre disparaît après `respawn_delay`.
var respawns := true

var net_position: Vector3
var net_yaw: float
var net_state: String = "CALM"

var waypoints: Array[Vector3] = []
var wp_index := 0
var state_name: StringName = &"Calm"

var _states := {}
var _state: EnemyState
var _home := Vector3.ZERO
var _layer := 0
var _last_health := -1.0
var _was_dead := false
var _material := StandardMaterial3D.new()

@onready var perception: Perception = $Perception
@onready var awareness: EnemyAwareness = $Awareness
@onready var weapon: EnemyWeapon = $Weapon
@onready var _lag_comp: LagCompensator = $LagComp
@onready var _health: HealthComponent = $Health
@onready var _agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label


func _ready() -> void:
	add_to_group("enemies")
	_layer = collision_layer
	_material.albedo_color = config.body_color
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
				waypoints.append(marker.global_position)
	for state: EnemyState in $States.get_children():
		state.enemy = self
		_states[state.name] = state
	change_state(&"Calm")


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or _health.is_dead():
		return
	velocity = Vector3(0.0, velocity.y - config.gravity * delta if not is_on_floor() else 0.0, 0.0)
	_state.physics_update(delta)
	move_and_slide()
	net_position = global_position
	net_yaw = rotation.y


func _process(delta: float) -> void:
	var health := _health.health
	var dead := health <= 0.0
	_label.visible = not dead
	_label.text = "%s %s %d" % [config.display_name, net_state, ceili(health)]
	_label.modulate = STATE_COLORS.get(net_state, Color.WHITE)
	_mesh.rotation.x = CORPSE_ROTATION_X if dead else 0.0  # le cadavre reste visible, couché
	_mesh.position.y = CORPSE_Y if dead else STANDING_Y
	if dead:
		_material.albedo_color = CORPSE_COLOR
	elif _was_dead:
		_material.albedo_color = config.body_color
	elif _last_health > health:
		_material.albedo_color = FLASH_COLOR
		create_tween().tween_property(_material, "albedo_color", config.body_color, config.flash_time)
	_was_dead = dead
	_last_health = health
	if multiplayer.is_server():
		return
	if health <= 0.0:
		global_position = net_position
		return
	var t := 1.0 - exp(-config.net_smoothing * delta)
	global_position = global_position.lerp(net_position, t)
	rotation.y = lerp_angle(rotation.y, net_yaw, t)


func change_state(new_state: StringName) -> void:
	if _state:
		_state.exit()
	_state = _states[new_state]
	state_name = new_state
	net_state = String(new_state).to_upper()
	_state.enter()


func is_dead() -> bool:
	return _health.is_dead()


## Élimination silencieuse (contrat lu par la mêlée) : ennemi non alerté attaqué dans le dos.
func can_be_silenced(from: Vector3) -> bool:
	if not config.silent_takedown or _health.is_dead() or not awareness.is_unaware():
		return false
	var to_attacker := (from - global_position) * Vector3(1.0, 0.0, 1.0)
	return (-global_basis.z).dot(to_attacker.normalized()) <= config.takedown_back_dot


## Avance vers `target` par la navigation (met `velocity` horizontale, oriente l'ennemi).
## Retourne vrai quand la cible est atteinte (ou que le chemin s'arrête au bord du navmesh).
func move_to(target: Vector3, speed: float, delta: float) -> bool:
	var flat := target - global_position
	flat.y = 0.0
	if flat.length() <= config.waypoint_tolerance:
		return true
	var retargeted := _agent.target_position.distance_to(target) > config.retarget_distance
	if retargeted:
		_agent.target_position = target
	elif _agent.is_navigation_finished():
		return true
	var next := _agent.get_next_path_position() - global_position
	next.y = 0.0
	var direction := next.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), config.turn_speed * delta)
	return false


func face_point(point: Vector3, delta: float) -> void:
	var to := point - global_position
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), config.turn_speed * delta)


func _on_died(_by_peer: int) -> void:
	collision_layer = 0
	net_state = "DEAD"
	add_to_group("enemy_bodies")
	await get_tree().create_timer(config.respawn_delay).timeout
	if not _health.is_dead():
		return  # déjà remis à zéro par reset_encounter()
	if not respawns:
		queue_free()
		return
	_reset()


## Host : la rencontre repart de zéro (renforts supprimés, ennemis remis à leur poste, vivants ou morts).
func reset_encounter() -> void:
	if not respawns:
		queue_free()
	else:
		_reset()


func _reset() -> void:
	remove_from_group("enemy_bodies")
	get_tree().call_group("perception", "forget_body", self)
	_health.reset()
	global_position = _home
	net_position = _home
	wp_index = 0
	_lag_comp.clear()
	awareness.reset()
	change_state(&"Calm")
	collision_layer = _layer
	was_reset.emit()


## Change de config en cours de partie (phases du boss) : valeurs de combat et couleur. Appelé chez tous les pairs.
func apply_config(new_config: EnemyConfig) -> void:
	config = new_config
	_material.albedo_color = config.body_color
