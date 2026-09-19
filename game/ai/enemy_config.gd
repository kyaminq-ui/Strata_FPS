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

@export_group("Présentation")
@export var net_smoothing: float = 15.0
@export var flash_time: float = 0.15
