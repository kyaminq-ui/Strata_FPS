class_name Grenade
extends RigidBody3D
## Grenade explosive. SIMULÉE PAR LE HOST uniquement (rebonds, mèche, explosion) ; les autres
## peers reçoivent net_position (MultiplayerSynchronizer, autorité host) et l'interpolent.
## Elle a un HealthComponent : n'importe quel tir qui la touche la détruit -> explosion.
## Les explosions à portée déclenchent celles des autres grenades (réaction en chaîne).

const WORLD_MASK := 1
const PLAYER_MASK := 2
const ENEMY_MASK := 4
const GRENADE_MASK := 8
const TARGET_HEIGHT := 0.9
const REMOTE_SMOOTHING := 25.0
const BLINK_START := 0.8  # s avant l'explosion
const BLINK_RATE := 12.0
const SAFE_COLOR := Color(0.2, 0.9, 0.3)
const ALERT_COLOR := Color(1.0, 0.2, 0.1)

@export var config: GrenadeConfig

var initial_velocity := Vector3.ZERO  # renseigné par GrenadeSpawner (tous les peers)
var thrower_id := 0
var net_position := Vector3.ZERO
var net_fuse_left := 0.0  # répliqué : les clients en déduisent le clignotement

var _fuse_left := 0.0
var _exploded := false
var _material := StandardMaterial3D.new()

@onready var _health: HealthComponent = $Health
@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	_material.albedo_color = SAFE_COLOR
	_mesh.material_override = _material
	net_position = global_position
	if multiplayer.is_server():
		_fuse_left = config.fuse_time
		var surface := PhysicsMaterial.new()
		surface.bounce = config.bounce
		surface.friction = 0.6
		physics_material_override = surface
		linear_velocity = initial_velocity
		_health.died.connect(func(_by_peer: int) -> void: _explode())
	else:
		freeze = true  # les clients ne simulent pas : position répliquée


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	net_position = global_position
	_fuse_left -= delta
	net_fuse_left = _fuse_left
	if _fuse_left <= 0.0:
		_explode()


func _process(delta: float) -> void:
	var fuse_left := _fuse_left
	if not multiplayer.is_server():
		global_position = global_position.lerp(net_position, 1.0 - exp(-REMOTE_SMOOTHING * delta))
		fuse_left = net_fuse_left
	if fuse_left > 0.0 and fuse_left < BLINK_START:
		var on := int(fuse_left * BLINK_RATE) % 2 == 0
		_material.albedo_color = ALERT_COLOR if on else SAFE_COLOR


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var center := global_position
	var space := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = config.blast_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = PLAYER_MASK | ENEMY_MASK | GRENADE_MASK
	for result in space.intersect_shape(query, 32):
		var body := result.collider as Node3D
		if body == null or body == self:
			continue
		var health := body.get_node_or_null("Health") as HealthComponent
		if health == null:
			continue
		var target := body.global_position + Vector3.UP * TARGET_HEIGHT
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(center, target, WORLD_MASK)).is_empty():
			continue  # à couvert
		var damage := config.damage * (1.0 - clampf(center.distance_to(target) / config.blast_radius, 0.0, 1.0))
		if body is Player:
			damage *= config.player_damage_multiplier
		if damage > 0.0:
			health.take_damage(damage, thrower_id)
	NoiseBus.emit_at(get_tree(), center, config.noise_radius, NoiseBus.EXPLOSION)
	var spawner := get_tree().get_first_node_in_group("grenade_spawner") as GrenadeSpawner
	if spawner:
		spawner.explosion_fx(center, config.blast_radius)
	queue_free()
