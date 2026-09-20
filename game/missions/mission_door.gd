class_name MissionDoor
extends StaticBody3D
## Porte verrouillée par un objectif. Le HOST l'ouvre (open) ; l'ouverture est diffusée à tous (cosmétique + collision).

@onready var _shape: CollisionShape3D = $Shape


func _ready() -> void:
	add_to_group("mission_doors")


## Host : ouvre la porte chez tout le monde.
func open() -> void:
	set_open.rpc(true)


@rpc("authority", "call_local", "reliable")
func set_open(is_open: bool) -> void:
	_shape.set_deferred("disabled", is_open)
	visible = not is_open
