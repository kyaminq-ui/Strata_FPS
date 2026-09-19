extends StaticBody3D
## Cible d'entraînement. Le host gère les dégâts et le respawn ; tous les peers
## affichent l'état à partir de Health.health (répliqué).

const RESPAWN_DELAY := 3.0
const BASE_COLOR := Color(0.9, 0.5, 0.15)
const FLASH_COLOR := Color(1.0, 1.0, 1.0)

var _last_health := -1.0
var _material := StandardMaterial3D.new()
var _layer := 0

@onready var _health: HealthComponent = $Health
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label


func _ready() -> void:
	_layer = collision_layer
	_material.albedo_color = BASE_COLOR
	_mesh.material_override = _material
	if multiplayer.is_server():
		_health.died.connect(_on_died)


func _process(_delta: float) -> void:
	var health := _health.health
	_label.text = str(ceili(health))
	_mesh.visible = health > 0.0
	_label.visible = health > 0.0
	if _last_health > health and health > 0.0:
		_material.albedo_color = FLASH_COLOR
		create_tween().tween_property(_material, "albedo_color", BASE_COLOR, 0.15)
	_last_health = health


func _on_died(_by_peer: int) -> void:
	collision_layer = 0
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_health.reset()
	collision_layer = _layer
