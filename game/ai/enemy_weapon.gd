class_name EnemyWeapon
extends Node
## Tir hitscan de l'ennemi (host). Temps de réaction avant le premier tir, cadence, dispersion.
## Dégâts via HealthComponent.take_damage (contrat « cible »), trait cosmétique répliqué aux clients.

const WORLD_MASK := 1
const PLAYER_MASK := 2
const FLASH_TIME := 0.06  # cosmétique

var _enemy: Enemy
var _aim_time := 0.0
var _cooldown := 0.0

@onready var _muzzle: Marker3D = $"../Mesh/Gun/Muzzle"
@onready var _flash_mesh: MeshInstance3D = $"../Mesh/Gun/Flash"


func _ready() -> void:
	_enemy = get_parent() as Enemy


func reset() -> void:
	_aim_time = 0.0


## Appelé chaque frame par l'état Combat (host). `target` null = joueur perdu de vue.
func tick(delta: float, target: Player) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if target == null:
		_aim_time = 0.0
		return
	_aim_time += delta
	if _aim_time >= _enemy.config.reaction_time and _cooldown <= 0.0:
		_fire(target)


func _fire(target: Player) -> void:
	var config := _enemy.config
	_cooldown = config.fire_interval
	var origin := _enemy.global_position + Vector3.UP * config.eye_height
	var aim_direction := (target.global_position + Vector3.UP * config.target_height - origin).normalized()
	var space := _enemy.get_world_3d().direct_space_state
	var ends := PackedVector3Array()
	for i in config.pellets:
		var direction := _with_spread(aim_direction, config.spread_degrees)
		var end := origin + direction * config.attack_range
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end, WORLD_MASK | PLAYER_MASK))
		if not hit.is_empty():
			end = hit.position
			var health := (hit.collider as Node).get_node_or_null("Health") as HealthComponent
			if health:
				health.take_damage(config.damage, 0)  # 0 = pas de tireur joueur
		ends.append(end)
	var start := _muzzle.global_position  # les traits partent du canon (le tir, lui, part des yeux)
	_show_shot_local(start, ends)
	if not multiplayer.get_peers().is_empty():
		show_shot.rpc(start, ends)


@rpc("authority", "call_remote", "unreliable")
func show_shot(from: Vector3, ends: PackedVector3Array) -> void:
	_show_shot_local(from, ends)


func _show_shot_local(from: Vector3, ends: PackedVector3Array) -> void:
	for end in ends:
		Tracer.spawn(_enemy.get_parent(), from, end)
	_flash()


func _flash() -> void:
	_flash_mesh.show()
	get_tree().create_timer(FLASH_TIME).timeout.connect(_flash_mesh.hide)


static func _with_spread(direction: Vector3, degrees: float) -> Vector3:
	var angle := deg_to_rad(degrees) * sqrt(randf())
	var around := randf() * TAU
	var basis := Basis.looking_at(direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)
	return basis * Vector3(sin(angle) * cos(around), sin(angle) * sin(around), -cos(angle))
