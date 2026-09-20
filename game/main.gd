extends Node
## Scène de démarrage (menu de debug). Crée le réseau AVANT l'arène : le client
## doit être « en connexion » quand l'arène entre dans l'arbre (voir docs/NETWORK.md).
## Arguments de test (après --) : --solo | --host | --join=<adresse> [--arena=infiltration]
## Le host et le client doivent choisir la même arène.

const ARENAS: Array[PackedScene] = [
	preload("res://game/world/arena_graybox.tscn"),
	preload("res://game/world/arena_infiltration.tscn"),
	preload("res://game/world/hub_graybox.tscn"),
	preload("res://game/world/sector_bas_fonds.tscn"),
]
const ARENA_ARGS := {"graybox": 0, "infiltration": 1, "hub": 2, "sector": 3}

var _arena: Node

@onready var _menu: Control = $Menu
@onready var _address: LineEdit = %Address
@onready var _arena_picker: OptionButton = %ArenaPicker
@onready var _status: Label = %Status


func _ready() -> void:
	%SoloButton.pressed.connect(_start_solo)
	%HostButton.pressed.connect(_start_host)
	%JoinButton.pressed.connect(func() -> void: _start_join(_address.text.strip_edges()))
	MultiplayerManager.connection_failed.connect(_return_to_menu.bind("Connexion échouée"))
	MultiplayerManager.server_disconnected.connect(_return_to_menu.bind("Host déconnecté"))
	GameSession.arena_requested.connect(_on_arena_requested)
	_apply_command_line()


func _apply_command_line() -> void:
	for arg in OS.get_cmdline_user_args():  # --arena d'abord : il doit être connu avant le démarrage
		if arg.begins_with("--arena=") and ARENA_ARGS.has(arg.trim_prefix("--arena=")):
			_arena_picker.select(ARENA_ARGS[arg.trim_prefix("--arena=")])
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
	_load_arena(_arena_picker.selected)


## Changement d'arène ordonné par le host (hub <-> secteur). Le host attend la fin de la frame (il envoie
## d'abord l'ordre, puis ses spawns) ; un client charge tout de suite pour que l'arène existe avant les spawns.
func _on_arena_requested(index: int) -> void:
	if multiplayer.is_server():
		_load_arena.call_deferred(index)
	else:
		_load_arena(index)


func _load_arena(index: int) -> void:
	GameSession.reset()
	if _arena:
		remove_child(_arena)  # tout de suite : le nom du nœud doit être libre pour la nouvelle arène
		_arena.queue_free()
	_arena = ARENAS[index].instantiate()
	add_child(_arena)


func _return_to_menu(message: String) -> void:
	MultiplayerManager.leave()
	GameSession.reset()
	if _arena:
		_arena.queue_free()
		_arena = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_status.text = message
	_menu.show()
