extends CharacterBody2D

signal damaged(amount: int, attacker: Node2D)

@export var player_number := 1
@export var player_color := Color("3c879b")
@export var max_speed := 210.0
@export var acceleration := 1400.0
@export var braking := 1600.0
@export var turning_acceleration := 1300.0
@export var dash_speed := 560.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var dash_duration := 0.12
@export_range(0.0, 5.0, 0.01, "suffix:s") var dash_recovery := 0.55
@export var combat_enabled := false
@export_range(1, 1000) var max_health := 100
@export var contact_distance := 20.0
@export var contact_speed := 60.0
@export var ghost_enabled := false
@export var ghost_speed := 35.0
@export_range(0.1, 30.0, 0.1, "suffix:s") var ghost_duration := 5.0

var health := 100
var _hit_flash := 0.0
var _muzzle_flash := 0.0
var aim_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _dash_time_left := 0.0
var _dash_recovery_left := 0.0
var _ghost := false
var _ghost_health := 0.0

@onready var controls = $HumanControls
@onready var weapon = $Revolver


func _ready() -> void:
	health = max_health
	# A solid core prevents running through another active player; the larger
	# separation radius below makes sustained contact yield gently.
	if combat_enabled:
		collision_mask |= 2
	add_to_group("characters")
	weapon.fired.connect(func(): _muzzle_flash = 0.06)


func _physics_process(delta: float) -> void:
	_hit_flash = move_toward(_hit_flash, 0.0, delta)
	_muzzle_flash = move_toward(_muzzle_flash, 0.0, delta)
	_dash_recovery_left = move_toward(_dash_recovery_left, 0.0, delta)
	if is_ghost():
		_advance_ghost(delta)
		queue_redraw()
		return
	if not is_dashing() and _dash_recovery_left == 0.0 and controls.dash_just_pressed():
		# move_and_slide reports the actual motion, even when velocity still points into a wall.
		var motion := get_real_velocity()
		if not velocity.is_zero_approx() and not motion.is_zero_approx():
			_dash_direction = motion.normalized()
			_dash_time_left = dash_duration
	if is_dashing():
		# This frame remains locked even if it ends the dash.
		weapon.advance(delta, controls.fire_pressed(), controls.consume_fire_press(), false,
			controls.consume_reload_press())
		_advance_dash(delta)
	else:
		_move_and_aim(delta)
		if combat_enabled and health > 0:
			_separate_contacts(delta)
		weapon.advance(delta, controls.fire_pressed(), controls.consume_fire_press(),
			combat_enabled and health > 0, controls.consume_reload_press())
	queue_redraw()


func _separate_contacts(delta: float) -> void:
	for other in get_tree().get_nodes_in_group("characters"):
		if other == self or not other.is_active():
			continue
		var offset: Vector2 = global_position - other.global_position
		var distance := offset.length()
		if distance >= contact_distance:
			continue
		var direction := offset / distance if distance > 0.001 else (
			Vector2.LEFT if get_instance_id() < other.get_instance_id() else Vector2.RIGHT)
		# Keep world collisions solid while allowing a small, gradual separation.
		move_and_collide(direction * minf((contact_distance - distance) * 0.5, contact_speed * delta))


func take_damage(amount: int, attacker: Node2D) -> void:
	if not is_active() or amount <= 0:
		return
	var applied := mini(amount, health)
	health -= applied
	_hit_flash = 0.16
	damaged.emit(applied, attacker)
	if health == 0:
		weapon.cancel_reload()
		weapon.require_new_press()
		if ghost_enabled:
			_enter_ghost()
	queue_redraw()


func is_active() -> bool:
	return combat_enabled and health > 0 and not is_ghost()


func is_ghost() -> bool:
	return _ghost


func _enter_ghost() -> void:
	stop_movement()
	_ghost = true
	_ghost_health = 0.0
	collision_layer = 0
	collision_mask = 1
	$Visual.modulate = Color(0.65, 0.75, 0.85, 0.4)


