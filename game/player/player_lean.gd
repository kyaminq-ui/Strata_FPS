class_name PlayerLean
extends Node
## Penchement gauche/droite (maintenu). L'autorité lit l'input, limite le décalage contre les murs et
## écrit la cible dans Player.net_lean ; tous les peers lissent puis décalent/inclinent la tête et le mesh.

@export var config: MovementConfig
@export var head: Node3D
@export var body_mesh: MeshInstance3D

var _player: Player
var _goal := 0.0  # cible -1 (gauche) .. 1 (droite), déjà limitée par les murs
var _lean := 0.0  # valeur lissée affichée


func _ready() -> void:
	_player = get_parent()


func _physics_process(_delta: float) -> void:
	if not _player.is_multiplayer_authority():
		return
	var side := 0.0
	if _player.can_act():
		side = Input.get_axis("lean_left", "lean_right")
	_goal = side * _free_ratio(side) if side != 0.0 else 0.0
	_player.net_lean = _goal


func _process(delta: float) -> void:
	if not _player.is_multiplayer_authority():
		_goal = _player.net_lean
	_lean = lerpf(_lean, _goal, 1.0 - exp(-config.lean_speed * delta))
	head.position.x = _lean * config.lean_offset
	var roll := -deg_to_rad(_lean * config.lean_roll_degrees)  # roulis positif = vers la gauche
	head.rotation.z = roll
	body_mesh.rotation.z = roll


## Part du décalage complet possible du côté demandé (0..1) avant de heurter un mur.
func _free_ratio(side: float) -> float:
	var from := _player.global_position + Vector3.UP * head.position.y
	var reach := config.lean_offset + config.lean_wall_margin
	var to := from + _player.global_basis.x * signf(side) * reach
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 1.0
	var free := from.distance_to(hit.position) - config.lean_wall_margin
	return clampf(free / config.lean_offset, 0.0, 1.0)
