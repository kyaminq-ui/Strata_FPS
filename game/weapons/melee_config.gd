class_name MeleeConfig
extends Resource
## Métriques de la mêlée (GDD §4) : coup rapide, bonus après dash, finisseur simple.
## Source unique : default_melee.tres.

@export var damage: float = 40.0
@export var range: float = 2.4
@export_range(1.0, 90.0) var half_angle_degrees: float = 50.0
@export var cooldown: float = 0.55
@export var swing_time: float = 0.2
@export_group("Dash -> mêlée")
@export var dash_damage_multiplier: float = 1.5
@export var dash_range_bonus: float = 1.0
@export_group("Finisseur")
@export_range(0.0, 1.0) var finisher_health_fraction: float = 0.3
