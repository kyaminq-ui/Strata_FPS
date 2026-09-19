extends CanvasLayer
## HUD local minimal : viseur, munitions, hitmarker. Créé par Player pour l'autorité seulement.

@onready var _ammo: Label = %Ammo
@onready var _hit_marker: Label = %HitMarker

var _tween: Tween


func bind(weapon: WeaponController) -> void:
	weapon.ammo_changed.connect(_on_ammo_changed)
	weapon.reload_started.connect(func() -> void: _ammo.text = "RELOAD")
	weapon.hit_confirmed.connect(_on_hit_confirmed)
	_on_ammo_changed(weapon.ammo, weapon.data.magazine_size)


func _on_ammo_changed(current: int, magazine: int) -> void:
	_ammo.text = "%d / %d" % [current, magazine]


func _on_hit_confirmed(killed: bool) -> void:
	if _tween:
		_tween.kill()
	_hit_marker.modulate = Color(1.0, 0.2, 0.2, 1.0) if killed else Color(1.0, 1.0, 1.0, 1.0)
	_tween = create_tween()
	_tween.tween_property(_hit_marker, "modulate:a", 0.0, 0.2)
