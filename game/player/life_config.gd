class_name LifeConfig
extends Resource
## Métriques de vie/down/réanimation (GDD §5). Source unique : default_life.tres.

@export var down_duration: float = 15.0
@export var revive_time: float = 3.0
@export var revive_range: float = 2.5
@export_range(0.0, 1.0) var revive_health_fraction: float = 0.5
