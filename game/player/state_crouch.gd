class_name StateCrouch
extends PlayerState
## Accroupi volontaire : maintenir C / Ctrl, au sol comme en l'air. Au sol : déplacement lent ;
## en l'air : l'élan est conservé (contrôle aérien normal) et un atterrissage assez rapide devient un slide.
## On se relève au relâchement (s'il y a la place). Saut et dash restent possibles une fois relevable.

var _airborne := false


func enter() -> void:
	player.crouch.crouched = true
	_airborne = not player.is_on_floor()


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
	if can_stand and not Input.is_action_pressed("slide"):
		player.change_state(&"Walk")
		return

	var horizontal := Vector2(player.velocity.x, player.velocity.z)
	if _airborne:
		if player.is_on_floor():
			_airborne = false
			if horizontal.length() >= config.slide_min_entry_speed:
				player.change_state(&"Slide")  # atterrissage rapide : slide
				return
		elif player.wish_dir != Vector3.ZERO:
			horizontal = horizontal.move_toward(Vector2(player.wish_dir.x, player.wish_dir.z) * config.walk_speed, config.air_acceleration * delta)
		player.velocity.x = horizontal.x
		player.velocity.z = horizontal.y
		return
	if player.wish_dir != Vector3.ZERO:
		horizontal = horizontal.move_toward(Vector2(player.wish_dir.x, player.wish_dir.z) * config.crouch_speed, config.ground_acceleration * delta)
	else:
		horizontal = horizontal.move_toward(Vector2.ZERO, config.ground_friction * delta)
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.y
