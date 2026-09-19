class_name EnemyConfig
extends Resource
## Métriques d'un ennemi (tranche 3.1 : patrouille). Perception/combat s'ajouteront avec leurs tranches.

@export_group("Vie")
@export var max_health: float = 80.0
@export var respawn_delay: float = 30.0  # le cadavre reste ce temps (il peut être découvert)

@export_group("Patrouille")
@export var walk_speed: float = 3.0
@export var turn_speed: float = 8.0
@export var waypoint_tolerance: float = 0.6
@export var wait_time: float = 1.5
@export var gravity: float = 24.0

@export_group("Perception")
@export var view_distance: float = 20.0
@export var view_fov_degrees: float = 110.0
@export var eye_height: float = 1.6
@export var target_height: float = 1.2  # point visé sur le joueur pour la ligne de vue
@export var vision_interval: float = 0.1

@export_group("États")
@export var investigate_speed: float = 3.5
@export var chase_speed: float = 5.5
@export var detect_time: float = 1.0  # vue continue nécessaire pour passer de suspicion à alerte
@export var detect_decay_time: float = 3.0  # temps pour oublier une détection non entretenue
@export var search_time: float = 4.0  # durée de la fouille à l'arrivée en suspicion
@export var search_turn_speed: float = 1.5  # rad/s, regarde autour
@export var alert_lose_time: float = 6.0  # sans voir le joueur : l'alerte retombe en suspicion
@export var alert_share_radius: float = 60.0  # alerte globale partagée (rayon)
@export var combat_distance: float = 12.0
@export var combat_exit_margin: float = 3.0
@export var combat_lose_time: float = 1.0
@export var preferred_distance: float = 8.0  # en combat : s'approche au-delà, strafe en deçà
@export var combat_speed: float = 3.5
@export var strafe_speed: float = 2.5
@export var strafe_change_time: float = 1.8
@export var retarget_distance: float = 0.25  # cible de navigation : on ne recalcule qu'au-delà

@export_group("Infiltration")
@export_range(-1.0, 1.0) var takedown_back_dot: float = -0.2  # attaquant derrière : cos(angle) <= ceci (≈ hors du demi-plan avant)
@export var body_height: float = 0.3  # point visé sur un cadavre pour la ligne de vue

@export_group("Tir")
@export var damage: float = 8.0
@export var fire_interval: float = 0.9
@export var reaction_time: float = 0.7  # vue continue avant le premier tir : le joueur peut réagir
@export var spread_degrees: float = 3.0
@export var attack_range: float = 40.0

@export_group("Présentation")
@export var net_smoothing: float = 15.0
@export var flash_time: float = 0.15
