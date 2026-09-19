class_name PlayerSpawner
extends MultiplayerSpawner
## Le host instancie un Player par peer (nommé par son peer id) ; le
## MultiplayerSpawner rejoue spawn_function chez les clients avec les mêmes données.
## Solo = le host seul.

const PLAYER_SCENE := preload("res://game/player/player.tscn")

@export var spawn_points_path: NodePath

@onready var _players_root: Node = get_node(spawn_path)
@onready var _spawn_points: Node = get_node(spawn_points_path)


func _ready() -> void:
	spawn_function = _create_player
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.connect(_spawn_player)
	multiplayer.peer_disconnected.connect(_despawn_player)
	_spawn_player(multiplayer.get_unique_id())


func _spawn_player(peer_id: int) -> void:
	var markers := _spawn_points.get_children()
	var marker: Node3D = markers[_players_root.get_child_count() % markers.size()]
	spawn({"peer_id": peer_id, "position": marker.position})


func _create_player(data: Dictionary) -> Node:
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(data.peer_id)
	player.position = data.position
	player.net_position = data.position
	return player


func _despawn_player(peer_id: int) -> void:
	var player := _players_root.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
