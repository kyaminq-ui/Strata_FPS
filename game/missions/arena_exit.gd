class_name ArenaExit
extends Node
## Sortie d'arène (ascenseur du hub) : quand son terminal est actionné, le host envoie tous les joueurs
## vers l'arène `arena_index` (liste de main.gd : 2 = hub, 3 = secteur Bas-fonds).

@export var terminal: HackTerminal
@export var arena_index := 3


func _ready() -> void:
	if multiplayer.is_server():
		terminal.hacked.connect(func() -> void: GameSession.load_arena(arena_index))
