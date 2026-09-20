extends SceneTree
## Sonde réseau (headless) : le client va au terminal de piratage du secteur et maintient « interact » ~6 s ;
## il journalise ce qu'il voit (jauge, objectif courant, porte du boss). Le host valide et diffuse.
## Usage : godot --headless --path . -s tests/net_probe_hack.gd -- --arena=sector --join=127.0.0.1
## Pas de référence aux classes du jeu (voir NEXTSTEPS : compilation avant les autoloads).

const SETTLE_SECONDS := 3.0
const HOLD_SECONDS := 7.0
const END_SECONDS := 13.0

var _elapsed := 0.0
var _next_log := 0.0
var _placed := false
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	var arena = _main._arena
	if arena == null or _elapsed < SETTLE_SECONDS:
		return false
	var terminal = arena.get_node("HackTerminal")
	if not _placed:
		for p in get_nodes_in_group("players"):
			if p.is_multiplayer_authority():
				p.global_position = terminal.global_position + Vector3(0.0, 0.1, 1.5)
		_placed = true
	if _elapsed >= SETTLE_SECONDS + 1.0 and _elapsed < SETTLE_SECONDS + 1.0 + HOLD_SECONDS:
		Input.action_press("interact")
	else:
		Input.action_release("interact")
	if _elapsed >= _next_log:
		_next_log += 1.0
		print("[hack probe] t=%.0f progress=%.2f done=%s objective='%s' door_visible=%s mission_done=%s" % [
			_elapsed, terminal.progress, terminal.done, root.get_node("GameSession").current_objective_text(),
			arena.get_node("BossDoorW").visible, root.get_node("GameSession").mission_done])
	if _elapsed >= END_SECONDS:
		quit()
	return false
