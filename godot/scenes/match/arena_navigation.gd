extends RefCounted
## Village paths use live solid footprints and the characters' feet.

const CELL := 16.0
const FOOT := Vector2(0, 16)
var grid := AStarGrid2D.new()
var space: PhysicsDirectSpaceState2D
var _query := PhysicsShapeQueryParameters2D.new()
var _arena: Node2D
var _revision := -1


func configure(arena: Node2D) -> void:
	_arena = arena
	_revision = arena.collision_revision
	space = arena.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	_query.shape = shape
	_query.collision_mask = 1
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(arena.world_size() / CELL))
	grid.cell_size = Vector2.ONE * CELL
	grid.offset = Vector2.ONE * CELL / 2.0
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	var perimeter: PackedVector2Array = arena.polygon_points(arena.layout.perimeter)
	for y in range(grid.region.size.y):
		for x in range(grid.region.size.x):
			var cell := Vector2i(x, y)
			var feet := grid.get_point_position(cell)
			grid.set_point_solid(cell, not Geometry2D.is_point_in_polygon(feet, perimeter)
				or not clear_point(feet - FOOT))


func clear_point(pivot: Vector2) -> bool:
	_query.transform = Transform2D(0, pivot + FOOT)
	_query.motion = Vector2.ZERO
	return space.intersect_shape(_query, 1).is_empty()


func clear_segment(from: Vector2, to: Vector2) -> bool:
	_query.transform = Transform2D(0, from + FOOT)
	_query.motion = to - from
	var fractions := space.cast_motion(_query)
	return fractions[0] >= 0.999


func _cell(pivot: Vector2) -> Vector2i:
	var wanted := Vector2i(((pivot + FOOT - grid.offset) / CELL).round())
	var best := Vector2i(-1, -1)
	var distance := INF
	for radius in range(9):
		for y in range(wanted.y - radius, wanted.y + radius + 1):
			for x in range(wanted.x - radius, wanted.x + radius + 1):
				var cell := Vector2i(x, y)
				if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
					continue
				var point: Vector2 = grid.get_point_position(cell) - FOOT
				var candidate := pivot.distance_squared_to(point)
				if candidate < distance and clear_segment(pivot, point):
					distance = candidate
					best = cell
		if best.x >= 0:
			return best
	return best


func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	if _revision != _arena.collision_revision:
		configure(_arena)
	if clear_point(to) and clear_segment(from, to):
		return PackedVector2Array([to])
	var start := _cell(from)
	var end := _cell(to)
	if start.x < 0 or end.x < 0:
		return PackedVector2Array()
	var feet_path := grid.get_point_path(start, end)
	var path := PackedVector2Array()
	for point in feet_path:
		path.append(point - FOOT)
	if clear_point(to) and not path.is_empty() and clear_segment(path[-1], to):
		path.append(to)
	# Follow the furthest visible waypoint, avoiding unnecessary grid turns.
	while path.size() > 1 and clear_segment(from, path[1]):
		path.remove_at(0)
	return path


func escape_goal(from: Vector2, threat: Vector2) -> Vector2:
	var away := (from - threat).normalized()
	if away.is_zero_approx():
		away = Vector2.DOWN
	var best := from
	var score := from.distance_to(threat)
	for angle in range(16):
		var candidate := from + away.rotated(angle * TAU / 16.0) * 180.0
		if not clear_point(candidate):
			continue
		var candidate_score := candidate.distance_to(threat)
		if candidate_score > score and not route(from, candidate).is_empty():
			score = candidate_score
			best = candidate
	return best
