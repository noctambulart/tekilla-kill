extends CharacterBody2D

signal damaged(amount: int, attacker: Node2D)
signal health_unit_recovered(unit: int)

const SHOT_FEEDBACK := preload("res://scenes/character/shot_feedback.gd")
const HIT_FLASH_DURATION := 0.18
const EMPTY_FLASH_DURATION := 0.28
const GHOST_SHADER := preload("res://scenes/character/ghost.gdshader")

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
@export var stationary := false
@export_range(1, 1000) var max_health := 100
@export var contact_distance := 20.0
@export var contact_speed := 60.0
@export var ghost_enabled := false
@export var ghost_speed := 35.0
@export_range(0.1, 30.0, 0.1, "suffix:s") var ghost_duration := 5.0
@export_range(0.0, 6.0, 0.5) var dash_landing_margin := 2.0

var health := 100
var _hit_flash := 0.0
var _hit_direction := Vector2.ZERO
var _muzzle_flash := 0.0
var _empty_flash := 0.0
var aim_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _dash_time_left := 0.0
var _dash_recovery_left := 0.0
var _ghost := false
var _ghost_health := 0.0
var _stun_time_left := 0.0
var _village_grounded := false
var _shot_target: Area2D
var _dash_over_props: Array[PhysicsBody2D] = []
var _dash_safe_position := Vector2.ZERO
var _melee_flash := 0.0
var _melee_direction := Vector2.RIGHT
var _recovered_units := 0

@onready var controls = $HumanControls
@onready var weapon = $Revolver
@onready var visual: Node2D = $Visual
@onready var reload_audio: AudioStreamPlayer = $ReloadAudio


func _ready() -> void:
	health = max_health
	# A solid core prevents running through another active player; the larger
	# separation radius below makes sustained contact yield gently.
	if combat_enabled:
		collision_mask |= 2
	add_to_group("characters")
	weapon.fired.connect(func(): _muzzle_flash = 0.06)
	weapon.dry_fired.connect(_on_dry_fire)
	weapon.cartridge_inserted.connect(reload_audio.play)
	weapon.melee_struck.connect(func(_target):
		_melee_flash = 0.12
		_melee_direction = aim_direction
		SHOT_FEEDBACK.play(self, SHOT_FEEDBACK.Cue.MELEE))


func use_village_art() -> void:
	# Configure after adding the character: keep the established aiming pivot,
	# move only the movement collider to the visible ground contact.
	_village_grounded = true
	$CollisionShape2D.position = Vector2(0, 16)
	$Visual.warm_art = true
	_shot_target = get_node_or_null("ShotTarget") as Area2D
	if _shot_target == null:
		_shot_target = Area2D.new()
		_shot_target.name = "ShotTarget"
		_shot_target.collision_mask = 0
		_shot_target.monitoring = false
		var hit_shape := CollisionShape2D.new()
		var core := CircleShape2D.new()
		core.radius = 8.0
		hit_shape.shape = core
		_shot_target.add_child(hit_shape)
		add_child(_shot_target)
	_shot_target.collision_layer = 0 if _ghost else 4


func _process(_delta: float) -> void:
	if _village_grounded:
		z_index = roundi(global_position.y + 16)
		if is_dashing() and not _dash_over_props.is_empty():
			z_index += 32


