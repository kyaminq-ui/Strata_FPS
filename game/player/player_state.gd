class_name PlayerState
extends Node
## Base d'un état de mouvement (enfant de Player/States). Seul l'autorité les exécute.
## Les transitions passent par player.change_state(&"Nom").

var player: Player


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
