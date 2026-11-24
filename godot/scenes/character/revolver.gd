extends Node
## Finite magazine and cadence; the character supplies intentions and permission.

signal fired

const BULLET := preload("res://scenes/character/revolver_bullet.gd")

@export_range(1, 24) var capacity := 6
@export_range(0.01, 2.0, 0.01, "suffix:s") var shot_interval := 0.24
@export_range(0.05, 2.0, 0.01, "suffix:s") var reload_interval := 0.4
@export var damage := 25
@export var bullet_speed := 900.0
@export var bullet_range := 720.0

var ammunition := 0
var _cooldown := 0.0
var _requires_press := true
var _reloading := false
var _reload_time_left := 0.0


func _ready() -> void:
	reset()


func advance(delta: float, held: bool, just_pressed: bool, allowed: bool,
		reload_pressed: bool = false) -> void:
	_cooldown = move_toward(_cooldown, 0.0, delta)
	if not allowed:
		cancel_reload()
		require_new_press()
		return
	if is_reloading():
		# An old hold or a press while empty cannot become a deferred shot.
		if just_pressed and ammunition > 0:
			cancel_reload()
		else:
			_advance_reload(delta)
			return
	# If both actions arrive together, an available shot takes priority.
	if reload_pressed and ammunition < capacity and not (just_pressed and ammunition > 0):
		_reloading = true
		_reload_time_left = reload_interval
		require_new_press()
		return
	if just_pressed:
		_requires_press = false
	if _requires_press or not (held or just_pressed) or _cooldown > 0.0 or ammunition <= 0:
		return
	ammunition -= 1
	_cooldown = shot_interval
	var shooter = get_parent()
	var bullet := BULLET.new()
	# Sibling lifetime: resetting or leaving the arena also removes its projectiles.
	shooter.get_parent().add_child(bullet)
	bullet.launch(shooter, shooter.aim_direction, bullet_speed, bullet_range, damage)
	fired.emit()


func is_reloading() -> bool:
	return _reloading


func reload_progress() -> float:
	return clampf(1.0 - _reload_time_left / reload_interval, 0.0, 1.0) if _reloading else 0.0


func _advance_reload(delta: float) -> void:
	_reload_time_left -= delta
	while _reload_time_left <= 0.0 or is_zero_approx(_reload_time_left):
		ammunition += 1
		if ammunition >= capacity:
			cancel_reload()
			return
		_reload_time_left += reload_interval


func cancel_reload() -> void:
	_reloading = false
	_reload_time_left = 0.0


func require_new_press() -> void:
	_requires_press = true


func reset() -> void:
	cancel_reload()
	ammunition = capacity
	_cooldown = 0.0
	require_new_press()
