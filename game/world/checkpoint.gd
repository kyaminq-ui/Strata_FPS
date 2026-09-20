class_name Checkpoint
extends Area3D
## Point de reprise. Le HOST détecte le passage d'un joueur debout et l'enregistre dans GameSession ;
## l'état actif est affiché chez tous les peers par RPC (cosmétique).

const COLOR_INACTIVE := Color(0.25, 0.3, 0.4)
const COLOR_ACTIVE := Color(0.1, 1.0, 0.5)

@export var slot_spacing: float = 1.5  # écart entre les deux joueurs au respawn (m)

var active := false

var _material := StandardMaterial3D.new()

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	add_to_group("checkpoints")
	_material.emission_enabled = true
	_mesh.material_override = _material
	set_active(false)
	monitoring = multiplayer.is_server()
	body_entered.connect(_on_body_entered)


## Position de respawn du joueur numéro `slot` (2 emplacements de part et d'autre du centre).
func spawn_position(slot: int) -> Vector3:
	return global_position + global_basis.x * slot_spacing * (float(slot % 2) - 0.5)


@rpc("authority", "call_local", "reliable")
func set_active(on: bool) -> void:
	active = on
	var color := COLOR_ACTIVE if on else COLOR_INACTIVE
	_material.albedo_color = color
	_material.emission = color


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player != null and not player.life.downed:
		GameSession.set_checkpoint(self)
