extends Node
## Finite magazine and cadence; the character supplies intentions and permission.

signal fired
signal dry_fired
signal cartridge_inserted
signal melee_struck(target: Node2D)

const BULLET := preload("res://scenes/character/revolver_bullet.gd")

@export_range(1, 24) var capacity := 6
@export_range(0.01, 2.0, 0.01, "suffix:s") var shot_interval := 0.24
@export_range(0.05, 2.0, 0.01, "suffix:s") var reload_interval := 0.4
@export var damage := 25
@export var bullet_speed := 900.0
@export var bullet_range := 720.0
@export var melee_range := 30.0
@export_range(1.0, 180.0) var melee_arc_degrees := 90.0

var ammunition := 0
var _cooldown := 0.0
var _requires_press := true
var _reloading := false
var _reload_time_left := 0.0


func _ready() -> void:
	reset()


func advance(delta: float, held: bool, just_pressed: bool, allowed: bool,
		reload_pressed: bool = false, dashing: bool = false) -> void:
	_cooldown = move_toward(_cooldown, 0.0, delta)
	if not allowed:
		cancel_reload()
		require_new_press()
		return
	if dashing:
		# Keep the current cartridge clock; new commands are discarded during the dash.
		if is_reloading():
			_advance_reload(delta)
		require_new_press()
		return
	var target: Node2D = find_melee_target() if held or just_pressed else null
	var can_attack := ammunition > 0 or is_instance_valid(target)
	if just_pressed and not can_attack:
		dry_fired.emit()
	if is_reloading():
		# An old hold or a press while empty cannot become a deferred shot.
		if just_pressed and can_attack:
			cancel_reload()
		else:
			_advance_reload(delta)
			return
	# If both actions arrive together, an available shot takes priority.
	if reload_pressed and ammunition < capacity and not (just_pressed and can_attack):
		_reloading = true
		_reload_time_left = reload_interval
		require_new_press()
		return
	if just_pressed:
		_requires_press = false
	if _requires_press or not (held or just_pressed) or _cooldown > 0.0 or not can_attack:
		return
	_cooldown = shot_interval
	var shooter = get_parent()
	if is_instance_valid(target):
		if target.has_method("take_damage"):
			target.take_damage(damage, shooter)
		melee_struck.emit(target)
		return
	ammunition -= 1
	var bullet := BULLET.new()
	# Sibling lifetime: resetting or leaving the arena also removes its projectiles.
	shooter.get_parent().add_child(bullet)
	bullet.launch(shooter, shooter.aim_direction, bullet_speed, bullet_range, damage)
	fired.emit()


func find_melee_target(direction := Vector2.ZERO) -> Node2D:
	var actor = get_parent()
	var aim: Vector2 = actor.aim_direction if direction.is_zero_approx() else direction.normalized()
	# Use the actual bullet path: a nearby wall or prop intercepting the muzzle
	# substitutes a strike even when no opponent is present. Ignore side cover.
	var obstacle := _close_shot_obstacle(aim)
	if is_instance_valid(obstacle):
		return obstacle
	var nearest: Node2D
	var distance := melee_range + 0.001
	for other in get_tree().get_nodes_in_group("characters"):
		if other == actor or other.get_world_2d() != actor.get_world_2d() or not other.is_active():
			continue
		var offset: Vector2 = other.global_position - actor.global_position
		if offset.length() > distance or offset.normalized().dot(aim) < cos(deg_to_rad(melee_arc_degrees / 2.0)):
			continue
		var excluded: Array[RID] = [actor.get_rid(), other.get_rid()]
		# Check both the weapon path and the ground path, including thin cover.
		var query := PhysicsRayQueryParameters2D.create(actor.global_position, other.global_position, 11, excluded)
		query.collide_with_areas = true
		query.hit_from_inside = true
		var space: PhysicsDirectSpaceState2D = actor.get_world_2d().direct_space_state
		if not space.intersect_ray(query).is_empty():
			continue
		query.from += actor.get_node("CollisionShape2D").position
		query.to += other.get_node("CollisionShape2D").position
		if not space.intersect_ray(query).is_empty():
			continue
		nearest = other
		distance = offset.length()
	return nearest


func _close_shot_obstacle(aim: Vector2) -> Node2D:
	var actor = get_parent()
	var excluded: Array[RID] = [actor.get_rid()]
	for child in actor.get_children():
		if child is Area2D:
			excluded.append(child.get_rid())
	var query := PhysicsRayQueryParameters2D.create(actor.global_position,
		actor.global_position + aim * melee_range, BULLET.SHOT_MASK, excluded)
	query.collide_with_areas = true
	query.hit_from_inside = true
	var hit: Dictionary = actor.get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Node2D = hit.collider
	if collider is Area2D:
		collider = collider.get_parent()
	# An opponent in front of cover still follows the existing arc/range rules.
	return null if collider is CharacterBody2D else collider


func is_reloading() -> bool:
	return _reloading


func reload_progress() -> float:
	return clampf(1.0 - _reload_time_left / reload_interval, 0.0, 1.0) if _reloading else 0.0


func _advance_reload(delta: float) -> void:
	_reload_time_left -= delta
	while _reload_time_left <= 0.0 or is_zero_approx(_reload_time_left):
		ammunition += 1
		cartridge_inserted.emit()
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
