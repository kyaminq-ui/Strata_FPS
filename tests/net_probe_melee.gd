extends SceneTree
## Sonde de test réseau (headless) : le client se place devant Dummy1 et frappe 3 fois
## (mêlée). Affiche les hits confirmés, la santé vue et les coups du host vus chez lui.
## Usage : godot --headless --path . -s tests/net_probe_melee.gd -- --join=127.0.0.1

const SETTLE_SECONDS := 2.0
const PUNCHES := 3
const PUNCH_INTERVAL := 0.8
const STAND_POSITION := Vector3(3.0, 0.1, -4.2)  # devant Dummy1 (3, 0, -6)

var _elapsed := 0.0
var _punches := 0
var _hits := 0
var _host_swings := 0
var _bound := false
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	var players := _main.get_node_or_null("ArenaGraybox/Players")
	if players == null or _elapsed < SETTLE_SECONDS:
		return false
	var me := players.get_node_or_null(str(root.multiplayer.get_unique_id())) as Player
	var host_player := players.get_node_or_null("1") as Player
	if me == null or host_player == null:
		return false
	if not _bound:
		me.melee.hit_confirmed.connect(func(_killed: bool) -> void: _hits += 1)
		host_player.melee.swing_started.connect(func() -> void: _host_swings += 1)
		me.global_position = STAND_POSITION
		me.rotation.y = 0.0
		me.get_node("Head").rotation.x = atan2(-0.8, 1.8)
		_bound = true
	Input.action_release("melee")
	var due := SETTLE_SECONDS + 0.5 + _punches * PUNCH_INTERVAL
	if _punches < PUNCHES and _elapsed >= due:
		Input.action_press("melee")
		_punches += 1
	elif _punches >= PUNCHES and _elapsed >= due + 2.0:
		var health: HealthComponent = _main.get_node("ArenaGraybox/Dummies/Dummy1/Health")
		print("[melee probe] coups=", _punches, " hits_confirmes=", _hits, " sante_vue=", health.health, " coups_du_host_vus=", _host_swings)
		quit()
	return false
