class_name SectorMission
extends Node
## Missions du secteur (host seul) : 1. pirater le terminal (ouvre la salle du cible), 2. éliminer la cible.
## L'état des objectifs vit dans GameSession (diffusé aux clients). Un reset de rencontre ne l'annule pas.

@export var terminal: HackTerminal
@export var target: Enemy  # la cible majeure (le boss remplacera cet élite en 4.5)


func _ready() -> void:
	if not multiplayer.is_server():
		return
	GameSession.set_objectives([
		{"id": "hack", "text": "MISSION 1 - Accès : pirater le terminal de sécurité", "done": false},
		{"id": "kill", "text": "MISSION 2 - La cible : éliminer la cible au sommet", "done": false},
	])
	terminal.hacked.connect(_on_hacked)
	target.get_node("Health").died.connect(_on_target_died)


func _on_hacked() -> void:
	GameSession.complete_objective("hack")
	get_tree().call_group("mission_doors", "open")


func _on_target_died(_by_peer: int) -> void:
	GameSession.complete_objective("kill")
