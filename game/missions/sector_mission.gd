class_name SectorMission
extends Node
## Missions du secteur (host seul) : 1. pirater le terminal (ouvre la salle du cible), 2. éliminer la cible.
## L'état des objectifs vit dans GameSession (diffusé aux clients). Un reset de rencontre ne l'annule pas.

@export var terminal: HackTerminal
@export var target: Enemy  # la cible majeure (le boss remplacera cet élite en 4.5)
@export var end_screen_seconds := 12.0  # écran de fin avant le retour au hub
@export var return_arena := 2  # liste de main.gd : 2 = hub


func _ready() -> void:
	if not multiplayer.is_server():
		return
	GameSession.set_objectives([
		{"id": "hack", "text": "MISSION 1 - Accès : pirater le terminal de sécurité", "done": false},
		{"id": "kill", "text": "MISSION 2 - La cible : éliminer la cible au sommet", "done": false},
	])
	terminal.hacked.connect(_on_hacked)
	target.get_node("Health").died.connect(_on_target_died)
	GameSession.mission_completed.connect(_on_mission_completed)


func _on_hacked() -> void:
	GameSession.complete_objective("hack")
	get_tree().call_group("mission_doors", "open")


func _on_target_died(_by_peer: int) -> void:
	GameSession.complete_objective("kill")  # sans effet si la cible ressuscite (reset) puis meurt encore


## Tous les objectifs sont faits : écran de fin chez tous, puis retour au hub.
func _on_mission_completed() -> void:
	GameSession.announce_return(end_screen_seconds)
	await get_tree().create_timer(end_screen_seconds).timeout
	GameSession.load_arena(return_arena)
