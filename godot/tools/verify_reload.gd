extends "res://tools/verify_shooting.gd"
## Reuse the combat trial/input helpers; run the reload scenarios independently.


func _button(pressed: bool, device := 7) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_X
	event.pressed = pressed
	Input.parse_input_event(event)


func _reload() -> void:
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _frames()


func _prepare(first := Vector2(100, 272), second := Vector2(480, 144)) -> void:
	_key(KEY_R, false)
	_button(false)
	_button(false, 8)
	await super._prepare(first, second)


func _spend_rounds(count: int, hold := false) -> void:
	var before: int = j1.weapon.ammunition
	_mouse(true, Vector2(100, 80))
	var spacing := ceili(j1.weapon.shot_interval * Engine.physics_ticks_per_second)
	await _frames(1 + (count - 1) * spacing)
	if not hold:
		_mouse(false, Vector2(100, 80))
	_check(j1.weapon.ammunition == before - count, "Préparation : tirs réels consommant %d balle(s)" % count)


func _verify_progressive_reload() -> void:
	await _prepare()
	await _reload()
	_check(not j1.weapon.is_reloading() and j1.weapon.ammunition == 6,
		"Chargeur plein : l’appui ne démarre rien")
	await _spend_rounds(2)
	await _reload()
	_check(j1.weapon.is_reloading() and j1.weapon.ammunition == 4,
		"Appui bref sur R : départ depuis un chargeur partiel sans ajout immédiat")
	await _frames(12)
	_check(j1.weapon.ammunition == 4 and j1.weapon.reload_progress() > 0.4
		and j1.weapon.reload_progress() < 0.7, "La première balle prend du temps")
	_check(arena.get_node("HUD/Controls/Subtitle").text.contains("recharge"),
		"Le HUD indique le rechargement réel")
	# Keyboard repeat must not restart the current cartridge.
	var repeated := InputEventKey.new()
	repeated.physical_keycode = KEY_R
	repeated.pressed = true
	repeated.echo = true
	Input.parse_input_event(repeated)
	await _frames(12)
	_check(j1.weapon.ammunition == 5 and j1.weapon.is_reloading(),
		"Une balle ajoutée après 400 ms, sans redémarrage par l’écho clavier")
	await _frames(24)
	_check(j1.weapon.ammunition == 6 and not j1.weapon.is_reloading(),
		"Remplissage automatique jusqu’au plein depuis un chargeur partiel")
	await _frames(30)
	_check(j1.weapon.ammunition == 6, "La capacité n’est jamais dépassée")


func _verify_empty_and_held_fire() -> void:
	await _prepare()
	await _spend_rounds(6, true)
	await _frames(20)
	_check(j1.weapon.ammunition == 0 and not j1.weapon.is_reloading(),
		"À vide, aucune recharge automatique")
	await _reload()
	var ammunition := 0
	var loaded_frames: Array[int] = []
	for i in range(150):
		await _frames()
		if j1.weapon.ammunition != ammunition:
			_check(j1.weapon.ammunition == ammunition + 1, "Les balles arrivent une par une")
			ammunition = j1.weapon.ammunition
			loaded_frames.append(Engine.get_physics_frames())
		if not j1.weapon.is_reloading():
			break
	_check(ammunition == 6 and loaded_frames.size() == 6,
		"Un appui remplit aussi un chargeur vide")
	var regular := true
	for i in range(1, loaded_frames.size()):
		regular = regular and loaded_frames[i] - loaded_frames[i - 1] == 24
	_check(regular, "400 ms séparent chaque ajout de balle")
	await _frames(20)
	_check(j1.weapon.ammunition == 6, "L’ancien maintien du tir ne coupe pas la recharge ni ne tire à sa fin")
	_mouse(false)
	await _frames()
	_mouse(true)
	await _frames()
	_check(j1.weapon.ammunition == 5, "Nouvel appui après recharge : le tir reprend")


