class_name LagCompensator
extends Node
## Lag compensation (host) : garde un court historique de la position du parent. Un tir de client
## est testé contre la capsule du parent À SA POSITION PASSÉE (le client a visé ce qu'il voyait,
## en retard sur le host). Test analytique : déplacer le corps puis lancer un raycast ne marche pas,
## le serveur de physique n'applique le déplacement qu'au pas suivant.
## Groupe « lag_comp » : la résolution d'un tir de client interroge tout le groupe.

@export var window: float = 0.3  # de combien on rembobine (s) : couvre ~RTT 200 ms (0.15 suffit à RTT 100)

var _body: Enemy
var _history: Array = []  # [temps_ms, position]
var _radius := 0.45
var _height := 1.8


func _ready() -> void:
	_body = get_parent() as Enemy
	var shape_node := _body.get_node("CollisionShape3D") as CollisionShape3D
	var capsule := shape_node.shape as CapsuleShape3D
	_radius = capsule.radius
	_height = capsule.height
	add_to_group("lag_comp")
	set_physics_process(multiplayer.is_server())


func clear() -> void:
	_history.clear()


func _physics_process(_delta: float) -> void:
	if _body.is_dead():
		return
	var now := Time.get_ticks_msec()
	_history.append([now, _body.global_position])
	while _history.size() > 1 and now - _history[0][0] > window * 2000.0:
		_history.pop_front()


## Distance le long du rayon jusqu'à la capsule rembobinée, ou -1.0 (mort, historique vide, raté).
func ray_hit_distance(origin: Vector3, direction: Vector3, max_distance: float) -> float:
	if _history.is_empty() or _body.is_dead():
		return -1.0
	var target_time := Time.get_ticks_msec() - window * 1000.0
	var past: Vector3 = _history[0][1]
	for sample in _history:
		past = sample[1]
		if sample[0] >= target_time:
			break
	var axis_bottom := past + Vector3.UP * _radius
	var axis_top := past + Vector3.UP * (_height - _radius)
	var closest := Geometry3D.get_closest_points_between_segments(
			origin, origin + direction * max_distance, axis_bottom, axis_top)
	if closest[0].distance_to(closest[1]) > _radius:
		return -1.0
	return origin.distance_to(closest[0])
