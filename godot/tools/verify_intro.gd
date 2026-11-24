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
	await RenderingServer.frame_post_draw
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
	_check(main.get_node("CenterContainer/Content/ReplayButton").has_focus(), "Focus sur relecture, aucune activation involontaire")
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
	print("INTRO CHECK: ", "PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
