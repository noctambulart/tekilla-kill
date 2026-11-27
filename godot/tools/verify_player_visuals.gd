extends SceneTree
## Real locomotion drives the new art; captures use the same Character scene.

var failures: Array[String] = []
var checks := 0
var output := ""
var legacy := false
var warm_art := false


class DirectionBoard extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color("eedcb3"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(14, 26), "PONCHO ET GARCIA · Sprites jouables", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("392a22"))
		draw_string(font, Vector2(14, 50), "Même scène de personnage · corps droit, visée indépendante", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("604c39"))
		for row in range(2):
			draw_string(font, Vector2(14, 90 + row * 132), "PONCHO" if row == 0 else "GARCIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("392a22"))
			for col in range(8):
				draw_rect(Rect2(10 + col * 79, 100 + row * 132, 70, 90), Color("d4b47d"))
				draw_string(font, Vector2(29 + col * 79, 182 + row * 132), str(col * 45) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("392a22"))


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
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


func _stick(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 7
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw()
	_check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK,
		"Capture " + name)


func _run() -> void:
	legacy = OS.get_cmdline_user_args().has("--legacy")
	warm_art = OS.get_cmdline_user_args().has("--warm") and not legacy
	output = ProjectSettings.globalize_path("res://../output/arena/2026-11-25-integration/players")
	if warm_art:
		output = ProjectSettings.globalize_path("res://../output/arena/2026-11-25-saloon-study/character-warm/players")
	if legacy:
		output = output.path_join("legacy")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	change_scene_to_file("res://scenes/movement_test/movement_test.tscn")
	await _frames(5)
	var first = current_scene.get_node("Players/J1")
	var second = current_scene.get_node("Players/J2")
	var visual = first.get_node("Visual")
	visual.refined_art = not legacy
	second.get_node("Visual").refined_art = not legacy
	visual.warm_art = warm_art
	second.get_node("Visual").warm_art = warm_art
	await _frames(2)
	_check(visual._textures.idle.get_height() == (48 if legacy else 144),
		"Densité des dessins source chargée dans les scènes réelles")
	_check(legacy or visual._textures.idle.resource_path.contains("/saloon_warm/" if warm_art else "/village/"),
		"Lot graphique demandé réellement chargé")
	_check(visual.character_style == 0 and second.get_node("Visual").character_style == 1,
		"La scène jouable affecte Poncho à J1 et Garcia à J2")
	_check(first.player_color != second.player_color, "Repères de joueurs distincts des personnages")
	_check(visual.animation_state == "idle", "Repos réel sans commande")
	await _capture("movement-after")
	root.size = Vector2i(1280, 720)
	await _frames(3)
	await _capture("movement-720p")
	root.size = Vector2i(1920, 1080)
	await _frames(3)
	first.position = Vector2(80, 260)
	_key(KEY_D, true)
	await _frames(14)
	_check(visual.animation_state == "walk", "Marche déclenchée par les entrées et la physique")
	var phase: int = visual.animation_frame
	await _frames(10)
	_check(visual.animation_frame != phase, "La marche parcourt les poses")
	_key(KEY_SPACE, true)
	await _frames(2)
	_check(visual.animation_state == "dash" and first.is_dashing(), "Dash lié à l’état réel")
	await _capture("movement-dash")
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	await _frames(25)
	_check(visual.animation_state == "idle" and visual.animation_frame == 0,
		"Retour à la pose neutre après freinage")
	await _capture("dash-recovery")
	await _frames(40)
	_check(first.dash_readiness() == 1.0, "Dash prêt après récupération")
	await _capture("dash-ready")
	current_scene.assign_joypad(7)
	_stick(JOY_AXIS_LEFT_X, 1.0)
	await _frames(14)
	var garcia = second.get_node("Visual")
	_check(garcia.animation_state == "walk", "Garcia marche avec les entrées manette réelles")
	phase = garcia.animation_frame
	await _frames(10)
	_check(garcia.animation_frame != phase, "Garcia parcourt ses propres poses")
	_stick(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _frames(2)
	_check(garcia.animation_state == "dash" and second.is_dashing(), "Garcia joue son dash réel")
	_stick(JOY_AXIS_LEFT_X, 0.0)
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await _frames(25)
	_check(garcia.animation_state == "idle", "Garcia retrouve sa pose de repos")
	# Inspect the exact playable scene in eight directions, independently of inputs.
	current_scene.queue_free()
	await _frames(2)
	var board := DirectionBoard.new()
	root.add_child(board)
	current_scene = board
	var character: PackedScene = load("res://scenes/character/character.tscn")
	for style in range(2):
		for direction in range(8):
			var actor = character.instantiate()
			actor.position = Vector2(45 + direction * 79, 138 + style * 132)
			board.add_child(actor)
			actor.set_physics_process(false)
			actor.aim_direction = Vector2.RIGHT.rotated(direction * PI / 4)
			actor.player_number = style + 1
			actor.player_color = Color("3c879b") if style == 0 else Color("b83d2b")
			var art = actor.get_node("Visual")
			art.refined_art = not legacy
			art.warm_art = warm_art
			art.character_style = style
			art._process(0.0)
			_check(is_equal_approx(art.weapon_angle, actor.aim_direction.angle())
				and art.rotation == 0.0 and actor.rotation == 0.0,
				"Corps droit et visée indépendante : %d / %d" % [style, direction])
	await _capture("directions-in-game")
	board.queue_free()
	await _frames(2)
	change_scene_to_file("res://scenes/arroyo_seco/arena_review.tscn")
	await _frames(5)
	current_scene.explorer.get_node("Visual").refined_art = not legacy
	current_scene.explorer.get_node("Visual").warm_art = warm_art
	await _frames(2)
	_check(current_scene.explorer.get_node("Visual").character_style == 0,
		"Poncho présent dans la visite réelle")
	await _capture("arroyo-seco-native")
	current_scene.set_overview(true)
	await _frames(3)
	await _capture("arroyo-seco-overview")
	var report := {"checks": checks, "failures": failures, "refined_art": not legacy, "warm_art": warm_art,
		"rendered": DisplayServer.get_name() != "headless",
		"scope": "Sprites des scènes réelles, transitions repos/marche/dash, visée indépendante et visite. Pas de validation créative ou matérielle."}
	var file := FileAccess.open(output.path_join("verification.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("PLAYER VISUALS: ", "PASS" if failures.is_empty() else failures, " (", checks, " checks)")
	quit(0 if failures.is_empty() else 1)
