class_name Player
extends CharacterBody3D
## Joueur FPS. Trois couches :
##  - état local (input, velocity) : simulé uniquement par l'autorité (le peer propriétaire) ;
##  - état répliqué (net_*) : écrit par l'autorité, lu par les autres via MultiplayerSynchronizer ;
##  - présentation (interpolation, meshes, label) : tous les peers.
## L'autorité = peer id porté par le nom du nœud, posé par PlayerSpawner.

const REMOTE_SMOOTHING := 18.0
const HOST_COLOR := Color(0.1, 0.8, 1.0)
const GUEST_COLOR := Color(1.0, 0.25, 0.7)

@export var config: MovementConfig

var net_position: Vector3
var net_yaw: float
var net_pitch: float

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _visor_mesh: MeshInstance3D = $Head/VisorMesh
@onready var _label: Label3D = $NameLabel


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = HOST_COLOR if name.to_int() == 1 else GUEST_COLOR
	_body_mesh.material_override = material
	_visor_mesh.material_override = material
	_label.text = "P" + name
	_label.modulate = material.albedo_color

	# La position de spawn arrive via net_* (réplication au spawn) : l'appliquer partout.
	position = net_position
	rotation.y = net_yaw
	_head.rotation.x = net_pitch

	if is_multiplayer_authority():
		# Vue à la première personne : son propre corps est masqué.
		_camera.current = true
		_body_mesh.hide()
		_visor_mesh.hide()
		_label.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * config.mouse_sensitivity
		var limit := deg_to_rad(config.max_pitch_degrees)
		_head.rotation.x = clampf(_head.rotation.x - event.relative.y * config.mouse_sensitivity, -limit, limit)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := (global_basis * Vector3(input.x, 0.0, input.y)).normalized()

	if not is_on_floor():
		velocity.y -= config.gravity * delta

	var horizontal := Vector2(velocity.x, velocity.z)
	if wish_dir != Vector3.ZERO:
		var accel := config.ground_acceleration if is_on_floor() else config.air_acceleration
		horizontal = horizontal.move_toward(Vector2(wish_dir.x, wish_dir.z) * config.walk_speed, accel * delta)
	elif is_on_floor():
		horizontal = horizontal.move_toward(Vector2.ZERO, config.ground_friction * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y

	move_and_slide()

	net_position = global_position
	net_yaw = rotation.y
	net_pitch = _head.rotation.x


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	var t := 1.0 - exp(-REMOTE_SMOOTHING * delta)
	global_position = global_position.lerp(net_position, t)
	rotation.y = lerp_angle(rotation.y, net_yaw, t)
	_head.rotation.x = lerp_angle(_head.rotation.x, net_pitch, t)
