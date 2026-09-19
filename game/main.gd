extends Node
## Scène de démarrage (menu de debug). Crée le réseau AVANT l'arène : le client
## doit être « en connexion » quand l'arène entre dans l'arbre (voir docs/NETWORK.md).
## Arguments de test (après --) : --solo | --host | --join=<adresse>

const ARENA := preload("res://game/world/arena_graybox.tscn")

var _arena: Node

@onready var _menu: Control = $Menu
@onready var _address: LineEdit = %Address
@onready var _status: Label = %Status


func _ready() -> void:
	%SoloButton.pressed.connect(_start_solo)
	%HostButton.pressed.connect(_start_host)
	%JoinButton.pressed.connect(func() -> void: _start_join(_address.text.strip_edges()))
	MultiplayerManager.connection_failed.connect(_return_to_menu.bind("Connexion échouée"))
	MultiplayerManager.server_disconnected.connect(_return_to_menu.bind("Host déconnecté"))
	_apply_command_line()


func _apply_command_line() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--solo":
			_start_solo()
		elif arg == "--host":
			_start_host()
		elif arg.begins_with("--join="):
			_start_join(arg.trim_prefix("--join="))


func _start_solo() -> void:
	_enter_arena()


func _start_host() -> void:
	if MultiplayerManager.host() == OK:
		_enter_arena()
	else:
		_status.text = "Host impossible (port utilisé ?)"


func _start_join(address: String) -> void:
	if MultiplayerManager.join(address) == OK:
		_enter_arena()
	else:
		_status.text = "Adresse invalide"


func _enter_arena() -> void:
	_menu.hide()
	_arena = ARENA.instantiate()
	add_child(_arena)


func _return_to_menu(message: String) -> void:
	MultiplayerManager.leave()
	if _arena:
		_arena.queue_free()
		_arena = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_status.text = message
	_menu.show()