func _verify_interruptions_and_mobility() -> void:
	await _prepare()
	await _spend_rounds(4)
	await _reload()
	var start: Vector2 = j1.position
	_key(KEY_D, true)
	_point_mouse(Vector2(100, 80))
	await _frames(24)
	_check(j1.position.x > start.x + 50 and j1.aim_direction.y < -0.9
		and j1.weapon.ammunition == 3 and j1.weapon.is_reloading(),
		"Déplacement et visée libres pendant la recharge")
	_key(KEY_D, false)
	_mouse(true, Vector2(100, 80))
	await _frames()
	_mouse(false)
	_check(not j1.weapon.is_reloading() and j1.weapon.ammunition == 2,
		"Un nouvel appui tire et interrompt en conservant les balles ajoutées")
	await _frames(30)
	_check(j1.weapon.ammunition == 2, "La recharge interrompue ne reprend pas seule")
	await _prepare()
	await _spend_rounds(6)
	await _reload()
	await _frames(5)
	_mouse(true)
	await _frames()
	_check(j1.weapon.ammunition == 0 and j1.weapon.is_reloading(),
		"Tirer avant la première balle ne coupe pas la recharge à vide")
	await _frames(24)
	_check(j1.weapon.ammunition == 1 and j1.weapon.is_reloading(),
		"Un appui commencé à vide ne devient pas un tir différé")
	_mouse(false)
	await _frames()
	_mouse(true)
	await _frames()
	_check(j1.weapon.ammunition == 0 and not j1.weapon.is_reloading(),
		"Nouvel appui avec la première balle disponible : interruption et tir")
	await _prepare()
	await _spend_rounds(1)
	await _reload()
	_mouse(true)
	await _frames()
	_mouse(false)
	_check(j1.weapon.ammunition == 5 and not j1.weapon.is_reloading(),
		"L’interruption par un tir respecte encore la cadence de l’arme")


func _verify_reload_and_dash() -> void:
	await _prepare()
	await _spend_rounds(4)
	await _reload()
	await _frames(24)
	var loaded: int = j1.weapon.ammunition
	_key(KEY_D, true)
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames()
	_check(j1.is_dashing() and not j1.weapon.is_reloading()
		and j1.weapon.ammunition == loaded, "Début du dash : annulation sans perdre les balles ajoutées")
	_key(KEY_R, true)
	_mouse(true)
	await _frames(30)
	_check(not j1.is_dashing() and not j1.weapon.is_reloading()
		and j1.weapon.ammunition == loaded, "Appuis maintenus pendant le dash : aucune reprise différée")
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_mouse(false)
	_key(KEY_R, false)
	await _frames()
	await _reload()
	_check(j1.weapon.is_reloading(), "Nouvel appui de recharge après le dash : autorisé")
	_mouse(true)
	await _frames()
	_mouse(false)
	_check(j1.weapon.ammunition == loaded - 1 and not j1.weapon.is_reloading(),
		"Nouvel appui de tir après le dash : autorisé et interrompt la recharge")
	# A tap during the dash must also be forgotten, even if released before its end.
	await _prepare()
	await _spend_rounds(2)
	_key(KEY_D, true)
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames()
	await _reload()
	await _frames(30)
	_check(j1.weapon.ammunition == 4 and not j1.weapon.is_reloading(),
		"Appui bref de recharge pendant le dash : aucune mise en attente")


