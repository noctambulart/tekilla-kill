extends SceneTree
## Reproduce the reported empty corner and disagreement between feet and physics.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var map = load("res://scenes/arroyo_seco/arroyo_seco.tscn").instantiate()
	root.add_child(map)
	var actor = load("res://scenes/character/character.tscn").instantiate()
	actor.position = Vector2(900, 800)
	root.add_child(actor)
	await physics_frame
	await physics_frame
	var failures: Array[String] = []
	var feet: Vector2 = actor.get_node("Visual").global_position + Vector2(0, 16)
	var physical: Vector2 = actor.get_node("CollisionShape2D").global_position
	if not feet.is_equal_approx(physical):
		failures.append("Pieds visibles et centre de collision séparés de %s unités" % feet.distance_to(physical))
	var house: Rect2 = map.tile_rect(map.layout.houses[0].rect)
	var empty_corner := house.position + Vector2(8, house.size.y - 2)
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8
	query.shape = circle
	query.collision_mask = 1
	query.transform = Transform2D(0, empty_corner)
	if not map.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
		failures.append("Coin transparent de maison bloquant à %s" % empty_corner)
	var report := {"failures": failures, "foot_offset": feet - physical, "empty_corner": empty_corner}
	var path := ProjectSettings.globalize_path("res://../output/arena/2026-11-25-saloon-study/before/footing.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("FOOTING BASELINE: ", failures)
	quit(0 if failures.is_empty() else 1)
