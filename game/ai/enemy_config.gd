class_name EnemyConfig
extends Resource
## Métriques d'un ennemi (tranche 3.1 : patrouille). Perception/combat s'ajouteront avec leurs tranches.

@export_group("Vie")
@export var max_health: float = 80.0
@export var respawn_delay: float = 5.0

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
@export var heard_display_time: float = 1.5  # debug : durée d'affichage « HEARD »

@export_group("Présentation")
@export var net_smoothing: float = 15.0
@export var flash_time: float = 0.15
