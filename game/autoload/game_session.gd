extends Node
## État de session mince, décidé par le HOST : dernier checkpoint actif et reset de rencontre.
## Solo = host seul (même code). Les clients n'ont pas besoin de cet état : le respawn est ordonné
## par le host (Player.respawn_at) et l'affichage des checkpoints passe par leur RPC.

## Le checkpoint (un Checkpoint) est volontairement non typé : Checkpoint appelle GameSession, le typer ici
## créerait une dépendance circulaire (qui casse la compilation selon l'ordre de chargement).
signal checkpoint_changed(checkpoint)
signal objectives_changed
signal objective_completed(text: String)
signal mission_completed

var checkpoint
var objectives: Array[Dictionary] = []  # {id, text, done} : décidé par le host puis diffusé
var mission_done := false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)


## À appeler quand on entre dans / quitte une arène.
func reset() -> void:
	checkpoint = null
	objectives.clear()
	mission_done = false
	objectives_changed.emit()


## Host : définit les objectifs de la mission (à l'entrée de l'arène).
func set_objectives(list: Array) -> void:
	if multiplayer.is_server():
		_sync_objectives.rpc(list, false)


## Host : un objectif est atteint (sans effet s'il l'était déjà ou s'il n'existe pas).
func complete_objective(id: String) -> void:
	if not multiplayer.is_server():
		return
	var updated: Array = objectives.duplicate(true)
	var changed := false
	for objective: Dictionary in updated:
		if objective.id == id and not objective.done:
			objective.done = true
			changed = true
	if changed:
		_sync_objectives.rpc(updated, updated.all(func(o: Dictionary) -> bool: return o.done))


## Objectif à afficher : le premier non terminé (vide si tout est fait).
func current_objective_text() -> String:
	for objective in objectives:
		if not objective.done:
			return objective.text
	return ""


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_sync_objectives.rpc_id(peer_id, objectives, mission_done)


@rpc("authority", "call_local", "reliable")
func _sync_objectives(list: Array, done: bool) -> void:
	var newly_done: Array[String] = []
	for objective: Dictionary in list:
		var previous := objectives.filter(func(o: Dictionary) -> bool: return o.id == objective.id)
		if objective.done and not previous.is_empty() and not previous[0].done:
			newly_done.append(objective.text)
	objectives.assign(list)
	var was_done := mission_done
	mission_done = done
	objectives_changed.emit()
	for text in newly_done:
		objective_completed.emit(text)
	if done and not was_done:
		mission_completed.emit()


## Host : enregistre le checkpoint atteint (les autres s'éteignent).
func set_checkpoint(new_checkpoint: Node3D) -> void:
	if not multiplayer.is_server() or new_checkpoint == checkpoint:
		return
	if is_instance_valid(checkpoint):
		checkpoint.set_active.rpc(false)
	checkpoint = new_checkpoint
	checkpoint.set_active.rpc(true)
	checkpoint_changed.emit(checkpoint)


## Où faire réapparaître le joueur numéro `slot` : dernier checkpoint, sinon marqueur de départ de l'arène.
func respawn_position(slot: int) -> Vector3:
	if is_instance_valid(checkpoint):
		return checkpoint.spawn_position(slot)
	var markers := get_tree().get_nodes_in_group("spawn_points")
	if markers.is_empty():
		return Vector3.ZERO
	return (markers[slot % markers.size()] as Node3D).global_position


## Host : plus aucun joueur debout (solo mort, coop tous down) -> la rencontre repart de zéro.
func reset_encounter() -> void:
	get_tree().call_group("enemies", "reset_encounter")
