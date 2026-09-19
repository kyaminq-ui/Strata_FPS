class_name StateDash
extends PlayerState
## Impulsion horizontale courte, au sol ou en l'air. Sans direction voulue : vers l'avant.

var _dir := Vector3.ZERO
var _left := 0.0


func enter() -> void:
	var dir := player.wish_dir if player.wish_dir != Vector3.ZERO else -player.global_basis.z
	dir.y = 0.0
	_dir = dir.normalized()
	_left = player.config.dash_duration
	player.dash_cooldown_left = player.config.dash_cooldown


func physics_update(delta: float) -> void:
	var config := player.config
	_left -= delta
	player.velocity = _dir * (config.dash_distance / config.dash_duration)
	if _left <= 0.0:
		player.velocity = _dir * config.walk_speed
		player.change_state(&"Walk")
