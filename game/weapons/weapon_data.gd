class_name WeaponData
extends Resource
## Données d'une arme (aucune logique). Une arme = un .tres de ce type.
## `damage` est infligé par plomb : un fusil = `pellets` rayons de `damage` chacun.

@export var display_name: String = "Pistol"
@export var damage: float = 25.0
@export var fire_interval: float = 0.25
@export var automatic: bool = false
@export var max_range: float = 100.0
@export var magazine_size: int = 12
@export var reload_time: float = 1.2
@export var equip_time: float = 0.3
@export_group("Dispersion")
@export var pellets: int = 1
@export var spread_degrees: float = 0.0
@export_group("Présentation (graybox)")
@export var view_size: Vector3 = Vector3(0.08, 0.1, 0.4)
@export var view_color: Color = Color(0.25, 0.25, 0.3)
