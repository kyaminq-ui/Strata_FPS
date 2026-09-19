extends EnemyState
## Suspicion : va vers la dernière position perçue (vue ou bruit), regarde autour, puis revient au calme.

var _arrived := false
var _search_left := 0.0


func enter() -> void:
	_arrived = false
	_search_left = enemy.config.search_time


func physics_update(delta: float) -> void:
	if not _arrived or enemy.sees_player():
		_arrived = enemy.move_to(enemy.investigate_position, enemy.config.investigate_speed, delta)
		return
	enemy.rotation.y += enemy.config.search_turn_speed * delta  # regarde autour
	_search_left -= delta
	if _search_left <= 0.0:
		enemy.change_state(&"Calm")
