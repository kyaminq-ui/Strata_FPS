extends SceneTree
## Sonde de test réseau (headless) : le client se contente de journaliser sa vie/son état
## down (vus depuis SON instance) à chaque changement pendant LIFETIME secondes.
## Usage : godot --headless --path . -s tests/net_probe_life.gd -- --join=127.0.0.1

const LIFETIME := 30.0

var _elapsed := 0.0
var _last := ""
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	var players: Node = _main._arena.get_node_or_null("Players") if _main._arena else null
	var me = players.get_node_or_null(str(root.multiplayer.get_unique_id())) if players else null
	if me != null:
		var cp := _checkpoints_active()
		var line := "downed=%s hp=%d pos=(%.1f,%.1f) t_down=%.0f cp=%s" % [me.life.downed, roundi(me.health.health), me.global_position.x, me.global_position.z, me.life.down_time_left, cp]
		var key := "downed=%s hp=%d pos=(%.1f,%.1f) cp=%s" % [me.life.downed, roundi(me.health.health), me.global_position.x, me.global_position.z, cp]
		if key != _last:
			print("[life probe %5.1fs] %s" % [_elapsed, line])
			_last = key
	if _elapsed > LIFETIME:
		quit()
	return false


func _checkpoints_active() -> String:
	var states: PackedStringArray = []
	for cp in get_nodes_in_group("checkpoints"):
		states.append("%s" % cp.active)
	return ",".join(states)
