class_name GrenadeConfig
extends Resource
## Métriques de la grenade explosive. Source unique : default_grenade.tres.
## Elle explose à la fin de la mèche OU dès qu'elle est touchée par un tir (elle a des PV).

@export_group("Lancer")
@export var throw_speed: float = 14.0
@export var throw_lift: float = 3.0
@export var throw_cooldown: float = 0.7
@export var max_carried: int = 2
@export var recharge_time: float = 6.0
@export_group("Grenade")
@export var fuse_time: float = 2.5
@export var bounce: float = 0.35
@export_group("Explosion")
@export var blast_radius: float = 5.0
@export var damage: float = 90.0  # au centre, décroît linéairement jusqu'au bord
@export_range(0.0, 1.0) var player_damage_multiplier: float = 0.5  # tir ami / dégâts sur soi
@export var noise_radius: float = 35.0  # bruit de l'explosion (ennemis)
