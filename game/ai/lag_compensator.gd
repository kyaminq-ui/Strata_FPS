class_name LagCompensator
extends Node
## Lag compensation (host) : garde un court historique de la position du parent, que le host
## rembobine le temps de résoudre le tir d'un client (qui a visé ce qu'il voyait, en retard sur le host).
## Groupe « lag_comp » : la résolution des tirs appelle rewind() / unrewind() sur tout le groupe.

@export var window: float = 0.15  # de combien on rembobine (s)

var _body: Enemy
var _history: Array = []  # [temps_ms, position]
var _saved_position := Vector3.ZERO
var _rewound := false


func _ready() -> void:
	_body = get_parent() as Enemy
	add_to_group("lag_comp")
	set_physics_process(multiplayer.is_server())


func clear() -> void:
	_history.clear()


func _physics_process(_delta: float) -> void:
	if _rewound or _body.is_dead():
		return
	var now := Time.get_ticks_msec()
	_history.append([now, _body.global_position])
	while _history.size() > 1 and now - _history[0][0] > window * 2000.0:
		_history.pop_front()


func rewind() -> void:
	if _history.is_empty() or _rewound or _body.is_dead():
		return
	var target_time := Time.get_ticks_msec() - window * 1000.0
	var past: Vector3 = _history[0][1]
	for sample in _history:
		past = sample[1]
		if sample[0] >= target_time:
			break
	_saved_position = _body.global_position
	_body.global_position = past
	_rewound = true


func unrewind() -> void:
	if _rewound:
		_body.global_position = _saved_position
		_rewound = false
