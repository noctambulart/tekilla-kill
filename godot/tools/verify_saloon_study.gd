extends SceneTree
## Reproduces the reported footprint errors in the playable study, not V5.

const OUTPUT := "res://../output/arena/2026-11-25-saloon-study/character-warm/"
var checks := 0
var failures: Array[String] = []
var query := PhysicsShapeQueryParameters2D.new()
var space: PhysicsDirectSpaceState2D
var folder := ""


func _initialize() -> void:
	folder = ProjectSettings.globalize_path(OUTPUT)
	create_timer(45.0).timeout.connect(func():
		push_error("Saloon verification timed out before completion")
		quit(2))
	_run.call_deferred()


func _frames(count := 1) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _clear(point: Vector2) -> bool:
	query.transform = Transform2D(0, point)
	return space.intersect_shape(query).is_empty()


func _path(points: Array) -> bool:
	for index in range(points.size() - 1):
		var start: Vector2 = points[index]
		var end: Vector2 = points[index + 1]
		var count := maxi(1, ceili(start.distance_to(end) / 4))
		for step in range(count + 1):
			if not _clear(start.lerp(end, float(step) / count)):
				return false
	return true


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	# Force a frame even when macOS occludes the temporary verification window.
	RenderingServer.force_draw()
	_check(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK, "Capture " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1920, 1080)
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	# The approved reference remains accessible as a developer scene.
	current_scene.start_saloon_study()
	await _frames(5)
	var trial = current_scene
	var map = trial.arena
	var actor = trial.explorer
	var target = trial.target
	_check(trial.name == "SaloonStudy" and target.stationary, "Scène étalon et vraie cible Garcia")
	space = map.get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = 8
	query.shape = circle
	query.collision_mask = 1
	for character in [actor, target]:
		var feet: Vector2 = character.get_node("Visual").global_position + Vector2(0, 16)
		_check(character.get_node("CollisionShape2D").global_position.is_equal_approx(feet), "Centre physique sur les pieds de " + character.name)
		_check(character.get_node("Visual")._textures.idle.resource_path.contains("/saloon_warm/"), "Palette chaude active sur " + character.name)
	_check(_clear(Vector2(144, 183)), "Coin transparent de maison réellement libre")
	_check(_clear(Vector2(140, 134)), "Passage sous le débord du toit autorisé")
	_check(not _clear(Vector2(200, 140)), "Façade fermée de maison toujours solide")
	_check(_path([Vector2(140, 212), Vector2(140, 128)]), "Trajet entier longeant la marge gauche de maison")
	_check(_path([Vector2(80, 212), Vector2(380, 212), Vector2(544, 212)]), "Rue entre maison et saloon traversable")
	_check(_path([Vector2(300, 480), Vector2(620, 480)]), "Entrée principale dégagée avec les objets intacts")
	_check(_path([Vector2(320, 540), Vector2(320, 604)]), "Ouverture sud réellement libre")
	_check(_path([Vector2(340, 220), Vector2(340, 320)]), "Ouverture arrière réellement libre")
	_check(_clear(Vector2(250, 325)), "Vide à l’intérieur du L non bloqué par un rectangle global")
	_check(not _clear(Vector2(250, 350)), "Base du comptoir solide")
	_check(not _clear(Vector2(64, 460)), "Mur permanent solide")
	var hat_width := 32.0
	_check(map.manifest.assets.table.world_size[0] / hat_width < 1.4, "Table proportionnée au personnage")
	_check(map.manifest.assets.barrel.world_size[1] < 36, "Tonneau plus bas que Poncho")
	_check(map.manifest.assets.house.world_size[0] / hat_width <= 5.1, "Maison proportionnée au concept")
	for id in map.prop_nodes:
		var art: Sprite2D = map.prop_nodes[id].get_node("Art")
		_check(is_zero_approx(art.rotation) and is_equal_approx(art.scale.x, art.scale.y), "Perspective et proportions conservées : " + id)
	actor.stop_movement()
	actor.position = Vector2(140, 196)
	_key(KEY_W, true)
	await _frames(22)
	_key(KEY_W, false)
	await _frames(9)
	_check(actor.position.y < 154, "Déplacement réel dans la marge auparavant bloquante")
	_check(actor.z_index < map.prop_nodes.house.z_index, "Personnage derrière le toit selon ses pieds")
	trial.reset_trial()
	actor.position = Vector2(540, 464)
	_key(KEY_A, true)
	await _frames(25)
	_key(KEY_A, false)
	await _frames(8)
	_check(actor.position.x < 490, "Traversée au clavier de l’ouverture principale : " + str(actor.position))
	actor.position = Vector2(80, 450)
	_key(KEY_A, true)
	await _frames(15)
	_key(KEY_A, false)
	await _frames(8)
	_check(actor.position.x > 77.5, "Arrêt sur le pied du mur ouest")
	trial.reset_trial()
	var motion := InputEventMouseMotion.new()
	var aim_point: Vector2 = target.global_position
	motion.position = root.get_final_transform() * (trial.camera.get_canvas_transform() * aim_point)
	Input.parse_input_event(motion)
	await _frames(2)
	var shot := InputEventMouseButton.new()
	shot.button_index = MOUSE_BUTTON_LEFT
	shot.position = motion.position
	shot.pressed = true
	Input.parse_input_event(shot)
	await _frames(1)
	shot = shot.duplicate()
	shot.pressed = false
	Input.parse_input_event(shot)
	await _frames(29)
	_check(target.health == 75 and actor.weapon.ammunition == 5, "Vrai tir à travers l’entrée jusqu’à Garcia : PV%d, balles%d, visée%s" % [target.health, actor.weapon.ammunition, actor.aim_direction])
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _frames(26)
	_check(actor.weapon.ammunition == 6, "Rechargement existant conservé")
	trial.reset_trial()
	_key(KEY_D, true)
	await _frames(5)
	_key(KEY_SPACE, true)
	await _frames(1)
	_check(actor.is_dashing(), "Dash réel disponible dans l’étude")
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	await _frames(9)
	_check(actor.dash_readiness() < 1, "Récupération du dash inchangée")
	await _frames(40)
	_check(actor.dash_readiness() == 1, "Dash prêt après récupération")
	trial.reset_trial()
	trial.set_overview(true)
	await _frames(3)
	await _capture("saloon-overview")
	trial.set_process(false)
	trial.camera.position = Vector2(332, 430)
	trial.camera.zoom = Vector2.ONE * 0.90
	await _frames(3)
	await _capture("saloon-in-game")
	trial.camera.position = Vector2(510, 470)
	trial.camera.zoom = Vector2.ONE * 1.6
	await _frames(3)
	await _capture("entrance-fade")
	actor.position = Vector2(140, 164)
	actor.z_index = 180
	trial.camera.position = Vector2(260, 170)
	trial.camera.zoom = Vector2.ONE
	await _frames(3)
	await _capture("house-passage")
	trial.toggle_plan()
	await _frames(2)
	await _capture("footprints")
	trial.toggle_plan()
	# Same real scene, positions and camera: only the artwork changes for this A/B.
	actor.position = Vector2(216, 180)
	actor.z_index = 196
	target.position = Vector2(320, 188)
	target.z_index = 204
	trial.camera.position = Vector2(260, 135)
	trial.camera.zoom = Vector2.ONE * 1.4
	for character in [actor, target]:
		character.get_node("Visual").warm_art = false
	await _frames(3)
	await _capture("house-before")
	for character in [actor, target]:
		character.get_node("Visual").warm_art = true
	await _frames(3)
	await _capture("house-after")
	trial.return_to_title()
	await _frames(3)
	_check(current_scene.name == "Main", "Retour au titre")
	current_scene.start_solo_trial()
	await _frames(4)
	_check(current_scene.arena.layout.version == 6, "Carte complète V6 accessible après généralisation")
	var report := {"checks": checks, "failures": failures, "rendered": DisplayServer.get_name() != "headless",
		"scope": "Zone étalon seulement. Fidélité artistique à examiner sur les captures réelles, pas certifiée par les tests."}
	var file := FileAccess.open(folder.path_join("verification.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("SALOON STUDY: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
