class_name GrenadeSpawner
extends MultiplayerSpawner
## Instancie les grenades (host) et les réplique aux clients. Trouvé par le groupe
## « grenade_spawner » : la logique de lancer n'a pas besoin de connaître l'arène.
## Gère aussi l'effet visuel d'explosion (cosmétique, joué sur tous les peers).

const GRENADE_SCENE := preload("res://game/weapons/grenade.tscn")
const FX_DURATION := 0.35
const FX_START_SCALE := 0.3

var _next_id := 0


func _ready() -> void:
	add_to_group("grenade_spawner")
	spawn_function = _create_grenade


## Host uniquement.
func throw(position: Vector3, velocity: Vector3, thrower_id: int) -> void:
	if not multiplayer.is_server():
		return
	_next_id += 1
	spawn({"id": _next_id, "position": position, "velocity": velocity, "thrower_id": thrower_id})


func _create_grenade(data: Dictionary) -> Node:
	var grenade: Grenade = GRENADE_SCENE.instantiate()
	grenade.name = "Grenade%d" % data.id
	grenade.position = data.position
	grenade.initial_velocity = data.velocity
	grenade.thrower_id = data.thrower_id
	return grenade


## Host : joue l'effet ici et le fait jouer chez les clients.
func explosion_fx(position: Vector3, radius: float) -> void:
	_play_fx(position, radius)
	if not multiplayer.get_peers().is_empty():
		show_explosion.rpc(position, radius)


@rpc("any_peer", "call_remote", "reliable")
func show_explosion(position: Vector3, radius: float) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		_play_fx(position, radius)


func _play_fx(position: Vector3, radius: float) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.6, 0.15, 0.7)
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	var fx := MeshInstance3D.new()
	fx.mesh = mesh
	fx.material_override = material
	get_parent().add_child(fx)
	fx.global_position = position
	fx.scale = Vector3.ONE * FX_START_SCALE
	var tween := fx.create_tween().set_parallel()
	tween.tween_property(fx, "scale", Vector3.ONE * radius, FX_DURATION)
	tween.tween_property(material, "albedo_color:a", 0.0, FX_DURATION)
	tween.chain().tween_callback(fx.queue_free)
