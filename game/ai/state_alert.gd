extends EnemyState
## Alerte : poursuit la dernière position connue du joueur. Passe en combat s'il est vu de assez près,
## retombe en suspicion si le joueur reste introuvable trop longtemps.


func enter() -> void:
	enemy.time_since_seen = 0.0  # l'alerte (bruit, dégâts, partage) compte comme un stimulus frais


func physics_update(delta: float) -> void:
	if enemy.sees_player() and enemy.seen_distance() <= enemy.config.combat_distance:
		enemy.change_state(&"Combat")
		return
	if enemy.time_since_seen > enemy.config.alert_lose_time:
		enemy.change_state(&"Suspicious")
		return
	if enemy.move_to(enemy.investigate_position, enemy.config.chase_speed, delta):
		enemy.rotation.y += enemy.config.search_turn_speed * delta  # arrivé : cherche du regard
