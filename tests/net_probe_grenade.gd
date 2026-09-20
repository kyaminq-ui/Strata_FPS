extends SceneTree
## Sonde de test réseau (headless) pour les grenades. Deux modes :
##  --mode=throw : le client lance une grenade au sol (le host tirera dessus) ;
##  --mode=shoot : le client attend une grenade du host, puis tire dessus au pistolet.
## Affiche ce que le client voit : grenade répliquée, déplacement, disparition, hit confirmé.
## Usage : godot --headless --path . -s tests/net_probe_grenade.gd -- --join=127.0.0.1 --mode=throw

const SETTLE_SECONDS := 2.0
const SHOOT_DELAY := 1.2  # après avoir vu la grenade (mode shoot)
const LIFETIME := 9.0
const THROW_PITCH := -1.0  # rad, vers le sol

var _mode := "throw"
var _elapsed := 0.0
var _throw_time := -1.0
var _first_seen := -1.0
var _gone_at := -1.0
var _first_position := Vector3.ZERO
var _last_position := Vector3.ZERO
var _hits := 0
var _shot := false
var _bound := false
var _count_after_throw := -1
var _color_changes := 0
var _last_color := Color.BLACK
var _main: Node


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(delta: float) -> bool:
	_elapsed += delta
	var players := _main.get_node_or_null("ArenaGraybox/Players")
	var container := _main.get_node_or_null("ArenaGraybox/Grenades")
	if players == null or container == null or _elapsed < SETTLE_SECONDS:
		return false
	var me = players.get_node_or_null(str(root.multiplayer.get_unique_id()))
	if me == null:
		return false
	if not _bound:
		me.weapon.hit_confirmed.connect(func(_killed: bool) -> void: _hits += 1)
		_bound = true
	Input.action_release("grenade")
	Input.action_release("fire")

	if _mode == "throw" and _throw_time < 0.0:
		me.get_node("Head").rotation.x = THROW_PITCH
		Input.action_press("grenade")
		_throw_time = _elapsed
	if _mode == "throw" and _throw_time > 0.0 and _count_after_throw < 0 and _elapsed > _throw_time + 0.2:
		_count_after_throw = me.grenades.count

	if container.get_child_count() > 0:
		var grenade := container.get_child(0) as Node3D
		if _first_seen < 0.0:
			_first_seen = _elapsed
			_first_position = grenade.global_position
		_last_position = grenade.global_position
		var material := grenade.get_node("Mesh").material_override as StandardMaterial3D
		if material != null and material.albedo_color != _last_color:
			_color_changes += 1
			_last_color = material.albedo_color
		if _mode == "shoot" and not _shot and _elapsed >= _first_seen + SHOOT_DELAY:
			_aim_and_fire(me, grenade)
	elif _first_seen >= 0.0 and _gone_at < 0.0:
		_gone_at = _elapsed

	if _elapsed > LIFETIME:
		print("[grenade probe] mode=", _mode, " vue=", _first_seen >= 0.0, " deplacement=", snappedf(_first_position.distance_to(_last_position), 0.1),
			" duree_de_vie=", snappedf(_gone_at - _first_seen, 0.01) if _gone_at >= 0.0 else -1.0,
			" changements_de_couleur_vus=", _color_changes, " hits_confirmes=", _hits, " stock_apres_lancer=", _count_after_throw)
		quit()
	return false


func _aim_and_fire(me, grenade: Node3D) -> void:
	var to_grenade = grenade.global_position - me.camera.global_position
	me.rotation.y = atan2(-to_grenade.x, -to_grenade.z)
	me.get_node("Head").rotation.x = atan2(to_grenade.y, Vector2(to_grenade.x, to_grenade.z).length())
	Input.action_press("fire")
	_shot = true
