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
var net_sliding: bool

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _dash_left := 0.0
var _dash_cooldown_left := 0.0
var _dash_dir := Vector3.ZERO
var _sliding := false
var _slide_left := 0.0
var _slide_speed := 0.0
var _slide_dir := Vector3.ZERO

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _visor_mesh: MeshInstance3D = $Head/VisorMesh
@onready var _label: Label3D = $NameLabel
@onready var _crouch: PlayerCrouch = $Crouch


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

	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0 and (not _sliding or _end_slide()):
		_start_dash(wish_dir)
	if Input.is_action_just_pressed("slide") and _can_start_slide():
		_start_slide()

	if _dash_left > 0.0:
		_update_dash(delta)
	elif _sliding:
		_update_slide(delta, wish_dir)
	else:
		_update_walk(delta, wish_dir)

	move_and_slide()

	net_position = global_position
	net_yaw = rotation.y
	net_pitch = _head.rotation.x
	net_sliding = _sliding


func _update_walk(delta: float, wish_dir: Vector3) -> void:
	if not is_on_floor():
		velocity.y -= config.gravity * delta
	_update_jump(delta)

	var horizontal := Vector2(velocity.x, velocity.z)
	if wish_dir != Vector3.ZERO:
		var accel := config.ground_acceleration if is_on_floor() else config.air_acceleration
		horizontal = horizontal.move_toward(Vector2(wish_dir.x, wish_dir.z) * config.walk_speed, accel * delta)
	elif is_on_floor():
		horizontal = horizontal.move_toward(Vector2.ZERO, config.ground_friction * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y


## Impulsion horizontale courte, au sol ou en l'air. Sans direction voulue : vers l'avant.
func _start_dash(wish_dir: Vector3) -> void:
	_dash_dir = wish_dir if wish_dir != Vector3.ZERO else -global_basis.z
	_dash_dir.y = 0.0
	_dash_dir = _dash_dir.normalized()
	_dash_left = config.dash_duration
	_dash_cooldown_left = config.dash_cooldown


func _update_dash(delta: float) -> void:
	_dash_left -= delta
	velocity = _dash_dir * (config.dash_distance / config.dash_duration)
	if _dash_left <= 0.0:
		velocity = _dash_dir * config.walk_speed


func _jump_velocity() -> float:
	return sqrt(2.0 * config.gravity * config.jump_height)


func _can_start_slide() -> bool:
	var speed := Vector2(velocity.x, velocity.z).length()
	return not _sliding and _dash_left <= 0.0 and is_on_floor() and speed >= config.slide_min_entry_speed


## Glissade qui conserve l'élan : direction figée, vitesse >= slide_speed puis friction.
func _start_slide() -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	_slide_dir = horizontal.normalized()
	_slide_speed = maxf(horizontal.length(), config.slide_speed)
	_slide_left = config.slide_duration
	_sliding = true
	_crouch.crouched = true


## Après slide_duration, on se relève si possible ; sinon on rampe sous l'obstacle (contrôle libre).
func _update_slide(delta: float, wish_dir: Vector3) -> void:
	_slide_left -= delta
	if not is_on_floor():
		velocity.y -= config.gravity * delta
	if Input.is_action_just_pressed("jump") and _end_slide():
		velocity.y = _jump_velocity()  # saut hors du slide : l'élan est conservé
		return
	if (_slide_left <= 0.0 or not is_on_floor()) and _end_slide():
		return
	if _slide_left > 0.0:
		_slide_speed = maxf(_slide_speed - config.slide_friction * delta, 0.0)
		velocity.x = _slide_dir.x * _slide_speed
		velocity.z = _slide_dir.z * _slide_speed
	else:
		velocity.x = wish_dir.x * config.crawl_speed
		velocity.z = wish_dir.z * config.crawl_speed


## Termine le slide si la place permet de se relever (sinon on reste accroupi sous l'obstacle).
func _end_slide() -> bool:
	if not _crouch.can_stand():
		return false
	_sliding = false
	_crouch.crouched = false
	return true


func _update_jump(delta: float) -> void:
	_coyote_left = config.coyote_time if is_on_floor() else maxf(_coyote_left - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = config.jump_buffer_time
	else:
		_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = _jump_velocity()
		_jump_buffer_left = 0.0
		_coyote_left = 0.0


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	_crouch.crouched = net_sliding
	var t := 1.0 - exp(-REMOTE_SMOOTHING * delta)
	global_position = global_position.lerp(net_position, t)
	rotation.y = lerp_angle(rotation.y, net_yaw, t)
	_head.rotation.x = lerp_angle(_head.rotation.x, net_pitch, t)
