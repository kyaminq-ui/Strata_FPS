extends SceneTree
## Sonde réseau (headless) : le client rejoint l'arène d'infiltration et journalise les ennemis
## (archétype, état, santé, position) tels qu'il les voit.
## Usage : godot --headless --path . -s tests/net_probe_types.gd -- --arena=infiltration --join=127.0.0.1

const SETTLE_SECONDS := 2.0
const LOG_INTERVAL := 2.0
const END_SECONDS := 12.0

var _elapsed := 0.0
var _next_log := SETTLE_SECONDS
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed >= _next_log:
		_next_log += LOG_INTERVAL
		var parts: PackedStringArray = []
		var enemies := _main.get_node_or_null("ArenaInfiltration/Enemies")
		if enemies:
			for enemy in enemies.get_children():
				if "net_state" in enemy:
					var p: Vector3 = enemy.global_position
					parts.append("%s[%s %s hp=%d (%.0f,%.0f)]" % [enemy.name, enemy.config.display_name, enemy.net_state, enemy.get_node("Health").health, p.x, p.z])
		print("[types probe] t=%.0f %s" % [_elapsed, " ".join(parts)])
	if _elapsed >= END_SECONDS:
		quit()
	return false
