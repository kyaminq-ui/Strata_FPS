extends SceneTree
## Sonde de test réseau (headless). Lance le jeu comme client, avance quelques secondes
## et affiche l'état des joueurs vus depuis ce client.
## Usage : godot --headless --path . -s tests/net_probe.gd -- --join=127.0.0.1

const WALK_SECONDS := 6.0
const SETTLE_SECONDS := 2.0

var _elapsed := 0.0
var _walking := false
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	if not _walking and _elapsed > SETTLE_SECONDS:
		_report("avant")
		Input.action_press("move_forward")
		_walking = true
	elif _walking and _elapsed > SETTLE_SECONDS + WALK_SECONDS:
		Input.action_release("move_forward")
		_report("apres")
		quit()
	if _walking:
		_press_scheduled_actions(delta)
	return false


## Cycle de 3 s : dash à 0 s, slide à +1 s, saut à +2 s (appuis d'une frame).
func _press_scheduled_actions(delta: float) -> void:
	var phase := fmod(_elapsed, 3.0)
	for action in ["jump", "dash", "slide"]:
		Input.action_release(action)
	if phase < delta:
		Input.action_press("dash")
	elif phase >= 1.0 and phase < 1.0 + delta:
		Input.action_press("slide")
	elif phase >= 2.0 and phase < 2.0 + delta:
		Input.action_press("jump")


func _report(label: String) -> void:
	var players := _main.get_node_or_null("ArenaGraybox/Players")
	if players == null:
		print("[probe ", label, "] pas d'arène")
		return
	print("[probe ", label, "] my_id=", root.multiplayer.get_unique_id(), " players=", players.get_child_count())
	for p: Player in players.get_children():
		print("  joueur ", p.name, " authority=", p.is_multiplayer_authority(), " pos=", p.global_position, " yaw=", p.rotation.y)
