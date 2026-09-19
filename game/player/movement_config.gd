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

@export_group("Couche B - Saut")
@export var jump_height: float = 1.6
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Couche D - Dash")
@export var dash_distance: float = 6.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.8
@export var dash_melee_window: float = 0.5  # après le début du dash : mêlée renforcée
@export var dash_jump_speed: float = 12.0  # vitesse horizontale conservée en sautant pendant un dash

@export_group("Couche E - Slide")
@export var slide_min_entry_speed: float = 5.0
@export var slide_speed: float = 12.0
@export var slide_duration: float = 0.8
@export var slide_friction: float = 6.0
@export var crawl_speed: float = 3.0  # sous un obstacle, fin de slide
@export var crouch_speed: float = 4.0  # accroupi volontaire (C / Ctrl maintenu)
@export var slide_height: float = 1.0
@export var slide_head_height: float = 0.75
@export var crouch_transition: float = 0.1

@export_group("Couche F - Wall-run")
@export var wallrun_min_speed: float = 6.0
@export var wallrun_speed: float = 10.0
@export var wallrun_duration: float = 1.5
@export var wallrun_gravity: float = 2.0
@export var wallrun_max_rise: float = 3.0
@export var wallrun_stick_speed: float = 2.0
@export var wallrun_max_approach_dot: float = 0.8
@export var wallrun_reattach_cooldown: float = 0.35
@export var wallrun_camera_tilt_degrees: float = 8.0
@export var wall_check_distance: float = 0.7
@export var wall_check_height: float = 1.0
@export var wall_jump_push: float = 6.0
@export var wall_jump_height: float = 1.6

@export_group("Regard")
@export var mouse_sensitivity: float = 0.0022
@export var max_pitch_degrees: float = 89.0
