class_name PlayerReviver
extends Node
## Côté réanimateur : maintenir « interact » près d'un partenaire down prévient le host
## (request_revive). Le host valide portée et progression ; ici on ne fait que demander.

@export var config: LifeConfig

var target: PlayerLife  # partenaire down à portée (pour l'invite HUD)

var _active_target: PlayerLife

@onready var _player: Player = get_parent()


func _physics_process(_delta: float) -> void:
	if not _player.is_multiplayer_authority():
		return
	target = _find_target()
	var wanted: PlayerLife = null
	if target != null and _player.can_act() and Input.is_action_pressed("interact"):
		wanted = target
	if wanted == _active_target:
		return
	if _active_target != null:
		_send(_active_target, false)
	if wanted != null:
		_send(wanted, true)
	_active_target = wanted


func _find_target() -> PlayerLife:
	if _player.life.downed:
		return null
	for node in _player.get_parent().get_children():
		var other := node as Player
		if other != null and other != _player and other.life.downed \
				and other.global_position.distance_to(_player.global_position) <= config.revive_range:
			return other.life
	return null


func _send(life: PlayerLife, active: bool) -> void:
	if multiplayer.is_server():
		life.set_reviver(multiplayer.get_unique_id(), active)
	else:
		life.request_revive.rpc_id(1, active)
