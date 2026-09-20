extends SceneTree
## Sonde réseau (headless) : le client journalise chaque seconde l'arène courante, le nombre de joueurs qu'il voit,
## sa position et l'objectif courant. Sert à vérifier les changements d'arène ordonnés par le host (hub <-> secteur).
## Usage : godot --headless --path . -s tests/net_probe_loop.gd -- --arena=hub --join=127.0.0.1
## Pas de référence aux classes du jeu (voir NEXTSTEPS : compilation avant les autoloads).

const LIFETIME := 60.0

var _elapsed := 0.0
var _next_log := 0.0
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed >= _next_log:
		_next_log += 1.0
		var arena = _main._arena
		var mine := "-"
		var count := 0
		if arena != null:
			var players = arena.get_node_or_null("Players")
			if players != null:
				count = players.get_child_count()
				var me = players.get_node_or_null(str(root.multiplayer.get_unique_id()))
				if me != null:
					mine = "(%.1f,%.1f,%.1f)" % [me.global_position.x, me.global_position.y, me.global_position.z]
		print("[loop probe] t=%.0f arena=%s players=%d me=%s objective='%s' done=%s" % [
			_elapsed, arena.name if arena != null else "none", count, mine,
			root.get_node("GameSession").current_objective_text(), root.get_node("GameSession").mission_done])
	if _elapsed > LIFETIME:
		quit()
	return false
