class_name StateWallRun
extends PlayerState
## Course latérale sur un mur, en l'air, en gardant « avant » appuyé. Le saut de mur
## pousse à l'opposé du mur en conservant l'élan. Dash et fin de mur/durée sortent de l'état.

const WORLD_MASK := 1

var _normal := Vector3.ZERO
var _tangent := Vector3.ZERO
var _time_left := 0.0
var _pending_normal := Vector3.ZERO


## Vrai si les conditions de démarrage sont réunies (mémorise le mur pour enter()).
func can_start() -> bool:
	var config := player.config
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if player.wall_cooldown_left > 0.0 or horizontal.length() < config.wallrun_min_speed:
		return false
	if not Input.is_action_pressed("move_forward"):
		return false
	var normal := _find_wall()
	if normal == Vector3.ZERO or absf(horizontal.normalized().dot(normal)) > config.wallrun_max_approach_dot:
		return false
	_pending_normal = normal
	return true


func enter() -> void:
	var config := player.config
	_normal = _pending_normal
	_tangent = _tangent_for(_normal, Vector3(player.velocity.x, 0.0, player.velocity.z))
	_time_left = config.wallrun_duration
	player.velocity.y = minf(player.velocity.y, config.wallrun_max_rise)
	var side := -signf(_normal.dot(player.global_basis.x))  # +1 : mur à droite
	player.camera_roll_target = side * config.wallrun_camera_tilt_degrees


func exit() -> void:
	player.camera_roll_target = 0.0


func physics_update(delta: float) -> void:
	var config := player.config
	if player.wants_dash():
		_leave()
		player.change_state(&"Dash")
		return
	if Input.is_action_just_pressed("jump"):
		_wall_jump()
		return

	_time_left -= delta
	var normal := _find_wall()
	if normal == Vector3.ZERO or player.is_on_floor() or _time_left <= 0.0 \
			or not Input.is_action_pressed("move_forward"):
		_leave()
		player.change_state(&"Walk")
		return

	_normal = normal
	_tangent = _tangent_for(_normal, _tangent)
	player.velocity.x = _tangent.x * config.wallrun_speed - _normal.x * config.wallrun_stick_speed
	player.velocity.z = _tangent.z * config.wallrun_speed - _normal.z * config.wallrun_stick_speed
	player.velocity.y -= config.wallrun_gravity * delta


func _wall_jump() -> void:
	var config := player.config
	var speed := maxf(Vector2(player.velocity.x, player.velocity.z).length(), config.wallrun_speed)
	player.velocity = _tangent * speed + _normal * config.wall_jump_push
	player.velocity.y = sqrt(2.0 * config.gravity * config.wall_jump_height)
	_leave()
	player.change_state(&"Walk")


func _leave() -> void:
	player.wall_cooldown_left = player.config.wallrun_reattach_cooldown


## Direction le long du mur, orientée comme `reference` (la vitesse ou l'ancienne tangente).
func _tangent_for(normal: Vector3, reference: Vector3) -> Vector3:
	var tangent := Vector3.UP.cross(normal).normalized()
	return tangent if tangent.dot(reference) >= 0.0 else -tangent


## Normale du mur juste à côté du joueur (perpendiculairement à sa course), sinon ZERO.
func _find_wall() -> Vector3:
	var config := player.config
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal.length() < 0.1:
		return Vector3.ZERO
	var right := horizontal.normalized().cross(Vector3.UP)
	var origin := player.global_position + Vector3.UP * config.wall_check_height
	var space := player.get_world_3d().direct_space_state
	for direction in [right, -right]:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * config.wall_check_distance, WORLD_MASK)
		var hit := space.intersect_ray(query)
		if not hit.is_empty() and absf(hit.normal.y) < 0.2:
			return hit.normal
	return Vector3.ZERO
