class_name PlayerLife
extends Node
## Vie du joueur. Coop : à 0 PV on passe « down » (même si le partenaire est déjà down) et le
## partenaire vivant peut réanimer ; si le délai expire, respawn au point d'apparition. Quand tous
## les joueurs sont down, ils respawn ensemble après un court délai. Sans partenaire du tout
## (solo, partenaire parti) : respawn immédiat. Le HOST décide de tout ; downed / down_time_left /
## revive_progress sont répliqués par SyncServer (autorité = host).

signal downed_changed(downed: bool)

const SERVER_RANGE_TOLERANCE := 1.5

@export var config: LifeConfig

var downed := false
var down_time_left := 0.0
var revive_progress := 0.0

var _last_downed := false
var _reviver_id := 0

@onready var _player: Player = get_parent()
@onready var _health: HealthComponent = $"../Health"


func _ready() -> void:
	if multiplayer.is_server():
		_health.died.connect(_on_health_depleted)


func _process(_delta: float) -> void:
	if downed != _last_downed:
		_last_downed = downed
		downed_changed.emit(downed)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or not downed:
		return
	down_time_left -= delta
	if _valid_reviver() != null:
		revive_progress = minf(revive_progress + delta / config.revive_time, 1.0)
	else:
		revive_progress = 0.0
	if revive_progress >= 1.0:
		_revive()
	elif _other_players().is_empty():
		_respawn()  # plus de partenaire (parti) : rien à attendre
	else:
		if _other_alive_players().is_empty():  # tous down : on n'attend pas la fin du délai complet
			down_time_left = minf(down_time_left, config.all_down_respawn_delay)
		if down_time_left <= 0.0:
			_respawn()


## Appelé par le réanimateur (son client -> host). Le tireur est identifié par le RPC.
@rpc("any_peer", "call_remote", "reliable")
func request_revive(active: bool) -> void:
	if multiplayer.is_server():
		set_reviver(multiplayer.get_remote_sender_id(), active)


func set_reviver(peer_id: int, active: bool) -> void:
	if active:
		_reviver_id = peer_id
	elif _reviver_id == peer_id:
		_reviver_id = 0


func _on_health_depleted(_by_peer: int) -> void:
	if _other_players().is_empty():
		_respawn()  # solo / partenaire parti : pas de down
		return
	downed = true
	down_time_left = config.down_duration
	revive_progress = 0.0
	_reviver_id = 0


func _revive() -> void:
	downed = false
	revive_progress = 0.0
	_reviver_id = 0
	_health.health = _health.max_health * config.revive_health_fraction


func _respawn() -> void:
	downed = false
	revive_progress = 0.0
	_reviver_id = 0
	_health.reset()
	var markers := get_tree().get_nodes_in_group("spawn_points")
	var position := Vector3.ZERO
	if not markers.is_empty():
		position = (markers[_player.name.to_int() % markers.size()] as Node3D).global_position
	_player.respawn_at(position)


func _valid_reviver() -> Player:
	if _reviver_id == 0:
		return null
	var reviver := _player.get_parent().get_node_or_null(str(_reviver_id)) as Player
	if reviver == null or reviver.life.downed or reviver.health.is_dead():
		return null
	if reviver.net_position.distance_to(_player.net_position) > config.revive_range * SERVER_RANGE_TOLERANCE:
		return null
	return reviver


func _other_players() -> Array[Player]:
	var result: Array[Player] = []
	for node in _player.get_parent().get_children():
		var other := node as Player
		if other != null and other != _player:
			result.append(other)
	return result


func _other_alive_players() -> Array[Player]:
	var result: Array[Player] = []
	for node in _player.get_parent().get_children():
		var other := node as Player
		if other != null and other != _player and not other.life.downed and not other.health.is_dead():
			result.append(other)
	return result
