extends SceneTree
## Integration checks use real scenes, input dispatch and physics collisions.

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
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


func _key(physical: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = pressed
	Input.parse_input_event(event)


func _stick(axis: JoyAxis, value: float, device: int = 7) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _point_mouse(target: Vector2) -> void:
	var mouse := InputEventMouseMotion.new()
	# parse_input_event expects window coordinates, including integer scaling/bars.
	mouse.position = root.get_final_transform() * target
	Input.parse_input_event(mouse)


func _verify_dash(j1: CharacterBody2D, j2: CharacterBody2D) -> void:
	j1.position = Vector2(120, 272)
	var start: Vector2 = j1.position
	_key(KEY_SPACE, true)
	await _frames()
	_check(j1.position.is_equal_approx(start) and j1.dash_readiness() == 1.0,
		"Espace à l’arrêt ne déclenche rien")
	_key(KEY_D, true)
	await _frames(12)
	_check(is_equal_approx(j1.velocity.length(), j1.max_speed) and not j1.is_dashing(),
		"L’appui fait à l’arrêt ne se déclenche pas pendant le déplacement")
	_key(KEY_SPACE, false)
	_key(KEY_D, false)
	_key(KEY_W, true)
	await _frames(2)
	var heading := j1.get_real_velocity().normalized()
	var aim: Vector2 = j1.aim_direction
	start = j1.position
	_key(KEY_W, false)
	_key(KEY_A, true)
	_key(KEY_SPACE, true)
	await _frames()
	_check(j1.is_dashing() and j1.velocity.is_equal_approx(heading * j1.dash_speed),
		"Le dash suit l’élan du virage à son déclenchement")
	_key(KEY_A, false)
	_key(KEY_D, true)
	_key(KEY_SPACE, false)
	_point_mouse(Vector2(50, 340))
	await _frames()
	_key(KEY_SPACE, true)
	await _frames(2)
	_check(j1.is_dashing() and j1.velocity.is_equal_approx(heading * j1.dash_speed)
		and j1.aim_direction.is_equal_approx(aim), "Déplacement et visée figés pendant le dash")
	await _frames(4)
	_check(not j1.is_dashing() and j1.dash_readiness() == 0.0
		and j1.position.is_equal_approx(start + heading * j1.dash_speed * j1.dash_duration)
		and j1.velocity.is_equal_approx(heading * j1.max_speed),
		"Distance du dash et reprise avec l’élan dans la même direction")
	await _frames(4)
	_check(not j1.aim_direction.is_equal_approx(aim) and j1.dash_readiness() > 0.0
		and j1.dash_readiness() < 1.0, "Visée à nouveau libre et récupération en cours")
	_key(KEY_SPACE, false)
	await _frames()
	_key(KEY_SPACE, true)
	await _frames()
	_check(not j1.is_dashing(), "Appui ignoré pendant la récupération")
	await _frames(36)
	_check(j1.dash_readiness() == 1.0 and is_equal_approx(j1.velocity.length(), j1.max_speed),
		"Aucun dash différé ou répété quand la jauge redevient pleine")
	_key(KEY_SPACE, false)
	_key(KEY_D, false)
	j1.stop_movement()

	j1.position = Vector2(245, 180)
	_key(KEY_D, true)
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames(3)
	_check(not j1.is_dashing() and j1.velocity.is_zero_approx()
		and j1.position.x > 277.0 and j1.position.x < 279.0 and j1.dash_readiness() < 1.0,
		"Un nouvel appui déclenche un dash qui s’arrête au premier obstacle")
	_key(KEY_SPACE, false)
	await _frames(36)
	_key(KEY_SPACE, true)
	await _frames()
	_check(j1.dash_readiness() == 1.0, "Pousser contre un obstacle à l’arrêt ne consomme pas le dash")
	_key(KEY_SPACE, false)
	_key(KEY_D, false)
	j1.stop_movement()

	j2.position = Vector2(500, 280)
	_stick(JOY_AXIS_LEFT_X, -1.0)
	await _frames(10)
	_stick(JOY_AXIS_TRIGGER_LEFT, 1.0, 8)
	await _frames()
	_check(not j2.is_dashing(), "Une autre manette ne peut pas déclencher le dash")
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.4)
	await _frames()
	_check(not j2.is_dashing(), "Une pression sous le seuil ne déclenche pas le dash")
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.7)
	await _frames()
	_check(j2.is_dashing() and not j1.is_dashing(), "Gâchette gauche lance le dash de J2")
	await _frames(44)
	_check(j2.dash_readiness() == 1.0 and is_equal_approx(j2.velocity.length(), j2.max_speed),
		"Maintenir la gâchette ne relance pas le dash")
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.9)
	await _frames()
	_check(not j2.is_dashing(), "Une variation de pression maintenue ne vaut pas un nouvel appui")
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await _frames()
	_stick(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _frames()
	_check(j2.is_dashing() and j2.velocity.x < 0.0, "Relâcher puis réappuyer permet un nouveau dash")
	root.focus_exited.emit()
	await _frames()
	_check(not j2.is_dashing() and j2.velocity.is_zero_approx(), "Perdre le focus interrompt le dash")
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.0, 8)
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_stick(JOY_AXIS_LEFT_X, 0.0)


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../output/movement/issue-18")
	DirAccess.make_dir_recursive_absolute(folder)
	_check(root.get_texture().get_image().save_png(folder.path_join("movement-test.png")) == OK,
		"Capture de la zone de test")


