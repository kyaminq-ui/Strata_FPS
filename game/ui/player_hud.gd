extends CanvasLayer
## HUD local minimal : viseur, munitions, hitmarker, PV et état down/réanimation.
## Créé par Player pour l'autorité seulement.

@onready var _ammo: Label = %Ammo
@onready var _hit_marker: Label = %HitMarker
@onready var _health: Label = %Health
@onready var _status: Label = %Status
@onready var _grenades: Label = %Grenades
@onready var _objective: Label = %Objective
@onready var _banner: Label = %Banner
@onready var _end_panel: ColorRect = %EndPanel
@onready var _end_text: Label = %EndText

var _player: Player
var _weapon_name := ""
var _tween: Tween
var _banner_tween: Tween
var _return_left := -1.0  # écran de fin : secondes avant le retour au hub (< 0 : pas annoncé)
var _mission_time := ""


func bind(player: Player) -> void:
	_player = player
	var weapon := player.weapon
	weapon.ammo_changed.connect(_on_ammo_changed)
	weapon.reload_started.connect(func() -> void: _ammo.text = "%s  RELOAD" % _weapon_name)
	weapon.weapon_changed.connect(func(w: WeaponData) -> void: _weapon_name = w.display_name)
	_weapon_name = weapon.data.display_name
	weapon.hit_confirmed.connect(_on_hit_confirmed)
	player.melee.hit_confirmed.connect(_on_hit_confirmed)
	player.grenades.count_changed.connect(_on_grenades_changed)
	_on_grenades_changed(player.grenades.count)
	_on_ammo_changed(weapon.ammo, weapon.data.magazine_size)
	GameSession.objectives_changed.connect(_refresh_objective)
	GameSession.objective_completed.connect(func(text: String) -> void: _show_banner("OBJECTIF ATTEINT : " + text))
	GameSession.announcement.connect(_show_banner)
	GameSession.mission_completed.connect(_on_mission_completed)
	GameSession.return_announced.connect(func(seconds: float) -> void: _return_left = seconds)
	_refresh_objective()


func _on_mission_completed() -> void:
	var seconds := int(GameSession.mission_seconds())
	_mission_time = "%d:%02d" % [seconds / 60, seconds % 60]
	_end_panel.show()


func _process(delta: float) -> void:
	if _player == null:
		return
	if _end_panel.visible:
		_return_left = maxf(_return_left - delta, 0.0) if _return_left >= 0.0 else _return_left
		var back := "" if _return_left < 0.0 else "Retour au hub dans %d s" % ceili(_return_left)
		_end_text.text = "MISSION ACCOMPLIE\n\nTemps : %s\n\n%s" % [_mission_time, back]
	_health.text = "HP %d" % ceili(_player.health.health)
	var life := _player.life
	if life.downed:
		_status.text = "DOWN  %ds" % ceili(maxf(life.down_time_left, 0.0))
		if life.revive_progress > 0.0:
			_status.text += "  (being revived %d%%)" % roundi(life.revive_progress * 100.0)
	elif _player.reviver.target != null:
		_status.text = "Hold F to revive  %d%%" % roundi(_player.reviver.target.revive_progress * 100.0)
	else:
		_status.text = ""


func _refresh_objective() -> void:
	var text := GameSession.current_objective_text()
	_objective.text = ("Objectif : " + text) if text != "" else ("Mission terminée" if GameSession.mission_done else "")


func _show_banner(text: String) -> void:
	_banner.text = text
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(3.0)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 1.0)


func _on_grenades_changed(count: int) -> void:
	_grenades.text = "[G] grenades: %d" % count


func _on_ammo_changed(current: int, magazine: int) -> void:
	_ammo.text = "%s  %d / %d" % [_weapon_name, current, magazine]


func _on_hit_confirmed(killed: bool) -> void:
	if _tween:
		_tween.kill()
	_hit_marker.modulate = Color(1.0, 0.2, 0.2, 1.0) if killed else Color(1.0, 1.0, 1.0, 1.0)
	_tween = create_tween()
	_tween.tween_property(_hit_marker, "modulate:a", 0.0, 0.2)
