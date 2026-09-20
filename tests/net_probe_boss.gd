extends SceneTree
## Sonde réseau (headless) : le client journalise chaque seconde ce qu'il voit du boss (nom de phase, PV, état)
## et de ses renforts, plus l'annonce reçue. Le host déclenche la phase 2 et tue le boss.
## Usage : godot --headless --path . -s tests/net_probe_boss.gd -- --arena=sector --join=127.0.0.1
## Pas de référence aux classes du jeu (voir NEXTSTEPS : compilation avant les autoloads).

const LIFETIME := 40.0

var _elapsed := 0.0
var _next_log := 0.0
var _last_announcement := ""
var _bound := false
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	var arena = _main._arena
	if arena != null and not _bound:
		root.get_node("GameSession").announcement.connect(func(text: String) -> void: _last_announcement = text)
		_bound = true
	if _elapsed >= _next_log and arena != null:
		_next_log += 1.0
		var boss = arena.get_node_or_null("Enemies/BossFixeur")
		if boss != null:
			print("[boss probe] t=%.0f name='%s' hp=%d state=%s phase=%d adds=%d announcement='%s' mission_done=%s" % [
				_elapsed, boss.config.display_name, boss.get_node("Health").health, boss.net_state,
				boss.get_node("Phases").phase, get_nodes_in_group("boss_add_units").size(), _last_announcement,
				root.get_node("GameSession").mission_done])
	if _elapsed > LIFETIME:
		quit()
	return false
