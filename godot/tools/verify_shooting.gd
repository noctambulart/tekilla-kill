extends SceneTree
## Exercise actual inputs, scene UI and swept projectile collisions.

var failures: Array[String] = []
var checks := 0
var arena
var j1
var j2
var shot_frames: Array[int] = []


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


func _point_mouse(target: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = root.get_final_transform() * target
	Input.parse_input_event(event)


func _mouse(pressed: bool, target := Vector2(300, 272)) -> void:
	_point_mouse(target)
	var event := InputEventMouseButton.new()
	event.position = root.get_final_transform() * target
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _stick(axis: JoyAxis, value: float, device := 7) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _prepare(first := Vector2(100, 272), second := Vector2(300, 272)) -> void:
	_mouse(false)
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0, 8)
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_stick(JOY_AXIS_LEFT_X, 0.0)
	arena.reset_trial()
	j1.position = first
	j2.position = second
	_point_mouse(second)
	shot_frames.clear()
	await _frames(3)


func _verify_inputs_and_magazine() -> void:
	await _prepare()
	var damage_events: Array = []
	j2.damaged.connect(func(amount, attacker): damage_events.append([amount, attacker]))
	# Even a press and release between two physics ticks must give one shot.
	_mouse(true)
	_mouse(false)
	await _frames()
	_check(j1.weapon.ammunition == 5 and j2.weapon.ammunition == 6,
		"Appui bref : une balle J1, sans consommer celle de J2")
	_check(j2.health == 100, "Le projectile a un temps de vol")
	await _frames(20)
	_check(j2.health == 75 and j1.health == 100, "Impact unique de 25 PV, tireur exclu")
	_check(damage_events.size() == 1 and damage_events[0] == [25, j1],
		"Dégâts signalés une seule fois avec l’attaquant")
	_check(get_nodes_in_group("revolver_bullets").is_empty(), "Projectile retiré après impact")
	_check(arena.get_node("HUD/Controls/Subtitle").text.contains("75 PV"),
		"Le HUD lit les dégâts réels")
	_mouse(true)
	await _frames(2)
	_mouse(false)
	_mouse(true)
	await _frames(2)
	_check(j1.weapon.ammunition == 4, "Cliquer vite ne contourne pas la cadence")
	await _frames(80)
	_check(j1.weapon.ammunition == 0 and shot_frames.size() == 6,
		"Le maintien épuise exactement le chargeur")
	var cadence_ok := true
	for i in range(1, shot_frames.size()):
		cadence_ok = cadence_ok and float(shot_frames[i] - shot_frames[i - 1]) / 60.0 >= j1.weapon.shot_interval
	_check(cadence_ok, "La cadence minimale est respectée entre tous les tirs")
	_check(j2.health == 0, "Les dégâts sont bornés à zéro PV")
	await _frames(50)
	_mouse(false)
	_mouse(true)
	await _frames(20)
	_check(j1.weapon.ammunition == 0 and shot_frames.size() == 6,
		"Vide : ni tir supplémentaire ni rechargement automatique")
	_check(arena.get_node("HUD/Controls/Subtitle").text.contains("VIDE"), "Chargeur vide visible")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames(20)
	_check(j2.weapon.ammunition == 6, "À zéro PV, le tir est bloqué en attendant la mission fantôme")


func _verify_joypad() -> void:
	await _prepare()
	_stick(JOY_AXIS_RIGHT_X, -1.0)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0, 8)
	await _frames(3)
	_check(j1.weapon.ammunition == 6 and j2.weapon.ammunition == 6,
		"Une manette non affectée ne tire pas")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.4)
	await _frames(3)
	_check(j2.weapon.ammunition == 6, "Gâchette sous le seuil : aucun tir")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.7)
	await _frames()
	_check(j2.weapon.ammunition == 5 and j1.weapon.ammunition == 6,
		"Gâchette droite : seul J2 tire")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.9)
	await _frames(2)
	_check(j2.weapon.ammunition == 5, "Variation de pression : pas de second tir anticipé")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	await _frames(18)
	_check(j1.health == 75 and j2.health == 100, "J2 touche J1 avec la visée conservée")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames(17)
	_check(j2.weapon.ammunition == 3, "Maintien de RT : répétition selon la cadence")
	arena.assign_joypad(-1)
	var remaining: int = j2.weapon.ammunition
	await _frames(20)
	_check(j2.weapon.ammunition == remaining, "Déconnexion : le tir maintenu est relâché")
	arena.assign_joypad(7)
	await _frames(20)
	_check(j2.weapon.ammunition == remaining, "Réaffectation : aucune reprise automatique")


