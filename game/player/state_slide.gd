class_name StateSlide
extends PlayerState
## Glissade qui conserve l'élan : direction figée, vitesse >= slide_speed puis friction.
## Après slide_duration on se relève si possible ; sinon on rampe sous l'obstacle.

var _dir := Vector3.ZERO
var _speed := 0.0
var _left := 0.0


func enter() -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	_dir = horizontal.normalized()
	_speed = maxf(horizontal.length(), player.config.slide_speed)
	_left = player.config.slide_duration
	player.crouch.crouched = true


func exit() -> void:
	player.crouch.crouched = false


func physics_update(delta: float) -> void:
	var config := player.config
	_left -= delta
	player.apply_gravity(delta)

	var can_stand := player.crouch.can_stand()
	if can_stand and Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity()  # l'élan est conservé
		player.change_state(&"Walk")
		return
	if can_stand and player.wants_dash():
		player.change_state(&"Dash")
		return
	if can_stand and (_left <= 0.0 or not player.is_on_floor()):
		# touche toujours maintenue : on reste accroupi (au sol ou en chute, l'élan est conservé)
		player.change_state(&"Crouch" if Input.is_action_pressed("slide") else &"Walk")
		return

	if _left > 0.0:
		_speed = maxf(_speed - config.slide_friction * delta, 0.0)
		player.velocity.x = _dir.x * _speed
		player.velocity.z = _dir.z * _speed
	else:
		player.velocity.x = player.wish_dir.x * config.crawl_speed
		player.velocity.z = player.wish_dir.z * config.crawl_speed