func _run() -> void:
	# Open the developer scene without exposing a test button in the public title.
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.start_movement_test()
	await _frames(3)
	_check(current_scene.name == "MovementTest", "Accès à la zone de développement")
	var arena = current_scene
	var j1 = arena.keyboard_character
	var j2 = arena.joypad_character
	_check(j1.player_number != j2.player_number and j1.player_color != j2.player_color,
		"Numéros et couleurs distincts")
	_check(j2.position.is_equal_approx(Vector2(480, 144)), "J2 immobile sans commande")
	arena.assign_joypad(7)
	await _capture()

	# A short start and stop leave time to react without sliding far.
	var j1_start: Vector2 = j1.position
	var j2_start: Vector2 = j2.position
	_key(KEY_D, true)
	await _frames()
	_check(j1.velocity.x > 0 and j1.velocity.x < j1.max_speed, "Courte accélération au départ")
	await _frames(11)
	_check(j1.position.x > j1_start.x + 5 and is_equal_approx(j1.velocity.x, j1.max_speed),
		"J1 atteint sa vitesse de croisière en quelques images")
	_check(j2.position.is_equal_approx(j2_start), "Le clavier ne déplace pas J2")
	var release_at: Vector2 = j1.position
	_key(KEY_D, false)
	await _frames()
	_check(j1.velocity.x > 0 and j1.velocity.x < j1.max_speed, "J1 freine progressivement au relâchement")
	await _frames(9)
	var stopped_at: Vector2 = j1.position
	await _frames(3)
	var braking_distance := stopped_at.x - release_at.x
	_check(j1.position.is_equal_approx(stopped_at) and j1.velocity.is_zero_approx()
		and braking_distance > 8.0 and braking_distance < 15.0,
		"J1 s’immobilise rapidement après un léger glissement")
	_key(KEY_D, true)
	_key(KEY_S, true)
	await _frames(9)
	_check(j1.velocity.length() <= j1.max_speed + 0.01, "Diagonale sans gain de vitesse")
	_key(KEY_D, false)
	_key(KEY_S, false)
	await _frames()

	# Mouse aim follows its world target independently of movement.
	var mouse_target := Vector2(160, 280)
	_point_mouse(mouse_target)
	_key(KEY_D, true)
	await _frames(4)
	var toward_mouse: Vector2 = (mouse_target - j1.global_position).normalized()
	_check(j1.aim_direction.dot(toward_mouse) > 0.99, "Visée souris indépendante du déplacement")
	_key(KEY_D, false)
	await _frames(10)

	# Assigned pad, unrelated pad, radial deadzone, analog speed and aim retention.
	j1_start = j1.position
	_stick(JOY_AXIS_LEFT_X, 1.0, 8)
	await _frames(4)
	_check(j1.position.is_equal_approx(j1_start) and j2.position.is_equal_approx(j2_start),
		"Une autre manette ne commande aucun des deux personnages")
	_stick(JOY_AXIS_LEFT_X, 0.0, 8)
	_stick(JOY_AXIS_LEFT_X, 0.1)
	await _frames(4)
	_check(j2.position.is_equal_approx(j2_start), "Zone morte contre la dérive du stick")
	_stick(JOY_AXIS_LEFT_X, 0.5)
	await _frames(7)
	var partial_speed: float = j2.velocity.length()
	_check(partial_speed > 0 and partial_speed < j2.max_speed, "Vitesse dosée à mi-course du stick")
	_stick(JOY_AXIS_LEFT_X, 1.0)
	await _frames(7)
	_check(j2.velocity.length() > partial_speed + 10, "Pleine inclinaison plus rapide")
	_check(j1.position.is_equal_approx(j1_start), "La manette ne déplace pas J1")
	_stick(JOY_AXIS_LEFT_X, 0.0)
	_stick(JOY_AXIS_LEFT_Y, -1.0)
	_stick(JOY_AXIS_RIGHT_Y, 1.0)
	await _frames(3)
	_check(j2.velocity.y < 0 and j2.aim_direction.is_equal_approx(Vector2.DOWN),
		"J2 se déplace et vise dans des directions opposées")
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	await _frames(3)
	_check(j2.aim_direction.is_equal_approx(Vector2.DOWN), "Visée conservée au relâchement du stick droit")
	_stick(JOY_AXIS_RIGHT_X, -0.7)
	_stick(JOY_AXIS_RIGHT_Y, -0.7)
	await _frames(2)
	_check(j2.aim_direction.dot(Vector2(-1, -1).normalized()) > 0.99, "Visée diagonale à 360 degrés")
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	_stick(JOY_AXIS_LEFT_Y, 0.0)
	await _frames()
	_check(j2.velocity.y < 0 and j2.velocity.length() < j2.max_speed, "J2 freine au relâchement du stick gauche")
	await _frames(9)
	stopped_at = j2.position
	await _frames(3)
	_check(j2.position.is_equal_approx(stopped_at), "J2 s’immobilise après le freinage")

	# An abrupt input change should give a curved path through real movement.
	j1.position = Vector2(160, 208)
	_key(KEY_D, true)
	await _frames(12)
	var turn_at: Vector2 = j1.position
	_key(KEY_D, false)
	_key(KEY_W, true)
	await _frames(4)
	var turn_offset: Vector2 = j1.position - turn_at
	_check(turn_offset.x > 8.0 and turn_offset.y < 0.0
		and j1.velocity.x > j1.max_speed * 0.6 and j1.velocity.y < 0.0,
		"En virage à 90°, J1 commence à tourner tout en gardant son élan")
	await _frames(12)
	_check(absf(j1.velocity.x) < 0.01 and j1.velocity.y < -j1.max_speed * 0.95,
		"Après le virage, J1 suit la nouvelle direction")
	_key(KEY_W, false)
	j1.stop_movement()

	# Simultaneous players and reversal through zero.
	j1.position = Vector2(160, 208)
	j2.position = Vector2(480, 144)
	_key(KEY_A, true)
	_stick(JOY_AXIS_LEFT_X, 1.0)
	await _frames(9)
	_check(j1.position.x < 155 and j2.position.x > 485, "Déplacements simultanés isolés")
	_key(KEY_A, false)
	_key(KEY_D, true)
	await _frames()
	_check(j1.velocity.x > -j1.max_speed and j1.velocity.x <= 0.0, "Le demi-tour commence par freiner")
	await _frames(5)
	_check(j1.velocity.x < 0, "Le demi-tour conserve brièvement l’élan précédent")
	await _frames(5)
	_check(j1.velocity.x > 0, "J1 repart dans l’autre sens après le freinage")
	_key(KEY_D, false)
	_stick(JOY_AXIS_LEFT_X, 0.0)
	await _frames(10)

	# Actual physics bodies stop at every wall and slide against an obstacle.
	for example in [
		[Vector2(40, 180), KEY_A, 0, 32.0, -1],
		[Vector2(600, 180), KEY_D, 0, 608.0, 1],
		[Vector2(240, 80), KEY_W, 1, 72.0, -1],
		[Vector2(240, 280), KEY_S, 1, 288.0, 1],
	]:
		j1.position = example[0]
		_key(example[1], true)
		await _frames(20)
		var coordinate: float = j1.position.x if example[2] == 0 else j1.position.y
		_check(absf(coordinate - example[3]) < 0.5, "Limite solide : " + str(example[1]))
		_key(example[1], false)
		await _frames(10)
	j1.position = Vector2(256, 180)
	_key(KEY_D, true)
	await _frames(30)
	_check(j1.position.x > 270 and j1.position.x < 279, "Obstacle infranchissable")
	_key(KEY_D, false)
	await _frames(10)
	j1.position = Vector2(270, 150)
	_key(KEY_D, true)
	_key(KEY_S, true)
	await _frames(16)
	_check(j1.position.x < 279 and j1.position.y > 165, "Glissement le long de l’obstacle")
	_key(KEY_D, false)
	_key(KEY_S, false)
	await _frames(10)

	await _verify_dash(j1, j2)

	# Device removal and leaving/reentering the scene must not retain held actions.
	_stick(JOY_AXIS_LEFT_X, 1.0)
	await _frames(4)
	arena.assign_joypad(-1)
	await _frames()
	stopped_at = j2.position
	await _frames(4)
	_check(j2.position.is_equal_approx(stopped_at), "Manette retirée : déplacement arrêté")
	_key(KEY_A, true)
	await _frames(3)
	root.focus_exited.emit()
	await _frames()
	stopped_at = j1.position
	await _frames(3)
	_check(j1.position.is_equal_approx(stopped_at), "Perte de focus : commandes relâchées")
	_key(KEY_A, false)
	arena.get_node("HUD/Controls/ReturnButton").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "Main" and not is_instance_valid(current_scene.intro),
		"Retour au titre sans relancer l’introduction")
	current_scene.start_movement_test()
	await _frames(4)
	_check(current_scene.keyboard_character.position.is_equal_approx(Vector2(160, 208)),
		"Nouvel essai sans commande résiduelle")
	print("MOVEMENT CHECK: ", "PASS" if failures.is_empty() else failures, " (", checks, " checks)")
	quit(0 if failures.is_empty() else 1)
