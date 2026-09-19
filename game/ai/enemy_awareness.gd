class_name EnemyAwareness
extends Node
## Conscience d'un ennemi (host) : transforme la perception en décisions d'état.
## Vue → jauge de détection → alerte ; bruit → suspicion ; dégâts → alerte ; alerte partagée entre ennemis.
## Expose la dernière position perçue (`investigate_position`) et le temps depuis la dernière vue.

var investigate_position := Vector3.ZERO  # dernière position perçue (vue ou bruit) : cible des états
var time_since_seen := 0.0

var _enemy: Enemy
var _perception: Perception
var _detect := 0.0  # 0..1, monte quand un joueur est vu en calme/suspicion ; à 1 = alerte


func _ready() -> void:
	_enemy = get_parent() as Enemy
	if not multiplayer.is_server():
		set_physics_process(false)
		return
	add_to_group("enemy_awareness")
	_perception = _enemy.get_node("Perception")
	_perception.noise_heard.connect(_on_noise_heard)
	_perception.body_spotted.connect(_on_body_spotted)
	(_enemy.get_node("Health") as HealthComponent).damaged.connect(_on_damaged)


func reset() -> void:
	_detect = 0.0
	time_since_seen = _enemy.config.alert_lose_time


func sees_player() -> bool:
	return _perception.seen_player != null


func seen_distance() -> float:
	return _enemy.global_position.distance_to(_perception.seen_player.global_position) if sees_player() else INF


func _physics_process(delta: float) -> void:
	if _enemy.is_dead():
		return
	if sees_player():
		time_since_seen = 0.0
		investigate_position = _perception.last_seen_position
	else:
		time_since_seen += delta
	if not is_unaware():
		return
	if sees_player():
		_detect += delta / _enemy.config.detect_time
		if _detect >= 1.0:
			become_alert()
		elif _enemy.state_name == &"Calm":
			_enemy.change_state(&"Suspicious")
	else:
		_detect = maxf(_detect - delta / _enemy.config.detect_decay_time, 0.0)


## Alerte partagée : un ennemi qui passe en alerte prévient tous les autres à portée.
func become_alert() -> void:
	_enemy.change_state(&"Alert")
	get_tree().call_group("enemy_awareness", "receive_alert", investigate_position)
	get_tree().call_group("reinforcements", "on_alert", investigate_position)


## Alerte imposée (renforts qui arrivent) : pas de propagation.
func force_alert(position: Vector3) -> void:
	investigate_position = position
	_enemy.change_state(&"Alert")


func receive_alert(position: Vector3) -> void:
	if _enemy.is_dead() or not is_unaware():
		return
	if _enemy.global_position.distance_to(position) > _enemy.config.alert_share_radius:
		return
	investigate_position = position
	_enemy.change_state(&"Alert")


func is_unaware() -> bool:
	return _enemy.state_name == &"Calm" or _enemy.state_name == &"Suspicious"


func _on_noise_heard(position: Vector3, _kind: StringName) -> void:
	if is_unaware():
		investigate_position = position
		_enemy.change_state(&"Suspicious")  # ré-entrée : relance l'enquête vers le nouveau bruit
	elif _enemy.state_name == &"Alert" and not sees_player():
		investigate_position = position


## Un cadavre découvert rend suspect (jamais une alerte directe).
func _on_body_spotted(position: Vector3) -> void:
	if is_unaware():
		investigate_position = position
		_enemy.change_state(&"Suspicious")


## Être touché alerte l'ennemi et révèle la position du tireur.
func _on_damaged(_amount: float, by_peer: int) -> void:
	if _enemy.is_dead():
		return  # coup mortel (dont élimination silencieuse) : personne n'est prévenu
	var shooter := get_tree().get_nodes_in_group("players").filter(func(p: Node) -> bool: return p.name == str(by_peer))
	if not shooter.is_empty():
		investigate_position = (shooter[0] as Node3D).global_position
	if is_unaware():
		become_alert()
