extends Node
## État de session mince, décidé par le HOST : dernier checkpoint actif et reset de rencontre.
## Solo = host seul (même code). Les clients n'ont pas besoin de cet état : le respawn est ordonné
## par le host (Player.respawn_at) et l'affichage des checkpoints passe par leur RPC.

## Le checkpoint (un Checkpoint) est volontairement non typé : Checkpoint appelle GameSession, le typer ici
## créerait une dépendance circulaire (qui casse la compilation selon l'ordre de chargement).
signal checkpoint_changed(checkpoint)

var checkpoint


## À appeler quand on entre dans / quitte une arène.
func reset() -> void:
	checkpoint = null


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
