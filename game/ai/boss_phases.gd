class_name BossPhases
extends Node
## Boss en 2 phases (enfant de l'Enemy « Fixeur »). Le HOST décide ; tous les pairs appliquent la config de phase
## (RPC fiable) pour l'affichage. Phase 2 sous `phase_two_fraction` des PV : config plus dure, renforts et onde de
## choc périodique (télégraphiée, esquivable en s'éloignant ou en sautant). Un reset de rencontre le remet en phase 1.

@export var config: BossConfig
@export var adds: EnemySpawner  # renforts de la phase 2 (spawner déclenché à la main)

var phase := 1

var _phase_one_config: EnemyConfig
var _shock_left := 0.0

@onready var _enemy: Enemy = get_parent()
@onready var _health: HealthComponent = $"../Health"


func _ready() -> void:
	_phase_one_config = _enemy.config
	if multiplayer.is_server():
		_enemy.was_reset.connect(_on_reset)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or _enemy.is_dead():
		return
	if phase == 1:
		if _health.health <= _health.max_health * config.phase_two_fraction:
			_start_phase_two()
	elif _enemy.state_name == &"Combat":
		_shock_left -= delta
		if _shock_left <= 0.0:
			_shock_left = config.shockwave_interval
			_shockwave()


func _start_phase_two() -> void:
	_set_phase.rpc(2)
	_shock_left = config.shockwave_interval
	GameSession.announce(config.phase_two_text)
	if adds != null:
		adds.spawn_wave(_enemy.global_position)


func _on_reset() -> void:
	if phase != 1:
		_set_phase.rpc(1)


@rpc("authority", "call_local", "reliable")
func _set_phase(new_phase: int) -> void:
	phase = new_phase
	_enemy.apply_config(config.phase_two if new_phase == 2 else _phase_one_config)


func _shockwave() -> void:
	var center := _enemy.global_position
	_show_telegraph.rpc(center, config.shockwave_radius, config.shockwave_delay)
	await get_tree().create_timer(config.shockwave_delay).timeout
	if _enemy.is_dead() or phase != 2:
		return
	for node in get_tree().get_nodes_in_group("players"):
		var player := node as Player
		if player == null or player.life.downed:
			continue
		var offset := player.global_position - center
		if Vector2(offset.x, offset.z).length() <= config.shockwave_radius and offset.y < config.shockwave_dodge_height:
			player.health.take_damage(config.shockwave_damage, 0)  # 0 = pas de tireur joueur


## Disque rouge au sol pendant la télégraphie (cosmétique, chez tous les pairs).
@rpc("authority", "call_local", "reliable")
func _show_telegraph(center: Vector3, radius: float, seconds: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.05
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.1, 0.1, 0.25)
	mesh.material = material
	var disc := MeshInstance3D.new()
	disc.mesh = mesh
	_enemy.get_parent().get_parent().add_child(disc)  # sous l'arène (pas sous Enemies, nœud de spawn)
	disc.global_position = center + Vector3.UP * 0.05
	var tween := disc.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.8, seconds)
	tween.tween_callback(disc.queue_free)