func _physics_process(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash = move_toward(_hit_flash, 0.0, delta)
		_update_hit_pose()
	_muzzle_flash = move_toward(_muzzle_flash, 0.0, delta)
	_empty_flash = move_toward(_empty_flash, 0.0, delta)
	_melee_flash = move_toward(_melee_flash, 0.0, delta)
	if stationary:
		queue_redraw()
		return
	_dash_recovery_left = move_toward(_dash_recovery_left, 0.0, delta)
	if is_ghost():
		_advance_ghost(delta)
		queue_redraw()
		return
	if is_stunned():
		_stun_time_left = move_toward(_stun_time_left, 0.0, delta)
		if is_zero_approx(_stun_time_left):
			_stun_time_left = 0.0
		velocity = Vector2.ZERO
		_update_aim()
		weapon.advance(delta, controls.fire_pressed(), controls.consume_fire_press(),
			combat_enabled and health > 0, controls.consume_reload_press())
		queue_redraw()
		return
	if not is_dashing() and _dash_recovery_left == 0.0 and controls.dash_just_pressed():
		# move_and_slide reports the actual motion, even when velocity still points into a wall.
		var motion := get_real_velocity()
		if not velocity.is_zero_approx() and not motion.is_zero_approx():
			_begin_dash(motion.normalized())
	if is_dashing():
		# This frame remains locked even if it ends the dash.
		weapon.advance(delta, controls.fire_pressed(), controls.consume_fire_press(),
			combat_enabled and health > 0, controls.consume_reload_press(), true)
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
	_hit_flash = HIT_FLASH_DURATION
	_hit_direction = global_position - attacker.global_position if is_instance_valid(attacker) else Vector2.RIGHT
	_hit_direction = _hit_direction.normalized()
	_update_hit_pose()
	damaged.emit(applied, attacker)
	if health == 0:
		weapon.cancel_reload()
		weapon.require_new_press()
		if ghost_enabled:
			_enter_ghost()
	queue_redraw()


func _update_hit_pose() -> void:
	var strength := _hit_flash / HIT_FLASH_DURATION
	visual.position = (_hit_direction * 4.0 * strength).round()
	visual.self_modulate = Color(1.7, 1.4, 1.2).lerp(Color.WHITE, 1.0 - strength)


func _on_dry_fire() -> void:
	_empty_flash = EMPTY_FLASH_DURATION
	SHOT_FEEDBACK.play(self, SHOT_FEEDBACK.Cue.EMPTY)


func is_active() -> bool:
	return combat_enabled and health > 0 and not is_ghost()


func is_ghost() -> bool:
	return _ghost


func is_stunned() -> bool:
	return _stun_time_left > 0.0


func can_pickup_bottle() -> bool:
	return is_active() and not is_stunned()


func stun(duration: float) -> void:
	if not is_active() or duration <= 0.0:
		return
	_stun_time_left = maxf(_stun_time_left, duration)
	if is_dashing():
		_finish_dash(Vector2.ZERO)
	velocity = Vector2.ZERO


func _enter_ghost() -> void:
	stop_movement()
	_stun_time_left = 0.0
	_ghost = true
	_ghost_health = 0.0
	_recovered_units = 0
	collision_layer = 0
	collision_mask = 1
	if is_instance_valid(_shot_target):
		_shot_target.collision_layer = 0
	var ghost_material := ShaderMaterial.new()
	ghost_material.shader = GHOST_SHADER
	$Visual.material = ghost_material
	$Visual.modulate = Color.WHITE


func _advance_ghost(delta: float) -> void:
	controls.consume_fire_press()
	controls.consume_reload_press()
	weapon.advance(delta, false, false, false)
	velocity = controls.movement() * ghost_speed
	move_and_slide()
	_ghost_health = minf(max_health, _ghost_health + max_health * delta / ghost_duration)
	health = floori(_ghost_health)
	var completed := mini(4, floori(_ghost_health * 4.0 / max_health + 0.00001))
	while _recovered_units < completed:
		_recovered_units += 1
		health_unit_recovered.emit(_recovered_units)
		SHOT_FEEDBACK.play(self, SHOT_FEEDBACK.Cue.RECOVERY)
	if is_equal_approx(_ghost_health, max_health):
		_ghost = false
		health = max_health
		collision_layer = 2
		collision_mask = 3
		if is_instance_valid(_shot_target):
			_shot_target.collision_layer = 4
		$Visual.modulate = Color.WHITE
		$Visual.material = null
		controls.release()
		weapon.reset()
		velocity = Vector2.ZERO


func reset_combat() -> void:
	stop_movement()
	_stun_time_left = 0.0
	reload_audio.stop()
	_ghost = false
	_ghost_health = 0.0
	_recovered_units = 0
	collision_layer = 2
	collision_mask = 3 if combat_enabled else 1
	if is_instance_valid(_shot_target):
		_shot_target.collision_layer = 4
	$Visual.modulate = Color.WHITE
	$Visual.material = null
	health = max_health
	_hit_flash = 0.0
	_update_hit_pose()
	_muzzle_flash = 0.0
	_empty_flash = 0.0
	_melee_flash = 0.0
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
	_update_aim()


func _update_aim() -> void:
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
	if _dash_point_clear(global_position):
		_dash_safe_position = global_position
	_dash_time_left = move_toward(_dash_time_left, 0.0, delta)
	_update_hit_pose()
	if not _dash_over_props.is_empty():
		visual.position.y -= sin(PI * (1.0 - _dash_time_left / dash_duration)) * 7.0
	if is_zero_approx(_dash_time_left):
		_finish_dash(_dash_direction * max_speed)


func _finish_dash(exit_velocity: Vector2) -> void:
	if not _dash_over_props.is_empty() and not _dash_point_clear(global_position):
		global_position = _dash_safe_position
	for prop in _dash_over_props:
		if is_instance_valid(prop):
			remove_collision_exception_with(prop)
	_dash_over_props.clear()
	_dash_time_left = 0.0
	_dash_recovery_left = dash_recovery
	velocity = exit_velocity
	_update_hit_pose()


func _dash_query(point: Vector2, margin := 0.0) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = $CollisionShape2D.shape.radius + margin
	query.shape = shape
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.transform = Transform2D(0.0, point + $CollisionShape2D.position)
	return query


func _dash_point_clear(point: Vector2, margin := 0.0) -> bool:
	return get_world_2d().direct_space_state.intersect_shape(_dash_query(point, margin), 1).is_empty()


func _begin_dash(direction: Vector2) -> void:
	_dash_direction = direction
	_dash_time_left = dash_duration
	_dash_safe_position = global_position
	var destination := global_position + direction * dash_speed * dash_duration
	if not _dash_point_clear(destination, dash_landing_margin):
		return
	var query := _dash_query(global_position)
	var candidates: Array[PhysicsBody2D] = []
	var ignored: Array[RID] = query.exclude
	var feet: Vector2 = global_position + $CollisionShape2D.position
	var corridor := Rect2(feet, destination - global_position).abs().grow($CollisionShape2D.shape.radius)
	for prop in get_tree().get_nodes_in_group("dash_over_props"):
		if prop.get_world_2d() == get_world_2d() and not prop.broken:
			var bounds := Rect2()
			for child in prop.get_children():
				if child is CollisionPolygon2D:
					bounds = Rect2(child.to_global(child.polygon[0]), Vector2.ZERO)
					for point in child.polygon:
						bounds = bounds.expand(child.to_global(point))
					break
			if not corridor.intersects(bounds):
				continue
			candidates.append(prop)
			ignored.append(prop.get_rid())
	query.exclude = ignored
	query.motion = destination - global_position
	# Only small props may be skipped; walls, crates and active opponents block.
	if get_world_2d().direct_space_state.cast_motion(query)[0] < 0.999:
		return
	for prop in candidates:
		add_collision_exception_with(prop)
	_dash_over_props = candidates


func stop_movement() -> void:
	controls.release()
	weapon.cancel_reload()
	weapon.require_new_press()
	if is_dashing():
		_finish_dash(Vector2.ZERO)
	velocity = Vector2.ZERO


func _draw() -> void:
	if _muzzle_flash > 0.0:
		draw_circle(aim_direction * 21, 4, Color("ffe8a1"))
	if not stationary:
		var reticle := aim_direction * 36
		draw_line(reticle - Vector2(3, 0), reticle + Vector2(3, 0), player_color)
		draw_line(reticle - Vector2(0, 3), reticle + Vector2(0, 3), player_color)
	draw_string(ThemeDB.fallback_font, Vector2(-13 if stationary else -7, -22),
		"CIBLE" if stationary else "J" + str(player_number),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("30221b"))
	var readiness := dash_readiness()
	if readiness < 1.0:
		draw_rect(Rect2(-12, 16, 24, 1), Color("30221b"))
		if readiness > 0.0:
			draw_rect(Rect2(-12, 16, 24 * readiness, 1), player_color.lightened(0.6))
	if combat_enabled:
		draw_rect(Rect2(-13, 22, 26, 4), Color("30221b"))
		var units := (_ghost_health if is_ghost() else float(health)) * 4.0 / max_health
		for index in range(4):
			var segment := Rect2(-12 + index * 6, 23, 5, 2)
			draw_rect(segment, Color("5e5140"))
			segment.size.x *= clampf(units - index, 0.0, 1.0)
			draw_rect(segment, Color("bdd9a3") if is_ghost() else Color("9fca74"))
		if not stationary:
			var pulse := _empty_flash / EMPTY_FLASH_DURATION
			var empty_color := Color("785b46").lerp(Color("ff664f"), sqrt(pulse))
			var ammo_y := 29.0 + roundf(3.0 * pulse)
			if pulse > 0.0:
				draw_rect(Rect2(-14, ammo_y - 2, weapon.capacity * 4 + 3, 8),
					Color("38231f").lerp(Color("ffac86"), pulse), false, 1.0)
			for i in range(weapon.capacity):
				draw_rect(Rect2(-12 + i * 4, ammo_y, 3, 4),
					Color("ffe8a1") if i < weapon.ammunition else empty_color)
	if _melee_flash > 0.0:
		var angle := _melee_direction.angle()
		var sweep := (1.0 - _melee_flash / 0.12) * 0.7
		draw_arc(Vector2.ZERO, 23.0 + sweep * 4.0, angle - PI / 4 + sweep,
			angle + PI / 4 + sweep, 8, Color(1.0, 0.9, 0.65, _melee_flash / 0.12), 2.0)
