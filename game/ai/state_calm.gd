extends EnemyState
## Calme : patrouille sur la route (boucle), avec une pause à chaque waypoint.

var _wait_left := 0.0


func enter() -> void:
	_wait_left = 0.0


func physics_update(delta: float) -> void:
	if enemy.waypoints.is_empty():
		return
	if _wait_left > 0.0:
		_wait_left -= delta
		return
	if enemy.move_to(enemy.waypoints[enemy.wp_index], enemy.config.walk_speed, delta):
		enemy.wp_index = (enemy.wp_index + 1) % enemy.waypoints.size()
		_wait_left = enemy.config.wait_time
