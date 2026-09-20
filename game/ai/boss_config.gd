class_name BossConfig
extends Resource
## Réglages du boss « Fixeur » (2 phases). Les valeurs de combat de chaque phase sont des EnemyConfig
## (boss_phase1.tres, boss_phase2.tres) ; ici : le passage de phase et l'onde de choc de la phase 2.

@export var phase_two: EnemyConfig  # config appliquée en phase 2
@export_range(0.05, 0.95) var phase_two_fraction: float = 0.5  # part de PV restante qui déclenche la phase 2
@export var phase_two_text: String = "LE FIXEUR EST EN FURIE"

@export_group("Onde de choc (phase 2)")
@export var shockwave_interval: float = 7.0  # s de combat entre deux ondes
@export var shockwave_delay: float = 1.5  # s de télégraphie avant l'impact
@export var shockwave_radius: float = 6.0  # m autour de la position du boss au début de la télégraphie
@export var shockwave_damage: float = 25.0
@export var shockwave_dodge_height: float = 1.0  # m au-dessus du sol : un joueur qui saute l'évite
