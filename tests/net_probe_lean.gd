extends SceneTree
## Sonde réseau (headless) : le client se penche à droite (lean_right maintenu) pendant 3 s, puis à gauche 2 s.
## Le client affiche aussi ce qu'il voit du host (net_lean, décalage de tête) pour tester la réplication inverse.
## Usage : godot --headless --path . -s tests/net_probe_lean.gd -- --join=127.0.0.1

const SETTLE_SECONDS := 2.0
const RIGHT_SECONDS := 3.0
const LEFT_SECONDS := 2.0

var _elapsed := 0.0
var _next_log := 0.0
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	var t := _elapsed - SETTLE_SECONDS
	if t >= 0.0 and t < RIGHT_SECONDS:
		Input.action_press("lean_right")
	elif t >= RIGHT_SECONDS and t < RIGHT_SECONDS + LEFT_SECONDS:
		Input.action_release("lean_right")
		Input.action_press("lean_left")
	else:
		Input.action_release("lean_left")
	if _elapsed >= _next_log:
		_next_log += 1.0
		for p in get_nodes_in_group("players"):
			print("[probe lean] t=%.1f player=%s mine=%s net_lean=%.2f head_x=%.2f roll=%.1f pos=%s act=%s" % [
				_elapsed, p.name, p.is_multiplayer_authority(), p.net_lean, p.get_node("Head").position.x,
				rad_to_deg(p.get_node("Head").rotation.z), p.global_position, p.can_act()])
	if _elapsed >= SETTLE_SECONDS + RIGHT_SECONDS + LEFT_SECONDS + 1.0:
		quit()
	return false
