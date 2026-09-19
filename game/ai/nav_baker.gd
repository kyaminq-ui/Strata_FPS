extends NavigationRegion3D
## Bake le mesh de navigation à partir de la géométrie statique de l'arène (parent) au chargement.
## Seul le host a besoin de navigation (l'IA n'est simulée que chez lui).


func _ready() -> void:
	if not multiplayer.is_server():
		return
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(navigation_mesh, source, get_parent())
	NavigationServer3D.bake_from_source_geometry_data(navigation_mesh, source)
	navigation_mesh = navigation_mesh # réassigne pour synchroniser la région avec le mesh baké
