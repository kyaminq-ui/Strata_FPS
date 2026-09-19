extends CanvasLayer
## HUD local minimal : viseur, munitions, hitmarker, PV et état down/réanimation.
## Créé par Player pour l'autorité seulement.

@onready var _ammo: Label = %Ammo
@onready var _hit_marker: Label = %HitMarker
@onready var _health: Label = %Health
@onready var _status: Label = %Status

var _player: Player
var _tween: Tween


func bind(player: Player) -> void:
	_player = player
	var weapon := player.weapon
	weapon.ammo_changed.connect(_on_ammo_changed)
	weapon.reload_started.connect(func() -> void: _ammo.text = "RELOAD")
	weapon.hit_confirmed.connect(_on_hit_confirmed)
	_on_ammo_changed(weapon.ammo, weapon.data.magazine_size)


func _process(_delta: float) -> void:
	if _player == null:
		return
	_health.text = "HP %d" % ceili(_player.health.health)
	var life := _player.life
	if life.downed:
		_status.text = "DOWN  %ds" % ceili(maxf(life.down_time_left, 0.0))
		if life.revive_progress > 0.0:
			_status.text += "  (being revived %d%%)" % roundi(life.revive_progress * 100.0)
	elif _player.reviver.target != null:
		_status.text = "Hold E to revive  %d%%" % roundi(_player.reviver.target.revive_progress * 100.0)
	else:
		_status.text = ""


func _on_ammo_changed(current: int, magazine: int) -> void:
	_ammo.text = "%d / %d" % [current, magazine]


func _on_hit_confirmed(killed: bool) -> void:
	if _tween:
		_tween.kill()
	_hit_marker.modulate = Color(1.0, 0.2, 0.2, 1.0) if killed else Color(1.0, 1.0, 1.0, 1.0)
	_tween = create_tween()
	_tween.tween_property(_hit_marker, "modulate:a", 0.0, 0.2)