func _verify_cover() -> void:
	await _prepare(Vector2(240, 180), Vector2(400, 180))
	_mouse(true, j2.position)
	_mouse(false, j2.position)
	await _frames(24)
	_check(j1.weapon.ammunition == 5 and j2.health == 100, "L’obstacle central arrête le tir")
	_check(get_nodes_in_group("revolver_bullets").is_empty(), "Impact sur décor : projectile retiré")
	await _prepare(Vector2(277, 180), Vector2(400, 180))
	_mouse(true, j2.position)
	_mouse(false, j2.position)
	await _frames(24)
	_check(j2.health == 100, "Canon au-delà d’un mur : aucun tir à travers le couvert")
	# One-pixel cover crossed within a single 15-pixel physics step.
	await _prepare()
	var cover := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1, 50)
	shape.shape = rectangle
	cover.add_child(shape)
	cover.position = Vector2(153, 272)
	arena.add_child(cover)
	await _frames(2)
	_mouse(true)
	_mouse(false)
	await _frames(24)
	_check(j2.health == 100, "Balayage continu : un obstacle de 1 px bloque la balle rapide")
	cover.queue_free()
	await _prepare(Vector2(100, 272), Vector2(200, 272))
	var third = load("res://scenes/character/character.tscn").instantiate()
	third.combat_enabled = true
	third.get_node("HumanControls").source = 1
	third.position = Vector2(300, 272)
	arena.get_node("Players").add_child(third)
	await _frames(2)
	_mouse(true)
	_mouse(false)
	await _frames(24)
	_check(j2.health == 75 and third.health == 100, "Seule la première cible reçoit les dégâts")
	third.queue_free()
	await _prepare(Vector2(100, 272), Vector2(300, 200))
	j1.weapon.bullet_range = 45.0
	_mouse(true, Vector2(600, 272))
	_mouse(false, Vector2(600, 272))
	await _frames(10)
	_check(get_nodes_in_group("revolver_bullets").is_empty(), "Portée épuisée : projectile retiré")
	j1.weapon.bullet_range = 720.0


func _verify_dash() -> void:
	await _prepare()
	_key(KEY_D, true)
	_mouse(true)
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames()
	_check(j1.is_dashing(), "Dash déclenché pendant un tir maintenu")
	var remaining: int = j1.weapon.ammunition
	await _frames(30)
	_check(not j1.is_dashing() and j1.weapon.ammunition == remaining,
		"Aucun tir pendant le dash ou à sa fin au maintien")
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_mouse(false)
	await _frames()
	_mouse(true)
	await _frames()
	_check(j1.weapon.ammunition == remaining - 1, "Nouvel appui après le dash : tir autorisé")
	await _prepare()
	_key(KEY_D, true)
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames()
	_mouse(true)
	_mouse(false)
	await _frames(25)
	_check(j1.weapon.ammunition == 6, "Appui bref pendant le dash : aucun tir mémorisé")
	await _prepare()
	_key(KEY_D, true)
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames()
	_mouse(true)
	await _frames(25)
	_check(j1.weapon.ammunition == 6, "Appui maintenu commencé pendant le dash : aucun tir différé")
	# Incoming bullets still damage a dashing character.
	await _prepare(Vector2(100, 272), Vector2(190, 272))
	_key(KEY_D, true)
	await _frames(8)
	_key(KEY_SPACE, true)
	_stick(JOY_AXIS_RIGHT_X, -1.0)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames(3)
	_check(j1.is_dashing() and j1.health == 75, "Le dash reste vulnérable aux balles")


