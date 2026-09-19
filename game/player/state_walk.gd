class_name StateWalk
extends PlayerState
## Marche au sol et mouvement en l'air (avec saut, coyote time, jump buffer).

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _wallrun: StateWallRun


func enter() -> void:
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_wallrun = player.get_state(&"WallRun") as StateWallRun


func physics_update(delta: float) -> void:
	var config := player.config
	if player.wants_dash():
		player.change_state(&"Dash")
		return
	if Input.is_action_just_pressed("slide") and _can_slide():
		player.change_state(&"Slide")
		return

	player.apply_gravity(delta)
	_update_jump(delta)

	var horizontal := Vector2(player.velocity.x, player.velocity.z)
	if player.wish_dir != Vector3.ZERO:
		var accel := config.ground_acceleration if player.is_on_floor() else config.air_acceleration
		horizontal = horizontal.move_toward(Vector2(player.wish_dir.x, player.wish_dir.z) * config.walk_speed, accel * delta)
	elif player.is_on_floor():
		horizontal = horizontal.move_toward(Vector2.ZERO, config.ground_friction * delta)
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.y

	if not player.is_on_floor() and _wallrun.can_start():
		player.change_state(&"WallRun")


func _can_slide() -> bool:
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	return player.is_on_floor() and speed >= player.config.slide_min_entry_speed


func _update_jump(delta: float) -> void:
	var config := player.config
	_coyote_left = config.coyote_time if player.is_on_floor() else maxf(_coyote_left - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = config.jump_buffer_time
	else:
		_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		player.velocity.y = player.jump_velocity()
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
