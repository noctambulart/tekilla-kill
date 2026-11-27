extends SceneTree
## Integration check: real scene lifecycle, input dispatch, audio and rendered frames.

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _settle() -> void:
	for i in range(3):
		await process_frame


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw()
	var folder := ProjectSettings.globalize_path("res://../output/intro/2026-11-22/review-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	var frame := root.get_texture().get_image()
	_check(frame.save_png(folder.path_join(name + ".png")) == OK, "Capture " + name)
	if name == "intro-0255":
		var fly_center: Vector2 = root.get_child(0).intro.call("_project", Vector2(0.5, 0.655))
		var screen_position := root.get_final_transform() * fly_center
		var pixel := frame.get_pixelv(Vector2i(screen_position.round()))
		_check(pixel.get_luminance() < 0.2, "La mouche est rendue sur le nez")


func _run() -> void:
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	_check(is_instance_valid(main.intro), "L’intro se lance automatiquement")
	_check(not main.get_node("CenterContainer").visible, "Le titre reste masqué pendant l’intro")
	var intro: Control = main.intro
	for node in intro.get_children():
		if node is AudioStreamPlayer:
			_check(is_equal_approx(node.stream.get_length(), 50.0), "Chaque piste sonore dure 50 secondes")
	for moment in [4.0, 12.0, 20.0, 25.5, 27.0, 35.0, 40.0, 44.0, 48.0]:
		intro.review_at(moment)
		await _settle()
		await _capture("intro-%04d" % int(moment * 10))
	intro.play_from(49.8)
	await create_timer(0.35).timeout
	await _settle()
	_check(not is_instance_valid(main.intro), "La lecture se termine naturellement")
	_check(main.get_node("CenterContainer").visible, "Fin vers le titre")
	await _capture("title")
	# Repeated skip through the actual input dispatcher, at start/middle/end.
	for moment in [0.0, 25.0, 49.0]:
		main.get_node("CenterContainer/Content/ReplayButton").pressed.emit()
		await _settle()
		_check(is_instance_valid(main.intro), "Relecture depuis le bouton")
		main.intro.review_at(moment)
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.pressed = true
		Input.parse_input_event(key)
		await create_timer(0.2).timeout
		await _settle()
		key.pressed = false
		Input.parse_input_event(key)
		_check(not is_instance_valid(main.intro), "Passage clavier à " + str(moment))
		_check(main.get_node("CenterContainer").visible, "Titre après passage clavier")
	main.start_intro()
	await _settle()
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_A
	joy.pressed = true
	Input.parse_input_event(joy)
	await create_timer(0.2).timeout
	await _settle()
	_check(not is_instance_valid(main.intro), "Passage par événement manette simulé")
	_check(main.get_node("CenterContainer/Content/SoloTrialButton").has_focus(), "Focus sur Jouer, aucune activation involontaire")
	var buttons: Array[String] = []
	for child in main.get_node("CenterContainer/Content").get_children():
		if child is Button:
			buttons.append(child.name)
	_check(buttons == ["SoloTrialButton", "ReplayButton", "QuitButton"],
		"Le titre ne conserve que Jouer, Revoir l’introduction et Quitter")
	# Click on the future Play button position to catch accidental scene activation.
	for moment in [0.0, 25.0, 49.0]:
		var play: Button = main.get_node("CenterContainer/Content/SoloTrialButton")
		var click_position := root.get_final_transform() * play.get_global_rect().get_center()
		main.start_intro()
		await _settle()
		main.intro.review_at(moment)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = click_position
		click.pressed = true
		Input.parse_input_event(click)
		await create_timer(0.2).timeout
		click.pressed = false
		Input.parse_input_event(click)
		await _settle()
		_check(not is_instance_valid(main.intro) and main.title_content.visible,
			"Un clic sur l’image passe l’intro à " + str(moment))
		_check(main.is_inside_tree() and main.get_node("CenterContainer/Content/SoloTrialButton").has_focus(),
			"Le clic de passage ne lance pas une partie")
		# Cleanup on an unfixed implementation so all moments can still be checked.
		if is_instance_valid(main.intro):
			main.intro.finish()
			await create_timer(0.2).timeout
			await _settle()
	# Verify the standalone F6 path returns to the title without an intro loop.
	main.queue_free()
	await _settle()
	var standalone: Control = load("res://scenes/intro/intro.tscn").instantiate()
	root.add_child(standalone)
	current_scene = standalone
	await _settle()
	standalone.finish()
	await create_timer(0.2).timeout
	await _settle()
	_check(current_scene.name == "Main", "La scène autonome revient au titre")
	_check(not is_instance_valid(current_scene.intro), "Pas de boucle intro/titre en F6")
	_check(current_scene.get_node("CenterContainer/Content/SoloTrialButton").has_focus(),
		"Le retour au titre place le focus sur Jouer")
	current_scene.get_node("CenterContainer/Content/SoloTrialButton").pressed.emit()
	await _settle()
	_check(current_scene.name == "Match" and current_scene.bot_enabled,
		"Jouer ouvre le round Poncho contre Garcia bot")
	current_scene.return_to_title()
	await _settle()
	_check(current_scene.name == "Main" and not is_instance_valid(current_scene.intro),
		"Retour du round vers le titre sans relancer l’intro")
	print("INTRO CHECK: ", "PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
