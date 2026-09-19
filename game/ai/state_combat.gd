extends EnemyState
## Combat : fait face au joueur vu, s'approche s'il est loin, strafe latéralement sinon, et tire
## (EnemyWeapon : réaction, cadence, dispersion). Retour en alerte si le joueur est perdu ou s'éloigne.

var _strafe_sign := 1.0
var _strafe_left := 0.0


func enter() -> void:
	enemy.weapon.reset()
	_strafe_left = 0.0


func physics_update(delta: float) -> void:
	var config := enemy.config
	var too_far := enemy.awareness.seen_distance() > config.combat_distance + config.combat_exit_margin
	if enemy.awareness.time_since_seen > config.combat_lose_time or too_far:
		enemy.change_state(&"Alert")
		return
	var target := enemy.perception.seen_player
	enemy.weapon.tick(delta, target)
	if target == null:
		return
	if enemy.awareness.seen_distance() > config.preferred_distance:
		enemy.move_to(target.global_position, config.combat_speed, delta)
	else:
		_strafe(delta)
	enemy.face_point(target.global_position, delta)


func _strafe(delta: float) -> void:
	_strafe_left -= delta
	if _strafe_left <= 0.0 or enemy.get_slide_collision_count() > 0:  # timer ou obstacle : on change de côté
		_strafe_sign = -_strafe_sign if _strafe_left <= 0.0 or randf() < 0.5 else _strafe_sign
		_strafe_left = enemy.config.strafe_change_time
	var side := enemy.global_basis.x * _strafe_sign * enemy.config.strafe_speed
	enemy.velocity.x = side.x
	enemy.velocity.z = side.z
