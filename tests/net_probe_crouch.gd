extends SceneTree
## Sonde réseau (headless) : le client s'accroupit (action « slide » maintenue à l'arrêt) pendant 3 s.
## Le host lit `net_crouched` / `crouch.crouched` du joueur client pour vérifier la réplication.
## Usage : godot --headless --path . -s tests/net_probe_crouch.gd -- --join=127.0.0.1

const SETTLE_SECONDS := 2.0
const HOLD_SECONDS := 3.0
const END_SECONDS := 6.0

var _elapsed := 0.0
var _main: Node


func _initialize() -> void:
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed >= SETTLE_SECONDS and _elapsed < SETTLE_SECONDS + HOLD_SECONDS:
		Input.action_press("slide")
	elif _elapsed >= SETTLE_SECONDS + HOLD_SECONDS:
		Input.action_release("slide")
	if _elapsed >= END_SECONDS:
		quit()
	return false