func _advance_ghost(delta: float) -> void:
	controls.consume_fire_press()
	controls.consume_reload_press()
	weapon.advance(delta, false, false, false)
	velocity = controls.movement() * ghost_speed
	move_and_slide()
	_ghost_health = minf(max_health, _ghost_health + max_health * delta / ghost_duration)
	health = floori(_ghost_health)
	if is_equal_approx(_ghost_health, max_health):
		_ghost = false
		health = max_health
		collision_layer = 2
		collision_mask = 3
		$Visual.modulate = Color.WHITE
		controls.release()
		weapon.reset()
		velocity = Vector2.ZERO


func reset_combat() -> void:
	stop_movement()
	_ghost = false
	_ghost_health = 0.0
	collision_layer = 2
	collision_mask = 3 if combat_enabled else 1
	$Visual.modulate = Color.WHITE
	health = max_health
	_hit_flash = 0.0
	_muzzle_flash = 0.0
	_dash_recovery_left = 0.0
	weapon.reset()
	queue_redraw()


func _move_and_aim(delta: float) -> void:
	var target_velocity: Vector2 = controls.movement() * max_speed
	var rate := acceleration
	# Approach the requested vector from the current one so turns carry momentum.
	if velocity.dot(target_velocity) < 0.999 * velocity.length() * target_velocity.length():
		rate = turning_acceleration
	elif target_velocity.length_squared() < velocity.length_squared():
		rate = braking
	velocity = velocity.move_toward(target_velocity, rate * delta)
	move_and_slide()
	var aiming: Vector2 = controls.aim(global_position)
	if not aiming.is_zero_approx():
		aim_direction = aiming


func is_dashing() -> bool:
	return _dash_time_left > 0.0


func dash_readiness() -> float:
	if is_dashing():
		return 0.0
	if _dash_recovery_left > 0.0:
		return 1.0 - _dash_recovery_left / dash_recovery
	return 1.0


func _advance_dash(delta: float) -> void:
	velocity = _dash_direction * dash_speed
	var motion := velocity * minf(delta, _dash_time_left)
	# A solid contact ends the dash instead of redirecting it along the surface.
	if move_and_collide(motion):
		_finish_dash(Vector2.ZERO)
		return
	_dash_time_left = move_toward(_dash_time_left, 0.0, delta)
	if is_zero_approx(_dash_time_left):
		_finish_dash(_dash_direction * max_speed)


func _finish_dash(exit_velocity: Vector2) -> void:
	_dash_time_left = 0.0
	_dash_recovery_left = dash_recovery
	velocity = exit_velocity


func stop_movement() -> void:
	controls.release()
	weapon.cancel_reload()
	weapon.require_new_press()
	if is_dashing():
		_finish_dash(Vector2.ZERO)
	velocity = Vector2.ZERO


func _draw() -> void:
	if _hit_flash > 0.0:
		draw_circle(Vector2.ZERO, 9, Color(1, 0.93, 0.75, _hit_flash / 0.16))
	if _muzzle_flash > 0.0:
		draw_circle(aim_direction * 21, 4, Color("ffe8a1"))
	var reticle := aim_direction * 36
	draw_line(reticle - Vector2(3, 0), reticle + Vector2(3, 0), player_color)
	draw_line(reticle - Vector2(0, 3), reticle + Vector2(0, 3), player_color)
	draw_string(ThemeDB.fallback_font, Vector2(-7, -22), "J" + str(player_number),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("30221b"))
	var readiness := dash_readiness()
	if readiness < 1.0:
		draw_rect(Rect2(-12, 16, 24, 1), Color("30221b"))
		if readiness > 0.0:
			draw_rect(Rect2(-12, 16, 24 * readiness, 1), player_color.lightened(0.6))
	if combat_enabled:
		draw_rect(Rect2(-13, 22, 26, 4), Color("30221b"))
		draw_rect(Rect2(-12, 23, 24.0 * health / max_health, 2), Color("9fca74"))
		for i in range(weapon.capacity):
			draw_rect(Rect2(-12 + i * 4, 29, 3, 4),
				Color("ffe8a1") if i < weapon.ammunition else Color("785b46"))
