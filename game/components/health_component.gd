class_name HealthComponent
extends Node
## Points de vie. `health` est répliqué par le MultiplayerSynchronizer de la scène
## propriétaire ; seuls le host/serveur appellent take_damage() (signaux côté serveur).

signal damaged(amount: float, by_peer: int)
signal died(by_peer: int)

@export var max_health: float = 100.0

var health: float


func _ready() -> void:
	health = max_health


func is_dead() -> bool:
	return health <= 0.0


## Serveur seulement. Retourne vrai si ce coup tue.
func take_damage(amount: float, by_peer: int = 0) -> bool:
	if not multiplayer.is_server() or is_dead():
		return false
	health = maxf(health - amount, 0.0)
	damaged.emit(amount, by_peer)
	if is_dead():
		died.emit(by_peer)
		return true
	return false


func reset() -> void:
	health = max_health
