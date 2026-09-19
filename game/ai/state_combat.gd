extends EnemyState
## Combat : s'arrête et fait face au joueur vu. (Le tir et le déplacement de combat arrivent en 3.4.)
## Retour en alerte si le joueur est perdu de vue un instant ou s'éloigne.


func physics_update(delta: float) -> void:
	var too_far := enemy.seen_distance() > enemy.config.combat_distance + enemy.config.combat_exit_margin
	if enemy.time_since_seen > enemy.config.combat_lose_time or too_far:
		enemy.change_state(&"Alert")
		return
	if enemy.sees_player():
		enemy.face_point(enemy.investigate_position, delta)
