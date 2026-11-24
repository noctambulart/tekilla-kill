extends SceneTree
## Verify the actual map, physics, entrances, visit controls and title round trip.

var failures: Array[String] = []
var checks := 0
var output := ""
var capture_completed := false


func _initialize() -> void:
	output = ProjectSettings.globalize_path("res://../output/arena/2026-11-23")
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _frames(count: int = 1) -> void:
	for i in range(count):
		await physics_frame
		await process_frame


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _capture(review: Node2D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output.path_join("visite-v4.png")) == OK,
		"Capture de la visite rapprochée par défaut")
	review.set_overview(true)
	await _frames(2)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output.path_join("vue-ensemble-v4.png")) == OK,
		"Capture de la vue d’ensemble de la carte agrandie")
	review.set_overview(false)
	review.explorer.position = Vector2(13, 15)*32
	await _frames(3)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output.path_join("saloon-v4.png")) == OK,
		"Capture du saloon à échelle native")
	review.set_overview(true)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(review.arena.world_size()) + Vector2i(32,32)
	viewport.disable_3d = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var map = load("res://scenes/arroyo_seco/arroyo_seco.tscn").instantiate()
	map.position = Vector2(16, 16)
	viewport.add_child(map)
	await _frames(3)
	await RenderingServer.frame_post_draw
	_check(viewport.get_texture().get_image().save_png(output.path_join("arroyo-seco-carte-v4.png")) == OK,
		"Export de la carte complète, sans interface ni personnage")
	map.annotations = true
	await _frames(2)
	await RenderingServer.frame_post_draw
	_check(viewport.get_texture().get_image().save_png(output.path_join("plan-annote-v4.png")) == OK,
		"Export du plan annoté depuis la même scène")
	# Render all eight atlas sprites at their actual in-game footprints.
	viewport.size = Vector2i(640,256)
	map.hide()
	var preview := Control.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(preview)
	var kinds := ["crate","barrel","table","couch","chair","pot","cart","counter"]
	var names := ["Caisse","Tonneau","Table de poker","Canapé","Chaise","Pot","Charrette","Comptoir"]
	var sizes := [Vector2(40,40),Vector2(40,40),Vector2(64,64),Vector2(128,48),
		Vector2(32,32),Vector2(24,24),Vector2(128,48),Vector2(128,32)]
	for index in range(kinds.size()):
		var cell := Vector2(index%4,floori(index/4.0))*Vector2(160,128)
		var sprite := TextureRect.new()
		sprite.texture = map.sprite_textures[kinds[index]]
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.size = sizes[index]
		sprite.position = cell+Vector2(80-sprite.size.x/2,52-sprite.size.y/2)
		preview.add_child(sprite)
		var label := Label.new()
		label.text = names[index]
		label.add_theme_font_size_override("font_size",12)
		label.position = cell+Vector2(4,94)
		label.size = Vector2(152,24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview.add_child(label)
	await _frames(2)
	await RenderingServer.frame_post_draw
	_check(viewport.get_texture().get_image().save_png(output.path_join("sprites-jeu-v4.png")) == OK,
		"Aperçu des huit sprites aux dimensions de jeu")
	viewport.queue_free()
	await _frames()
	capture_completed = true


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.get_node("CenterContainer/Content/ArenaButton").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "ArroyoReview", "Accès à la carte depuis le titre")
	var review = current_scene
	var map = review.arena
	var explorer = review.explorer
	_check(not review.overview and review.camera.zoom == Vector2.ONE, "Visite en vue rapprochée par défaut")
	await _capture(review)
	if DisplayServer.get_name() != "headless":
		_check(capture_completed, "Export visuel terminé sans interruption")
	_check(map.layout.version == 4, "Chargement du tracé agrandi V4")
	_check(map.world_size() == Vector2(1536,960), "Carte de 48 × 30 tuiles, surface ×2,25")
	_check(map.sprite_textures.size() == 9, "Huit nouveaux sprites et réemploi du comptoir pour les étagères")
	var counter: AtlasTexture = map.sprite_textures["counter"]
	_check(counter.region.size.x/counter.region.size.y > 2.5,
		"Comptoir détouré sur les pixels visibles, sans marges qui réduisent son épaisseur")
	_check(map.get_child_count() == map.layout.walls.size() + map.layout.props.size(),
		"Un corps solide par mur ou obstacle dessiné")
	_check(map.layout.buildings.size() == 4 and map.layout.spawns.size() == 4,
		"Trois bâtiments, un enclos et quatre départs")

	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8
	query.shape = shape
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState2D = map.get_world_2d().direct_space_state
	var bottle: Vector2 = map.tile_point(map.layout.bottle)
	for index in range(map.layout.spawns.size()):
		var spawn: Vector2 = map.tile_point(map.layout.spawns[index])
		_check(is_equal_approx(spawn.distance_to(bottle), 240.0), "Départ J%d à 240 px de la bouteille" % (index+1))
		var clear := true
		for step in range(21):
			query.transform = Transform2D(0, spawn.lerp(bottle, step / 20.0))
			clear = clear and space.intersect_shape(query, 1).is_empty()
		_check(clear, "Accès libre de J%d au centre avec le rayon réel de 8 px" % (index+1))
	for route in map.layout.routes:
		var clear := true
		for index in range(route.points.size() - 1):
			var a: Vector2 = map.tile_point(route.points[index])
			var b: Vector2 = map.tile_point(route.points[index+1])
			var count := maxi(1, int(ceil(a.distance_to(b)/8.0)))
			for step in range(count+1):
				query.transform = Transform2D(0, a.lerp(b, float(step)/count))
				clear = clear and space.intersect_shape(query, 1).is_empty()
		_check(clear, "Parcours praticable avec objets intacts : " + route.name)

	# The actual physics space blocks lines through walls and leaves doorways clear.
	for sample in [
		[Vector2(14,9),Vector2(16,9),true,"Mur de la façade du saloon"],
		[Vector2(14,12),Vector2(16,12),false,"Grande ouverture du saloon"],
		[Vector2(6,3),Vector2(6,5),false,"Sortie arrière du saloon"],
		[Vector2(26,6),Vector2(26,8),false,"Passage sud de l’enclos"],
	]:
		var ray := PhysicsRayQueryParameters2D.create(sample[0]*48, sample[1]*48, 1)
		_check(not space.intersect_ray(ray).is_empty() == sample[2], sample[3])

	# Movement uses the existing character and real input/physics, not teleported assertions.
	explorer.controls.release()
	explorer.position = Vector2(17,12)*48
	await _frames(2)
	_key(KEY_A, true)
	await _frames(58)
	_key(KEY_A, false)
	await _frames(2)
	_check(explorer.position.x < 22.5*32-8, "Entrée effective dans le saloon depuis la rue")
	explorer.position = Vector2(6,5)*48
	await _frames(2)
	_key(KEY_W, true)
	await _frames(40)
	_key(KEY_W, false)
	await _frames(2)
	_check(explorer.position.y < 6*32-8, "Sortie effective du saloon dans la cour")
	for example in [
		[Vector2(12,6)*48,KEY_W,1,256.0,"Mur nord du saloon"],
		[Vector2(8,8.5)*48,KEY_W,1,378.0,"Comptoir permanent"],
		[Vector2(31,10)*48,KEY_D,0,1520.0,"Limite fermée à l’est"],
	]:
		explorer.position = example[0]
		await _frames(2)
		_key(example[1],true)
		await _frames(35)
		_key(example[1],false)
		await _frames(2)
		var value: float = explorer.position.x if example[2] == 0 else explorer.position.y
		_check(absf(value-example[3])<.5, "Collision réelle : "+example[4])

	review.set_overview(true)
	review.get_node("HUD/Top/View").pressed.emit()
	_check(not review.overview and review.camera.zoom == Vector2.ONE, "Vue rapprochée sélectionnable")
	review.get_node("HUD/Top/Plan").pressed.emit()
	_check(map.annotations, "Plan et parcours affichables")
	_key(KEY_R,true)
	_key(KEY_R,false)
	await _frames(2)
	_check(explorer.position.is_equal_approx(map.tile_point(map.layout.spawns[0])), "Retour au départ de visite")
	_key(KEY_D,true)
	await _frames(5)
	root.focus_exited.emit()
	await _frames(2)
	var stopped_at: Vector2 = explorer.position
	await _frames(3)
	_check(explorer.position.is_equal_approx(stopped_at), "Commandes relâchées à la perte de focus")
	_key(KEY_D,false)
	review.get_node("HUD/Top/Return").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "Main", "Retour au titre sans rejouer l’introduction")
	current_scene.get_node("CenterContainer/Content/ArenaButton").pressed.emit()
	await _frames(3)
	_check(current_scene.explorer.position.is_equal_approx(current_scene.arena.tile_point(current_scene.arena.layout.spawns[0])),
		"Nouvelle visite sans déplacement résiduel")
	var report := {"checks":checks,"failures":failures,"status":"passed" if failures.is_empty() else "failed",
		"scope":"Scènes réelles, collisions physiques, passages, parcours, commandes et menus. Pas de combat ou de validation créative.",
		"rendered":DisplayServer.get_name() != "headless"}
	var file := FileAccess.open(output.path_join("verification-v4.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("ARROYO SECO : %d contrôles, %d échecs" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
