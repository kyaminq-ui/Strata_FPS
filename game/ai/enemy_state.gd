class_name EnemyState
extends Node
## Base d'un état d'ennemi (enfant de Enemy/States). Exécuté par le host uniquement.
## Les transitions passent par enemy.change_state(&"Nom").

var enemy: Enemy


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
