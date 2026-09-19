class_name ReinforcementConfig
extends Resource
## Renforts déclenchés par une alerte frontale (GDD §4 : le frontal est viable mais génère des renforts).

@export var delay: float = 8.0  # après l'alerte, si elle dure encore
@export var count: int = 2
@export var cooldown: float = 60.0  # entre deux vagues
@export var max_alive: int = 3
## Archétypes des renforts, en alternance (vide = la config de la scène ennemie).
@export var unit_types: Array[EnemyConfig] = []
