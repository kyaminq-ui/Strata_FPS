class_name NoiseBus
extends Node
## Bus d'événements de bruit (host). Les sources (tirs, explosions) appellent emit_at() ;
## les `Perception` des ennemis s'y abonnent. Trouvé par le groupe « noise_bus » (pas de singleton).

signal noise_emitted(position: Vector3, radius: float, kind: StringName)

const GUNSHOT := &"gunshot"
const EXPLOSION := &"explosion"


func _enter_tree() -> void:
	add_to_group("noise_bus")


## Host uniquement (appelé depuis la résolution host des tirs/explosions).
static func emit_at(tree: SceneTree, position: Vector3, radius: float, kind: StringName) -> void:
	var bus := tree.get_first_node_in_group("noise_bus") as NoiseBus
	if bus:
		bus.noise_emitted.emit(position, radius, kind)