func _verify_contacts_and_reset() -> void:
	await _prepare(Vector2(120, 272), Vector2(145, 272))
	j2.position = Vector2(138, 272)
	await _frames()
	var separation: float = j1.position.distance_to(j2.position)
	_check(separation > 18.0 and separation < 20.0, "Contact : le repoussement est progressif")
	await _frames(16)
	_check(j1.position.distance_to(j2.position) >= 19.9, "Contact souple : séparation terminée")
	_check(j1.health == 100 and j2.health == 100, "Aucun dégât de contact")
	await _prepare(Vector2(33, 272), Vector2(34, 272))
	await _frames(24)
	_check(j1.position.x >= 31.9 and j2.position.x >= 31.9, "Le repoussement respecte les murs")
	await _prepare(Vector2(120, 272), Vector2(120, 272))
	await _frames(18)
	_check(j1.position.distance_to(j2.position) >= 19.9, "Une superposition exacte est résolue")
	await _prepare(Vector2(100, 272), Vector2(160, 272))
	_key(KEY_D, true)
	await _frames(30)
	_check(j1.position.x < j2.position.x and j1.position.distance_to(j2.position) >= 15.9,
		"En course, les personnages se repoussent sans se traverser")
	_check(j1.health == 100 and j2.health == 100, "Pousser un autre joueur ne cause aucun dégât")
	await _prepare()
	_mouse(true)
	await _frames(2)
	root.focus_exited.emit()
	var remaining: int = j1.weapon.ammunition
	await _frames(30)
	_check(j1.weapon.ammunition == remaining, "Perte de focus : arrêt du tir maintenu")
	_mouse(false)
	await _frames()
	# The reset button uses a real GUI click, which must not fire a shot.
	shot_frames.clear()
	_mouse(true, Vector2(470, 14))
	await _frames(2)
	_check(shot_frames.is_empty(), "Appui sur un bouton d’interface : aucun tir")
	_mouse(false, Vector2(470, 14))
	await _frames(3)
	_check(j1.weapon.ammunition == 6 and j2.weapon.ammunition == 6
		and j1.health == 100 and j2.health == 100, "Réinitialisation : vie et chargeurs pleins")
	_check(j1.position == Vector2(160, 208) and j2.position == Vector2(480, 144)
		and get_nodes_in_group("revolver_bullets").is_empty(), "Réinitialisation : départs et projectiles nettoyés")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _prepare(Vector2(140, 210), Vector2(250, 210))
	_mouse(true, j2.position)
	_mouse(false, j2.position)
	await _frames(10)
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../output/combat/issue-20")
	DirAccess.make_dir_recursive_absolute(folder)
	_check(root.get_texture().get_image().save_png(folder.path_join("shooting-test.png")) == OK,
		"Capture du tir dans la scène réelle")


func _run() -> void:
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.start_movement_test()
	await _frames(3)
	arena = current_scene
	j1 = arena.keyboard_character
	j2 = arena.joypad_character
	arena.assign_joypad(7)
	j1.weapon.fired.connect(func(): shot_frames.append(Engine.get_physics_frames()))
	_check(j1.combat_enabled and j2.combat_enabled, "La scène de développement ouvre l’essai de combat")
	await _verify_inputs_and_magazine()
	await _verify_joypad()
	await _verify_cover()
	await _verify_dash()
	await _verify_contacts_and_reset()
	await _capture()
	arena.get_node("HUD/Controls/ReturnButton").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "Main" and get_nodes_in_group("revolver_bullets").is_empty(),
		"Retour au titre : projectiles nettoyés")
	current_scene.start_movement_test()
	await _frames(3)
	_check(current_scene.keyboard_character.weapon.ammunition == 6, "Nouvel essai : chargeur plein")
	var folder := ProjectSettings.globalize_path("res://../output/combat/issue-20")
	DirAccess.make_dir_recursive_absolute(folder)
	var report := FileAccess.open(folder.path_join("verification.json"), FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify({
			"status": "passed" if failures.is_empty() else "failed",
			"checks": checks,
			"failures": failures,
			"engine": Engine.get_version_info().string,
			"rendered": DisplayServer.get_name() != "headless",
			"scope": "Tir et dégâts dans les scènes réelles, entrées simulées. Validation des sensations et manette physique à faire."
		}, "\t") + "\n")
	print("SHOOTING CHECK: ", "PASS" if failures.is_empty() else failures, " (", checks, " checks)")
	quit(0 if failures.is_empty() else 1)
