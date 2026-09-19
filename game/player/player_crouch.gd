class_name PlayerCrouch
extends Node
## Hauteur du joueur pendant un slide : collision (autorité seulement), tête et mesh
## (tous les peers, avec transition douce). `crouched` est piloté par Player.

const STAND_HEIGHT := 1.8  # doit correspondre à la capsule de player.tscn
const STAND_HEAD_Y := 1.6

@export var config: MovementConfig
@export var shape_node: CollisionShape3D
@export var head: Node3D
@export var body_mesh: MeshInstance3D

var crouched := false

var _blend := 0.0
var _body: CharacterBody3D
var _shape: CapsuleShape3D


func _ready() -> void:
	_body = get_parent()
	# La sous-ressource de la scène est partagée entre instances : chaque joueur a la sienne.
	_shape = shape_node.shape.duplicate()
	shape_node.shape = _shape


## Vrai s'il y a la place de se relever (rien au-dessus de la capsule accroupie).
func can_stand() -> bool:
	return not _body.test_move(_body.global_transform, Vector3.UP * (STAND_HEIGHT - config.slide_height))


func _process(delta: float) -> void:
	_blend = move_toward(_blend, 1.0 if crouched else 0.0, delta / config.crouch_transition)
	head.position.y = lerpf(STAND_HEAD_Y, config.slide_head_height, _blend)
	var height_ratio := lerpf(1.0, config.slide_height / STAND_HEIGHT, _blend)
	body_mesh.scale.y = height_ratio
	body_mesh.position.y = STAND_HEIGHT * height_ratio * 0.5
	if _body.is_multiplayer_authority():
		var height := config.slide_height if crouched else STAND_HEIGHT
		_shape.height = height
		shape_node.position.y = height * 0.5
