extends SceneTree
## Real physics and inputs verify the new village; screenshots use shipped scenes.

var failures: Array[String] = []
var checks := 0
var output := ""
var space: PhysicsDirectSpaceState2D
var query := PhysicsShapeQueryParameters2D.new()
var last_block := ""


func _initialize() -> void:
	output = ProjectSettings.globalize_path("res://../output/arena/2026-11-25-integration")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func _frames(count: int = 1) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _clear(point: Vector2) -> bool:
	query.transform = Transform2D(0, point)
	var hits := space.intersect_shape(query, 1)
	if not hits.is_empty():
		last_block = "%s at %s" % [hits[0].collider.name, point / 32.0]
	return hits.is_empty()


func _line_clear(a: Vector2, b: Vector2) -> bool:
	var count := maxi(1, ceili(a.distance_to(b) / 8.0))
	for index in range(count + 1):
		if not _clear(a.lerp(b, float(index) / count)):
			return false
	return true


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "Capture " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.get_node("CenterContainer/Content/ArenaButton").pressed.emit()
	await _frames(4)
	var review = current_scene
	var map = review.arena
	var actor = review.explorer
	space = map.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 8
	query.shape = shape
	query.collision_mask = 1
	_check(map.layout.version == 5 and map.world_size() == Vector2(2048, 1280), "Village V5 de64×40 tuiles")
	_check(map.layout.buildings.size() == 4 and map.layout.houses.size() == 4, "Quatre lieux accessibles et quatre maisons fermées")
	_check(map.get_child_count() == map.layout.walls.size() + map.layout.props.size(), "Même source de géométrie pour visuels et corps solides")
	_check(map.sprite_textures.size() == 21, "Nouveau lot complet de sprites et alias d’étagère")
	_check(actor.get_node("Visual").village_art, "Nouveaux sprites actifs dans le personnage partagé")
	var bottle: Vector2 = map.tile_point(map.layout.bottle)
	_check(_clear(bottle), "Bouteille sur une surface libre")
	var equal_distance := true
	for index in range(map.layout.spawns.size()):
		var spawn: Vector2 = map.tile_point(map.layout.spawns[index])
		equal_distance = equal_distance and is_equal_approx(spawn.distance_to(bottle), 304.0)
		_check(_clear(spawn) and _line_clear(spawn, bottle), "Départ J%d libre et relié au centre" % (index + 1))
	_check(equal_distance, "Quatre emplacements de départ à égale distance de la bouteille")
	for route in map.layout.routes:
		var clear := true
		for index in range(route.points.size() - 1):
			clear = clear and _line_clear(map.tile_point(route.points[index]), map.tile_point(route.points[index + 1]))
		_check(clear, "Parcours physique avec objets intacts : " + route.name + (" / " + last_block if not clear else ""))
	for building in map.layout.buildings:
		var openings := 0
		for edge_key in building.doors:
			var edge := int(edge_key)
			var a: Vector2 = map.tile_point(building.polygon[edge])
			var b: Vector2 = map.tile_point(building.polygon[(edge + 1) % building.polygon.size()])
			var direction := (b - a).normalized()
			var normal := Vector2(-direction.y, direction.x)
			for span in building.doors[edge_key]:
				openings += 1
				var middle := (float(span[0]) + float(span[1])) * 16.0
				var center := Vector2(middle, a.y) if is_equal_approx(a.y, b.y) else Vector2(a.x, middle)
				var traversable := true
				for offset in [-16.0, 0.0, 16.0]:
					traversable = traversable and _line_clear(center + direction * offset - normal * 32,
						center + direction * offset + normal * 32)
				_check(traversable, "Seuil large, sans collision cachée : %s / bord%s" % [building.id, edge_key] + (" / " + last_block if not traversable else ""))
		_check(openings >= 2, "Au moins deux accès séparés : " + building.id)
	for sample in [
		[Vector2(3, 18), Vector2(5, 18), "Mur ouest du saloon"],
		[Vector2(10, 13.5), Vector2(10, 16.5), "Comptoir permanent"],
		[Vector2(6, 4), Vector2(12, 4), "Maison fermée"],
		[Vector2(62.5, 20), Vector2(64.5, 20), "Limite est visible"],
	]:
		var ray := PhysicsRayQueryParameters2D.create(sample[0] * 32, sample[1] * 32, 1)
		_check(not space.intersect_ray(ray).is_empty(), "Obstacle physique : " + sample[2])
	actor.stop_movement()
	actor.position = Vector2(26, 21) * 32
	await _frames(2)
	_key(KEY_A, true)
	await _frames(55)
	_key(KEY_A, false)
	await _frames(10)
	_check(actor.position.x < 24 * 32 - 8, "Entrée effective au clavier dans le saloon")
	actor.stop_movement()
	actor.position = Vector2(21.5, 35.5) * 32
	await _frames(2)
	_key(KEY_A, true)
	await _frames(40)
	_key(KEY_A, false)
	await _frames(10)
	_check(actor.position.x < 20 * 32 - 8, "Traversée effective de la sortie latérale de la remise")
	actor.stop_movement()
	actor.position = Vector2(5, 18) * 32
	await _frames(2)
	_key(KEY_A, true)
	await _frames(30)
	_key(KEY_A, false)
	await _frames(10)
	_check(absf(actor.position.x - 144.0) < 1.0, "Arrêt effectif contre le mur, rayon du personnage conservé")
	actor.stop_movement()
	actor.position = bottle
	_key(KEY_D, true)
	await _frames(5)
	_key(KEY_SPACE, true)
	await _frames(1)
	_check(actor.is_dashing(), "Dash disponible dans la carte")
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _frames(2)
	_check(actor.position.is_equal_approx(map.tile_point(map.layout.spawns[0])) and not actor.is_dashing(), "Retour au départ et interruption du dash")
	_key(KEY_D, true)
	await _frames(5)
	root.focus_exited.emit()
	await _frames(2)
	var stopped: Vector2 = actor.position
	await _frames(3)
	_check(actor.position.is_equal_approx(stopped), "Commandes relâchées à la perte de focus")
	_key(KEY_D, false)
	review.set_overview(true)
	review.get_node("HUD/Top/View").pressed.emit()
	_check(not review.overview and review.camera.zoom == Vector2.ONE, "Vue rapprochée sélectionnable")
	review.get_node("HUD/Top/Plan").pressed.emit()
	_check(map.annotations, "Plan et parcours disponibles")
	review.get_node("HUD/Top/Plan").pressed.emit()
	actor.stop_movement()
	actor.position = Vector2(13, 23) * 32
	await _frames(3)
	await _capture("saloon-in-game")
	review.set_overview(true)
	await _frames(3)
	await _capture("village-overview")
	if DisplayServer.get_name() != "headless":
		var viewport := SubViewport.new()
		viewport.size = Vector2i(map.world_size()) + Vector2i(32, 32)
		viewport.disable_3d = true
		viewport.world_2d = World2D.new()
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var clean_map = load("res://scenes/arroyo_seco/arroyo_seco.tscn").instantiate()
		clean_map.position = Vector2(16, 16)
		viewport.add_child(clean_map)
		await _frames(4)
		await RenderingServer.frame_post_draw
		_check(viewport.get_texture().get_image().save_png(output.path_join("village-map-native.png")) == OK, "Carte complète rendue par Godot")
		viewport.queue_free()
	review.get_node("HUD/Top/Return").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "Main", "Retour au titre")
	current_scene.get_node("CenterContainer/Content/SoloTrialButton").pressed.emit()
	await _frames(4)
	_check(current_scene.arena.layout.version == 5 and current_scene.target.stationary, "Nouvelle carte intégrée à l’essai solo existant")
	await _capture("solo-trial-in-game")
	current_scene.reset_trial()
	_check(current_scene.explorer.position.is_equal_approx(current_scene.arena.tile_point(current_scene.arena.layout.spawns[3])), "Réinitialisation au nouveau départ du saloon")
	var report := {"checks": checks, "failures": failures, "rendered": DisplayServer.get_name() != "headless",
		"scope": "Carte réelle, passages avec rayon8, boucles, collisions, déplacements, dash, focus, menus et sprites. Ni combat à quatre ni casse validés."}
	var file := FileAccess.open(output.path_join("verification-village.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("VILLAGE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
