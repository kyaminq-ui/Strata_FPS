class_name MovementConfig
extends Resource
## Source unique des métriques de mouvement. Voir docs/MOVEMENT_METRICS.md.
## Les champs saut/dash/slide/wall-run seront ajoutés avec leur couche.

@export_group("Couche A - Marche")
@export var walk_speed: float = 8.0
@export var ground_acceleration: float = 60.0
@export var ground_friction: float = 50.0
@export var air_acceleration: float = 20.0
@export var gravity: float = 24.0

@export_group("Regard")
@export var mouse_sensitivity: float = 0.0022
@export var max_pitch_degrees: float = 89.0