func _verify_joypad_and_lifecycle() -> void:
	await _prepare()
	_stick(JOY_AXIS_RIGHT_Y, -1.0)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames()
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_button(true, 8)
	await _frames()
	_check(j2.weapon.ammunition == 5 and not j2.weapon.is_reloading(),
		"Le bouton d’une autre manette ne recharge pas J2")
	_button(true)
	await _frames()
	_check(j2.weapon.is_reloading() and not j1.weapon.is_reloading(),
		"X / carré recharge seulement le joueur affecté")
	_stick(JOY_AXIS_LEFT_X, -0.5)
	var start: Vector2 = j2.position
	await _frames(24)
	_check(j2.weapon.ammunition == 6 and not j2.weapon.is_reloading()
		and j2.position.x < start.x, "Recharge manette pendant le déplacement")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames()
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _frames(30)
	_check(j2.weapon.ammunition == 5 and not j2.weapon.is_reloading(),
		"X / carré maintenu ne relance pas une recharge après un tir")
	_button(false)
	await _frames()
	_button(true)
	await _frames()
	arena.assign_joypad(-1)
	await _frames(30)
	_check(j2.weapon.ammunition == 5 and not j2.weapon.is_reloading(),
		"Retrait de manette : recharge interrompue sans balle ajoutée")
	arena.assign_joypad(7)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	await _prepare()
	await _spend_rounds(2)
	await _reload()
	await _frames(24)
	root.focus_exited.emit()
	await _frames(30)
	_check(j1.weapon.ammunition == 5 and not j1.weapon.is_reloading(),
		"Perte de focus : annulation conservant les balles terminées")
	await _reload()
	await _frames(12)
	var progress: float = j1.weapon.reload_progress()
	paused = true
	await _frames(30)
	_check(j1.weapon.ammunition == 5 and is_equal_approx(j1.weapon.reload_progress(), progress),
		"La pause de la scène suspend le délai de la balle en cours")
	paused = false
	j1.take_damage(j1.health, j2)
	await _frames(30)
	_check(not j1.weapon.is_reloading() and j1.weapon.ammunition == 5,
		"Zéro PV : la recharge cesse immédiatement")
	await _reload()
	_check(not j1.weapon.is_reloading(), "Zéro PV : aucun rechargement autorisé")
	arena.reset_trial()
	await _frames()
	_check(j1.weapon.ammunition == 6 and not j1.weapon.is_reloading(),
		"Réinitialiser l’essai remet le chargeur à plein sans recharge résiduelle")


func _capture_reload() -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _prepare(Vector2(140, 210), Vector2(460, 160))
	await _spend_rounds(3)
	await _reload()
	await _frames(36)
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../output/combat/issue-21")
	DirAccess.make_dir_recursive_absolute(folder)
	_check(root.get_texture().get_image().save_png(folder.path_join("reload-test.png")) == OK,
		"Capture du rechargement : cartouches entières, ajoutées une par une")


func _run() -> void:
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.get_node("CenterContainer/Content/MovementButton").pressed.emit()
	await _frames(3)
	arena = current_scene
	j1 = arena.keyboard_character
	j2 = arena.joypad_character
	arena.assign_joypad(7)
	await _verify_progressive_reload()
	await _verify_empty_and_held_fire()
	await _verify_interruptions_and_mobility()
	await _verify_reload_and_dash()
	await _verify_joypad_and_lifecycle()
	await _capture_reload()
	await _prepare()
	await _spend_rounds(1)
	await _reload()
	arena.return_to_title()
	await _frames(3)
	_check(current_scene.name == "Main", "Retour au titre pendant la recharge")
	current_scene.start_movement_test()
	await _frames(3)
	_check(current_scene.keyboard_character.weapon.ammunition == 6
		and not current_scene.keyboard_character.weapon.is_reloading(),
		"Nouvel essai : aucun état de recharge conservé")
	var folder := ProjectSettings.globalize_path("res://../output/combat/issue-21")
	DirAccess.make_dir_recursive_absolute(folder)
	var report := FileAccess.open(folder.path_join("verification.json"), FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify({
			"status": "passed" if failures.is_empty() else "failed",
			"checks": checks,
			"failures": failures,
			"engine": Engine.get_version_info().string,
			"rendered": DisplayServer.get_name() != "headless",
			"scope": "Rechargement dans les scènes réelles, entrées clavier/souris/manette simulées. Sensations et matériel physique à essayer."
		}, "\t") + "\n")
	print("RELOAD CHECK: ", "PASS" if failures.is_empty() else failures, " (", checks, " checks)")
	quit(0 if failures.is_empty() else 1)
