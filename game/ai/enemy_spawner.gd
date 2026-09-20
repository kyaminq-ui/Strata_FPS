class_name EnemySpawner
extends MultiplayerSpawner
## Renforts (host) : quand une alerte frontale dure, fait arriver des ennemis depuis les points de renfort,
## déjà en alerte vers la position du joueur. Répliqué par spawn_function (données explicites).
## Trouvé par le groupe « reinforcements » (appelé par EnemyAwareness.become_alert).

const ENEMY_SCENE := preload("res://game/ai/enemy.tscn")

@export var config: ReinforcementConfig
## Nœud dont les enfants Marker3D sont les points d'arrivée des renforts.
@export var points: Node3D
## Faux pour un spawner déclenché à la main (renforts du boss) : il ignore les alertes.
@export var responds_to_alerts := true
## Préfixe des noms de nœuds et groupe de comptage : à changer si plusieurs spawners partagent le même parent.
@export var unit_prefix := "Reinforcement"
@export var unit_group := &"reinforcement_units"

var _next_id := 0
var _cooldown_left := 0.0
var _pending := false


func _ready() -> void:
	if responds_to_alerts:
		add_to_group("reinforcements")
	spawn_function = _create_enemy
	set_process(multiplayer.is_server())


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


## Host : une alerte vient de se déclarer à `position`.
func on_alert(position: Vector3) -> void:
	if _pending or _cooldown_left > 0.0 or points == null or _alive_units() >= config.max_alive:
		return
	_pending = true
	await get_tree().create_timer(config.delay).timeout
	_pending = false
	if not _alert_ongoing():
		return  # le joueur s'est fait oublier : pas de renforts
	_cooldown_left = config.cooldown
	spawn_wave(position)


## Host : fait arriver une vague maintenant (déjà en alerte vers `position`), dans la limite de `max_alive`.
func spawn_wave(position: Vector3) -> void:
	var markers := points.get_children()
	for i in mini(config.count, config.max_alive - _alive_units()):
		var enemy := spawn({"id": _next_id, "type": i % config.unit_types.size() if not config.unit_types.is_empty() else -1, "position": (markers[i % markers.size()] as Marker3D).global_position}) as Enemy
		_next_id += 1
		if enemy:
			enemy.awareness.force_alert(position)


func _create_enemy(data: Dictionary) -> Node:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.name = "%s%d" % [unit_prefix, data.id]
	enemy.position = data.position
	enemy.respawns = false
	if data.type >= 0:
		enemy.config = config.unit_types[data.type]
	enemy.add_to_group(unit_group)
	return enemy


func _alive_units() -> int:
	return get_tree().get_nodes_in_group(unit_group).filter(func(e: Node) -> bool: return not (e as Enemy).is_dead()).size()


func _alert_ongoing() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and not enemy.is_dead() and (enemy.state_name == &"Alert" or enemy.state_name == &"Combat"):
			return true
	return false
