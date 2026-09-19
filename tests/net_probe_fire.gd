extends SceneTree
## Sonde de test réseau (headless) : le client vise Dummy1 et tire 3 fois.
## Affiche les munitions, les hit-confirmations reçues et la santé vue par le client.
## Usage : godot --headless --path . -s tests/net_probe_fire.gd -- --join=127.0.0.1

const SETTLE_SECONDS := 2.0
const SHOTS := 3
const SHOT_INTERVAL := 0.4
const TARGET := Vector3(3.0, 1.0, -6.0)  # poitrine de Dummy1

var _elapsed := 0.0
var _shots_fired := 0
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
		_aim_at_target(player)
		_bound = true
	Input.action_release("fire")
	var due := SETTLE_SECONDS + 0.2 + _shots_fired * SHOT_INTERVAL
	if _shots_fired < SHOTS and _elapsed >= due:
		Input.action_press("fire")
		_shots_fired += 1
	elif _shots_fired >= SHOTS and _elapsed >= due + 0.5:
		var health: HealthComponent = _main.get_node("ArenaGraybox/Dummies/Dummy1/Health")
		print("[fire probe] tirs=", _shots_fired, " ammo=", player.weapon.ammo, " hits_confirmes=", _hits, " sante_vue_par_le_client=", health.health)
		quit()
	return false


func _find_local_player() -> Player:
	var players := _main.get_node_or_null("ArenaGraybox/Players")
	if players == null:
		return null
	return players.get_node_or_null(str(root.multiplayer.get_unique_id())) as Player


func _aim_at_target(player: Player) -> void:
	var eye := player.global_position + Vector3.UP * WeaponController.HEAD_HEIGHT
	var to_target := TARGET - eye
	player.rotation.y = atan2(-to_target.x, -to_target.z)
	player.get_node("Head").rotation.x = atan2(to_target.y, Vector2(to_target.x, to_target.z).length())
