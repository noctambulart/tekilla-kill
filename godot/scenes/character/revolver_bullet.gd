extends Node2D
## Sweep each travelled segment so a fast bullet cannot skip thin cover or a target.

const SHOT_FEEDBACK := preload("res://scenes/character/shot_feedback.gd")
const IMPACT_DURATION := 0.10
const SHOT_MASK := 15 # World, characters, character targets and prop silhouettes.

var _direction := Vector2.RIGHT
var _speed := 0.0
var _distance_left := 0.0
var _damage := 0
var _shooter: CharacterBody2D
var _shooter_rid: RID
var _shooter_areas: Array[RID] = []
var _impact_left := 0.0
var _impact_normal := Vector2.ZERO
var _hit_character := false
var _finished := false


func launch(shooter: CharacterBody2D, direction: Vector2, speed: float,
		distance: float, damage: int) -> void:
	add_to_group("revolver_bullets")
	_shooter = shooter
	_shooter_rid = shooter.get_rid()
	for child in shooter.get_children():
		if child is Area2D:
			_shooter_areas.append(child.get_rid())
	_direction = direction.normalized()
	_speed = speed
	_distance_left = distance
	_damage = damage
	global_position = shooter.global_position
	z_index = 8
	# Check the barrel path too: a muzzle drawn beyond a wall must not shoot through it.
	_travel(minf(20.0, _distance_left))


func _physics_process(delta: float) -> void:
	if _finished:
		_impact_left -= delta
		if _impact_left <= 0.0:
			queue_free()
	else:
		_travel(minf(_speed * delta, _distance_left))
	queue_redraw()


func _travel(distance: float) -> void:
	var destination := global_position + _direction * distance
	var ignored: Array[RID] = [_shooter_rid]
	ignored.append_array(_shooter_areas)
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, SHOT_MASK, ignored)
	query.hit_from_inside = true
	query.collide_with_areas = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	_distance_left -= distance
	if not hit.is_empty():
		global_position = hit.position
		_finished = true
		_impact_left = IMPACT_DURATION
		_impact_normal = -_direction if hit.normal == Vector2.ZERO else hit.normal
		var collider: Node = hit.collider
		if collider is Area2D:
			collider = collider.get_parent()
		_hit_character = collider is CharacterBody2D and collider.has_method("take_damage")
		if collider.has_method("take_damage"):
			collider.take_damage(_damage, _shooter if is_instance_valid(_shooter) else null)
		SHOT_FEEDBACK.play(self, SHOT_FEEDBACK.Cue.TARGET if _hit_character else SHOT_FEEDBACK.Cue.WALL)
	else:
		global_position = destination
		if _distance_left <= 0.0:
			queue_free()


func _draw() -> void:
	if _finished:
		var remaining := clampf(_impact_left / IMPACT_DURATION, 0.0, 1.0)
		var spread := 1.0 - remaining
		if _hit_character:
			var rim := Color(0.61, 0.18, 0.10, remaining)
			var spark := Color(1.0, 0.84, 0.5, remaining)
			draw_circle(Vector2.ZERO, 3.0, spark)
			for i in range(5):
				var direction := _direction.rotated(float(i) * TAU / 5.0)
				var start := direction * (3.0 + 9.0 * spread)
				var end := start + direction * 5.0 * remaining
				draw_line(start, end, rim, 3.0)
				draw_line(start, end, spark, 1.5)
		else:
			var dust := Color(0.44, 0.33, 0.24, remaining)
			var chip := Color(1.0, 0.96, 0.82, remaining)
			for i in range(-2, 3):
				var direction := _impact_normal.rotated(float(i) * 0.42)
				var point := direction * (2.0 + 8.0 * spread + absi(i))
				draw_circle(point, 2.4, dust)
				draw_rect(Rect2(point - Vector2.ONE, Vector2(2, 2)), chip)
	else:
		draw_line(-_direction * 8, Vector2.ZERO, Color("593321"), 3)
		draw_line(-_direction * 7, Vector2.ZERO, Color("ffe8a1"), 1.5)
