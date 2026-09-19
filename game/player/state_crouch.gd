class_name StateCrouch
extends PlayerState
## Accroupi volontaire : maintenir C / Ctrl. Déplacement lent, on se relève au relâchement
## (s'il y a la place). Saut et dash restent possibles une fois relevable.


func enter() -> void:
	player.crouch.crouched = true


func exit() -> void:
	player.crouch.crouched = false


func physics_update(delta: float) -> void:
	var config := player.config
	player.apply_gravity(delta)

	var can_stand := player.crouch.can_stand()
	if can_stand and Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.jump_velocity()
		player.change_state(&"Walk")
		return
	if can_stand and player.wants_dash():
		player.change_state(&"Dash")
		return
	if can_stand and (not Input.is_action_pressed("slide") or not player.is_on_floor()):
		player.change_state(&"Walk")
		return

	var horizontal := Vector2(player.velocity.x, player.velocity.z)
	if player.wish_dir != Vector3.ZERO:
		horizontal = horizontal.move_toward(Vector2(player.wish_dir.x, player.wish_dir.z) * config.crouch_speed, config.ground_acceleration * delta)
	else:
		horizontal = horizontal.move_toward(Vector2.ZERO, config.ground_friction * delta)
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.y
