class_name Tracer
extends RefCounted
## Trait de tir purement cosmétique (local à chaque peer, sans autorité).

const LIFETIME := 0.06
const THICKNESS := 0.03

static var _material: StandardMaterial3D


static func spawn(parent: Node, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.1:
		return
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.albedo_color = Color(1.0, 0.9, 0.5)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(THICKNESS, THICKNESS, length)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material
	parent.add_child(instance)
	var direction := (to - from) / length
	var up := Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT
	instance.global_position = (from + to) * 0.5
	instance.look_at(to, up)
	parent.get_tree().create_timer(LIFETIME).timeout.connect(instance.queue_free)
