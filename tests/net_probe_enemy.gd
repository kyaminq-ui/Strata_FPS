extends SceneTree
## Sonde réseau (headless) : le client observe les ennemis (positions/état/santé répliqués),
## puis vise Enemy1 (en mouvement) et tire 3 fois avec le pistolet.
## Usage : godot --headless --path . -s tests/net_probe_enemy.gd -- --join=127.0.0.1

const SETTLE_SECONDS := 2.0
const LOG_INTERVAL := 1.0
const SHOOT_START := 6.0
const SHOTS := 5
const SHOT_INTERVAL := 0.8
const SHOOT_DISTANCE := 6.0
const AIM_HEIGHT := 1.0
const END_SECONDS := 22.0  # laisse le temps aux renforts d'arriver (delay 8 s après l'alerte)

var _elapsed := 0.0
var _next_log := 0.0
var _shots := 0
var _hits := 0
var _bound := false
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	var player := _find_local_player()
	if player == null or _elapsed < SETTLE_SECONDS:
		return false
	if not _bound:
		player.weapon.hit_confirmed.connect(func(_killed: bool) -> void: _hits += 1)
		_bound = true
	if _elapsed >= _next_log:
		_next_log += LOG_INTERVAL
		print("[enemy probe] t=%.1f %s | %s | myhp=%d | enemies=%s" % [_elapsed, _describe("Enemy1"), _describe("Enemy2"), player.health.health, _enemy_names()])
	Input.action_release("fire")
	if _elapsed >= SHOOT_START:
		_shoot_phase(player)
	return false


func _shoot_phase(player: Player) -> void:
	var due := SHOOT_START + _shots * SHOT_INTERVAL
	if _shots < SHOTS and _elapsed >= due:
		var enemy := _enemy("Enemy1")
		var target := enemy.global_position + Vector3.UP * AIM_HEIGHT
		player.global_position = enemy.global_position + Vector3(SHOOT_DISTANCE, 0.0, 0.0)
		var eye := player.global_position + Vector3.UP * WeaponController.HEAD_HEIGHT
		var to_target := target - eye
		player.rotation.y = atan2(-to_target.x, -to_target.z)
		player.get_node("Head").rotation.x = atan2(to_target.y, Vector2(to_target.x, to_target.z).length())
		Input.action_press("fire")
		_shots += 1
	elif _shots >= SHOTS and _elapsed >= END_SECONDS:
		print("[enemy probe] tirs=%d hits_confirmes=%d sante_vue_enemy1=%s" % [_shots, _hits, _enemy("Enemy1").get_node("Health").health])
		quit()


func _enemy_names() -> String:
	var names: PackedStringArray = []
	for enemy in _main.get_node("ArenaGraybox/Enemies").get_children():
		if enemy is Enemy:  # les traits cosmétiques sont aussi enfants de ce nœud
			names.append("%s:%s" % [enemy.name, enemy.net_state])
	return ",".join(names)


func _enemy(enemy_name: String) -> Node3D:
	return _main.get_node("ArenaGraybox/Enemies/" + enemy_name)


func _describe(enemy_name: String) -> String:
	var enemy := _enemy(enemy_name)
	var p := enemy.global_position
	return "%s (%.1f, %.1f) %s hp=%d" % [enemy_name, p.x, p.z, enemy.net_state, enemy.get_node("Health").health]


func _find_local_player() -> Player:
	var players := _main.get_node_or_null("ArenaGraybox/Players")
	if players == null:
		return null
	return players.get_node_or_null(str(root.multiplayer.get_unique_id())) as Player
