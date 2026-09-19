class_name Player
extends CharacterBody3D
## Joueur FPS. Trois couches :
##  - état local (input, velocity, machine à états de mouvement) : simulé uniquement par l'autorité ;
##  - état répliqué (net_*) : écrit par l'autorité, lu par les autres via MultiplayerSynchronizer ;
##  - présentation (interpolation, meshes, label, roulis caméra) : tous les peers.
## L'autorité = peer id porté par le nom du nœud, posé par PlayerSpawner.
## Le mouvement vit dans les états enfants de $States (Walk, Dash, Slide, WallRun).

const REMOTE_SMOOTHING := 18.0
const CAMERA_ROLL_SMOOTHING := 12.0
const HOST_COLOR := Color(0.1, 0.8, 1.0)
const GUEST_COLOR := Color(1.0, 0.25, 0.7)

@export var config: MovementConfig

var net_position: Vector3
var net_yaw: float
var net_pitch: float
var net_crouched: bool
var net_weapon := 0  # index dans WeaponController.loadout
var net_dashing := false  # dash récent (fenêtre dash -> mêlée), lu par le host

## Lus par les états de mouvement (autorité seulement).
var wish_dir := Vector3.ZERO
var dash_cooldown_left := 0.0
var wall_cooldown_left := 0.0
var camera_roll_target := 0.0  # degrés, piloté par les états
var input_enabled := true  # faux quand la souris est libérée (Échap)

var _states: Dictionary[StringName, PlayerState] = {}
var _state: PlayerState

@onready var crouch: PlayerCrouch = $Crouch
@onready var weapon: WeaponController = $Weapon
@onready var melee: MeleeController = $Melee
@onready var grenades: GrenadeThrower = $Grenades
@onready var health: HealthComponent = $Health
@onready var life: PlayerLife = $Life
@onready var reviver: PlayerReviver = $Reviver
@onready var _head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _visor_mesh: MeshInstance3D = $Head/VisorMesh
@onready var _label: Label3D = $NameLabel


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	$SyncServer.set_multiplayer_authority(1)  # vie/down : répliqués par le host


func _ready() -> void:
	add_to_group("players")
	var material := StandardMaterial3D.new()
	material.albedo_color = HOST_COLOR if name.to_int() == 1 else GUEST_COLOR
	_body_mesh.material_override = material
	_visor_mesh.material_override = material
	_label.text = "P" + name
	_label.modulate = material.albedo_color

	for state: PlayerState in $States.get_children():
		state.player = self
		_states[state.name] = state
	change_state(&"Walk")

	# La position de spawn arrive via net_* (réplication au spawn) : l'appliquer partout.
	position = net_position
	rotation.y = net_yaw
	_head.rotation.x = net_pitch

	if is_multiplayer_authority():
		# Vue à la première personne : son propre corps est masqué.
		camera.current = true
		_body_mesh.hide()
		_visor_mesh.hide()
		_label.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var hud := preload("res://game/ui/player_hud.tscn").instantiate()
		add_child(hud)
		hud.bind(self)
		life.downed_changed.connect(_on_downed_changed)
	# Arme : viewmodel pour soi, modèle à la 3e personne pour les autres.
	$Head/Camera3D/Viewmodel.visible = is_multiplayer_authority()
	$Head/GunMesh.visible = not is_multiplayer_authority()


func change_state(state_name: StringName) -> void:
	if _state:
		_state.exit()
	_state = _states[state_name]
	_state.enter()


func get_state(state_name: StringName) -> PlayerState:
	return _states[state_name]


## Peut agir (bouger volontairement, tirer, réanimer) : souris capturée et pas down.
func can_act() -> bool:
	return input_enabled and not life.downed


## Host : replace le joueur (respawn). Le propriétaire simule sa position, donc on le lui demande.
func respawn_at(pos: Vector3) -> void:
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		_teleport(pos)
	else:
		teleport.rpc_id(get_multiplayer_authority(), pos)


@rpc("any_peer", "call_remote", "reliable")
func teleport(pos: Vector3) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		_teleport(pos)


func _teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	net_position = pos


func _on_downed_changed(downed: bool) -> void:
	if downed:
		change_state(&"Walk")  # quitte proprement slide / wall-run
	crouch.crouched = downed


func wants_dash() -> bool:
	return dash_cooldown_left <= 0.0 and Input.is_action_just_pressed("dash")


func jump_velocity() -> float:
	return sqrt(2.0 * config.gravity * config.jump_height)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= config.gravity * delta


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * config.mouse_sensitivity
		var limit := deg_to_rad(config.max_pitch_degrees)
		_head.rotation.x = clampf(_head.rotation.x - event.relative.y * config.mouse_sensitivity, -limit, limit)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		input_enabled = false
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Le clic qui recapture la souris ne doit pas tirer.
		get_tree().create_timer(0.1).timeout.connect(func() -> void: input_enabled = true)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	wall_cooldown_left = maxf(wall_cooldown_left - delta, 0.0)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	wish_dir = (global_basis * Vector3(input.x, 0.0, input.y)).normalized()

	if life.downed:
		apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, config.ground_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, config.ground_friction * delta)
	else:
		_state.physics_update(delta)
	move_and_slide()

	net_position = global_position
	net_yaw = rotation.y
	net_pitch = _head.rotation.x
	net_crouched = _state.name == &"Slide" or _state.name == &"Crouch"
	net_dashing = dash_cooldown_left > config.dash_cooldown - config.dash_melee_window


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		var roll_smoothing := 1.0 - exp(-CAMERA_ROLL_SMOOTHING * delta)
		camera.rotation.z = lerp_angle(camera.rotation.z, deg_to_rad(camera_roll_target), roll_smoothing)
		return
	crouch.crouched = net_crouched or life.downed
	var t := 1.0 - exp(-REMOTE_SMOOTHING * delta)
	global_position = global_position.lerp(net_position, t)
	rotation.y = lerp_angle(rotation.y, net_yaw, t)
	_head.rotation.x = lerp_angle(_head.rotation.x, net_pitch, t)
