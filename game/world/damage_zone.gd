extends Area3D
## Zone qui inflige des dégâts continus aux joueurs (host uniquement). Sert de piège de
## level design et de source de dégâts de test tant qu'il n'y a pas d'ennemis.

@export var damage_per_second: float = 40.0


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	for body in get_overlapping_bodies():
		var health := body.get_node_or_null("Health") as HealthComponent
		if health:
			health.take_damage(damage_per_second * delta)
