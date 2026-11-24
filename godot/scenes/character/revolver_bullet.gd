extends Node2D
## Sweep each travelled segment so a fast bullet cannot skip thin cover or a target.

var _direction := Vector2.RIGHT
var _speed := 0.0
var _distance_left := 0.0
var _damage := 0
var _shooter: CharacterBody2D
var _shooter_rid: RID
var _impact_left := 0.0
var _finished := false


func launch(shooter: CharacterBody2D, direction: Vector2, speed: float,
		distance: float, damage: int) -> void:
	add_to_group("revolver_bullets")
	_shooter = shooter
	_shooter_rid = shooter.get_rid()
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
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, 3,
		[_shooter_rid])
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	_distance_left -= distance
	if not hit.is_empty():
		global_position = hit.position
		_finished = true
		_impact_left = 0.09
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(_damage, _shooter if is_instance_valid(_shooter) else null)
	else:
		global_position = destination
		if _distance_left <= 0.0:
			queue_free()


func _draw() -> void:
	if _finished:
		for angle in range(0, 360, 90):
			var direction := Vector2.RIGHT.rotated(deg_to_rad(angle + 45))
			draw_line(direction * 2, direction * 5, Color("fff0ad"), 1)
	else:
		draw_line(-_direction * 8, Vector2.ZERO, Color("593321"), 3)
		draw_line(-_direction * 7, Vector2.ZERO, Color("ffe8a1"), 1.5)
