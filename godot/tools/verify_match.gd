extends SceneTree
## Real arena, inputs and physics; shorten only the final drinking fixtures.

const OUTPUT_DIR := "res://../output/gameplay/2026-11-26-issue-23"
var output_dir := OUTPUT_DIR

var failures: Array[String] = []
var results: Array[Dictionary] = []
var checks := 0
var game
var bottle
var j1
var j2


func _initialize() -> void:
	set_meta("match_test_two_humans", true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence="):
			output_dir = argument.trim_prefix("--evidence=")
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	results.append({"passed": condition, "description": message})
	if not condition:
		failures.append(message)
		push_error(message)


func _frames(count := 1) -> void:
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


func _joy_button(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 7
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _mouse(pressed: bool, target: Vector2) -> void:
	var point := root.get_final_transform() * (root.get_canvas_transform() * target)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	var click := InputEventMouseButton.new()
	click.position = point
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	Input.parse_input_event(click)


func _bind_game() -> void:
	game = current_scene
	bottle = game.bottle
	j1 = game.players[0]
	j2 = game.players[1]
	game.assign_joypad(7)


func _fresh() -> void:
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_key(KEY_R, false)
	_mouse(false, Vector2.ZERO)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_stick(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_stick(JOY_AXIS_LEFT_X, 0.0)
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	_joy_button(JOY_BUTTON_X, false)
	game.replay()
	await _frames(3)
	_bind_game()
	game.countdown_left = 0.01
	await _frames(3)


func _hold_with_j1() -> void:
	j1.stop_movement()
	j2.stop_movement()
	j1.position = bottle.position
	j2.position = bottle.position + Vector2(100, 0)
	await _frames(3)
	_check(bottle.holder == j1, "Passer sur la bouteille la ramasse automatiquement")


func _wall(position: Vector2) -> void:
	var wall := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1, 80)
	collider.shape = shape
	wall.add_child(collider)
	wall.position = position
	game.world.add_child(wall)


func _verify_possession_and_drops() -> void:
	await _hold_with_j1()
	var before: int = bottle.remaining
	_key(KEY_D, true)
	_mouse(true, j1.position + Vector2(0, -80))
	await _frames(4)
	_mouse(false, j1.position + Vector2(0, -80))
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _frames(2)
	_check(j1.weapon.is_reloading() and bottle.holder == j1 and bottle.remaining < before,
		"Le porteur boit pendant le déplacement, le tir et le rechargement")
	_key(KEY_SPACE, true)
	await _frames()
	_check(j1.is_dashing() and bottle.holder == j1 and bottle.remaining < before - 4,
		"Le porteur conserve la bouteille et boit pendant le dash")
	_key(KEY_SPACE, false)
	_key(KEY_D, false)
	_check(bottle.scores[1] > 0 and bottle.scores[2] == 0
		and bottle.remaining + bottle.scores[1] + bottle.scores[2] == bottle.total_amount,
		"Score égal à la quantité bue, réserve conservée exactement")
	await _fresh()
	await _hold_with_j1()
	var origin: Vector2 = bottle.position
	_stick(JOY_AXIS_RIGHT_X, -1.0)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames()
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _frames(7)
	_check(j1.health == 75 and bottle.holder == null and bottle.position.x > origin.x,
		"Un vrai projectile non létal fait tomber la bouteille vers le tireur")
	var score: int = bottle.scores[1]
	await _frames(18)
	_check(bottle.holder == j2 and bottle.scores[1] == score,
		"Le tireur récupère la bouteille, l’ancien porteur cesse de marquer")
	await _frames(10)
	_check(bottle.scores[2] > 0, "La consommation reprend pour le nouveau porteur")
	await _fresh()
	await _hold_with_j1()
	bottle.throw_distance = 0.0
	j1.take_damage(25, j2)
	await _frames(10)
	_check(bottle.holder == null, "L’ancien porteur ne reprend pas immédiatement la bouteille")
	j2.position = bottle.position
	j1.position += Vector2(-30, 0)
	await _frames()
	_check(bottle.holder == j2, "Un autre joueur peut la prendre pendant le délai de l’ancien porteur")
	await _fresh()
	await _hold_with_j1()
	bottle.throw_distance = 0.0
	j1.take_damage(25, j2)
	await _frames(ceili(bottle.holder_stun_duration * 60.0) + 1)
	_check(bottle.holder == j1, "L’ancien porteur redevient autorisé après le court délai")
	await _fresh()
	await _hold_with_j1()
	origin = j1.position
	_wall(origin + Vector2(25, 0))
	await _frames(2)
	j1.take_damage(25, j2)
	await _frames(20)
	_check(bottle.position.x <= origin.x + 20.1 and bottle.velocity.is_zero_approx(),
		"Une projection s’arrête contre un couvert fin sans le traverser")


func _verify_arbitration() -> void:
	await _fresh()
	# Freeze motion to arrange simultaneous pickup candidates exactly.
	for player in game.players:
		player.set_physics_process(false)
	bottle.set_physics_process(false)
	var origin: Vector2 = bottle.position
	j1.position = origin + Vector2(-12, 0)
	j2.position = origin + Vector2(8, 0)
	bottle._try_pickup()
	_check(bottle.holder == j2, "Ramassage simultané : priorité au plus proche")
	bottle._random.seed = 37
	var selected: Dictionary = {}
	for i in range(40):
		bottle.holder = null
		bottle.position = origin
		j1.position = origin + Vector2(-10, 0)
		j2.position = origin + Vector2(10, 0)
		bottle._try_pickup()
		selected[bottle.holder.player_number] = true
	_check(selected.size() == 2, "À égalité exacte, le hasard peut désigner chacun des joueurs")


func _verify_second_carrier_actions() -> void:
	await _fresh()
	j2.position = bottle.position
	j1.position = bottle.position + Vector2(-100, 0)
	await _frames(3)
	_check(bottle.holder == j2, "Garcia ramasse automatiquement la même bouteille")
	var origin: Vector2 = j2.position
	var before: int = bottle.remaining
	_stick(JOY_AXIS_LEFT_X, 1.0)
	_stick(JOY_AXIS_RIGHT_Y, -1.0)
	await _frames(4)
	_check(j2.position.x > origin.x and j2.aim_direction.dot(Vector2.UP) > 0.99
		and bottle.remaining < before and bottle.holder == j2,
		"Garcia boit en se déplaçant et en visant indépendamment à la manette")
	before = bottle.remaining
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames(2)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check(j2.weapon.ammunition == 5 and bottle.remaining < before,
		"Le tir de Garcia laisse la consommation se poursuivre")
	_joy_button(JOY_BUTTON_X, true)
	_joy_button(JOY_BUTTON_X, false)
	await _frames(2)
	_check(j2.weapon.is_reloading(), "Garcia peut recharger en portant la bouteille")
	before = bottle.remaining
	_stick(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _frames()
	_check(j2.is_dashing() and j2.weapon.is_reloading() and bottle.holder == j2
		and bottle.remaining < before,
		"Garcia boit pendant le dash avec sa recharge déjà engagée")
	await _capture("garcia-carried")
	await _fresh()


func _verify_bottle_contract() -> void:
	await _fresh()
	# Real bottle and characters; control delta to exercise fractional rates and overshoot.
	for player in game.players:
		player.set_physics_process(false)
	bottle.set_physics_process(false)
	var origin: Vector2 = game.arena.tile_point(game.arena.layout.bottle)
	var states: Array[Dictionary] = []
	var end_states: Array[Dictionary] = []
	bottle.state_changed.connect(func(state: Dictionary): states.append(state))
	bottle.emptied.connect(func(): end_states.append(bottle.get_state()))
	bottle.total_amount = 11
	bottle.drinking_rate = 7.5
	bottle.configure(game.players, origin)
	_check(bottle.global_position == origin and bottle.holder == null
		and bottle.remaining == 11 and bottle.scores == {1: 0, 2: 0}
		and states.size() == 1 and not states[0].empty,
		"État initial publié : centre, réserve pleine, scores nuls, sans porteur")
	j1.position = origin + Vector2(-100, 0)
	j2.position = origin + Vector2(100, 0)
	bottle._physics_process(2.0)
	_check(bottle.remaining == 11 and bottle.scores == {1: 0, 2: 0} and states.size() == 1,
		"Aucune consommation ni événement de score au sol")
	j1.position = origin
	bottle._physics_process(0.1)
	_check(states.size() == 2 and states[-1].holder == j1 and states[-1].remaining == 11,
		"La prise publie le porteur sans consommer deux fois")
	j2.position = origin
	bottle._try_pickup()
	_check(bottle.holder == j1 and states.size() == 2,
		"Un second ramassage ne remplace pas un porteur existant")
	bottle._physics_process(0.15)
	bottle._physics_process(0.25)
	_check(bottle.scores == {1: 3, 2: 0} and bottle.remaining == 8,
		"Débit fractionnaire : trois unités après 0,4 seconde, sans perte d’arrondi")
	bottle.throw_distance = 0.0
	j1.take_damage(25, j2)
	_check(states[-1].holder == null and states[-1].scores == {1: 3, 2: 0},
		"La perte publie immédiatement l’absence de porteur et conserve le score")
	j1.position = origin + Vector2(-100, 0)
	j2.position = origin + Vector2(100, 0)
	bottle._physics_process(1.0)
	_check(bottle.remaining == 8 and bottle.scores == {1: 3, 2: 0},
		"La consommation cesse pendant toute la perte de possession")
	j2.position = bottle.position
	bottle._physics_process(0.1)
	bottle._physics_process(0.4)
	_check(bottle.scores == {1: 3, 2: 3} and bottle.remaining == 5,
		"Même temps de possession, même quantité bue pour Poncho et Garcia")
	var snapshot: Dictionary = bottle.get_state()
	snapshot.scores[1] = 999
	_check(bottle.scores[1] == 3 and states[0].scores == {1: 0, 2: 0},
		"Les instantanés de présentation ne modifient pas les scores ni les états passés")
	bottle._physics_process(10.0)
	_check(bottle.remaining == 0 and bottle.scores == {1: 3, 2: 8}
		and end_states.size() == 1 and end_states[0].empty
		and states[-1] == end_states[0],
		"Dernière gorgée plafonnée : état final publié avant l’unique signal de fin")
	var event_count := states.size()
	bottle._physics_process(10.0)
	bottle._drink(10.0)
	bottle.holder = null
	j1.position = bottle.position
	bottle._try_pickup()
	_check(bottle.holder == null and bottle.remaining == 0 and end_states.size() == 1
		and states.size() == event_count and bottle.scores == {1: 3, 2: 8},
		"Bouteille vide : ni nouveau porteur, ni consommation, ni seconde fin")
	var conserved := true
	for state in states:
		conserved = conserved and state.remaining >= 0 \
			and state.remaining + state.scores[1] + state.scores[2] == state.total_amount
	_check(conserved, "Chaque état publié conserve exactement le contenu initial")
	bottle.configure(game.players, origin)
	bottle.configure(game.players, origin)
	j1.reset_combat()
	_check(bottle.remaining == 11 and bottle.scores == {1: 0, 2: 0}
		and bottle.holder == null and not bottle.get_state().empty,
		"Réinitialiser la bouteille remet aussi à zéro son état de fin et ses fractions")
	j2.position = origin + Vector2(100, 0)
	j1.position = origin
	bottle._physics_process(0.1)
	j1._enter_ghost()
	bottle._drink(1.0)
	bottle._physics_process(1.0)
	_check(bottle.holder == null and bottle.remaining == 11 and bottle.scores == {1: 0, 2: 0},
		"Un porteur devenu fantôme ne consomme plus et ne peut pas reprendre")
	await _fresh()
	await _hold_with_j1()
	_check(not game.status.text.contains("%") and not game.player_labels[0].text.contains("%")
		and not game.player_labels[1].text.contains("%"),
		"Aucun pourcentage de réserve ou de score affiché pendant le round")


func _verify_ghost() -> void:
	await _fresh()
	await _hold_with_j1()
	_mouse(true, j1.position + Vector2(0, 100))
	await _frames()
	_mouse(false, j1.position + Vector2(0, 100))
	var score: int = bottle.scores[1]
	j1.take_damage(100, j2)
	_check(j1.is_ghost() and j1.health == 0 and j1.collision_layer == 0
		and bottle.holder == null, "Zéro vie : fantôme et bouteille perdue")
	var ammunition: int = j1.weapon.ammunition
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	_key(KEY_R, true)
	_mouse(true, j1.position + Vector2(100, 0))
	var origin: Vector2 = j1.position
	await _frames(15)
	_check(j1.position.x > origin.x + 6 and j1.position.x < origin.x + 12
		and not j1.is_dashing() and not j1.weapon.is_reloading() and j1.weapon.ammunition == ammunition,
		"Le fantôme se déplace très lentement, sans tir, dash ou recharge")
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_key(KEY_R, false)
	_mouse(false, j1.position)
	j1.stop_movement()
	var health: int = j1.health
	j1.take_damage(100, j2)
	_check(j1.health == health and j1.health > 0, "Fantôme invulnérable, vie récupérée progressivement")
	await _frames(15)
	bottle.holder = null
	bottle.velocity = Vector2.ZERO
	bottle._throw_time_left = 0.0
	bottle.position = j1.position
	j2.position = j1.position + Vector2(100, 0)
	await _frames()
	_check(bottle.holder == null, "Un fantôme ne ramasse pas la bouteille, même après le délai")
	var target = load("res://scenes/character/character.tscn").instantiate()
	target.combat_enabled = true
	target.get_node("HumanControls").source = 1
	target.position = j1.position - Vector2(70, 0)
	game.world.add_child(target)
	_stick(JOY_AXIS_RIGHT_X, -1.0)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames()
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _frames(14)
	_check(target.health == 75, "Les projectiles traversent le fantôme et atteignent la cible derrière")
	target.queue_free()
	j2.position = j1.position + Vector2(10, 0)
	origin = j1.position
	_key(KEY_D, true)
	await _frames(40)
	_check(j1.position.x > j2.position.x + 10 and j2.position.is_equal_approx(origin + Vector2(10, 0)),
		"Le fantôme traverse les personnages sans les repousser")
	_wall(j1.position + Vector2(20, 0))
	origin = j1.position
	await _frames(45)
	_check(j1.position.x <= origin.x + 12.1, "Les murs restent solides pour le fantôme")
	_key(KEY_D, false)
	j1.stop_movement()
	origin = j1.position
	await _capture("ghost")
	await _frames(300)
	_check(not j1.is_ghost() and j1.health == 100 and j1.weapon.ammunition == 6
		and j1.position.distance_to(origin) < 0.25, "Retour sur place, à pleine vie et chargeur plein")
	_check(bottle.scores[1] >= score, "Le score est conservé pendant le mode fantôme")
	j1.take_damage(25, j2)
	_check(j1.health == 75, "Le retour au combat est immédiatement vulnérable")


func _verify_pause_and_end() -> void:
	await _fresh()
	await _hold_with_j1()
	_mouse(true, j1.position + Vector2(0, 100))
	await _frames()
	_mouse(false, j1.position)
	_key(KEY_R, true)
	_key(KEY_R, false)
	j2.take_damage(100, j1)
	await _frames(5)
	var remaining: int = bottle.remaining
	var health: int = j2.health
	var progress: float = j1.weapon.reload_progress()
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	await _frames(30)
	_check(paused and bottle.remaining == remaining and j2.health == health
		and is_equal_approx(j1.weapon.reload_progress(), progress),
		"Échap suspend consommation, rechargement et récupération du fantôme")
	game.resume_button.pressed.emit()
	await _frames(24)
	_check(not paused and bottle.remaining < remaining and j2.health > health
		and j1.weapon.ammunition == 6, "Reprendre poursuit les temps suspendus")
	root.focus_exited.emit()
	await _frames()
	_check(paused, "Perte de focus : pause commune")
	game.resume_match()
	Input.joy_connection_changed.emit(7, false)
	await _frames()
	_check(paused and j2.controls.joypad_device < 0, "Déconnexion de la manette : pause commune")
	Input.joy_connection_changed.emit(7, true)
	_check(paused, "Reconnexion : reprise volontaire requise")
	game.resume_match()
	await _fresh()
	bottle.total_amount = 120
	bottle.remaining = 120
	await _hold_with_j1()
	for i in range(120):
		if bottle.scores[1] >= 60:
			break
		await _frames()
	bottle.throw_distance = 0.0
	j1.take_damage(25, j2)
	j1.position += Vector2(-35, 0)
	j2.position = bottle.position
	await _frames(70)
	_check(game.phase == game.Phase.FINISHED and bottle.remaining == 0
		and bottle.scores[1] == 60 and bottle.scores[2] == 60,
		"Bouteille vide : arrêt exact de la consommation, quantités conservées")
	_check(bottle.winner_numbers() == [1, 2] and game.announcement.text.contains("partagée"),
		"Égalité exacte : victoire partagée affichée")
	remaining = bottle.remaining
	await _frames(20)
	_check(bottle.remaining == remaining and game.world.process_mode == Node.PROCESS_MODE_DISABLED,
		"Le résultat arrête le gameplay")
	game.replay_button.pressed.emit()
	await _frames(3)
	_bind_game()
	_check(game.phase == game.Phase.COUNTDOWN and bottle.remaining == 2400
		and bottle.scores == {1: 0, 2: 0} and j1.health == 100 and not j1.is_ghost()
		and get_nodes_in_group("revolver_bullets").is_empty(), "Rejouer réinitialise toute la partie")
	game.countdown_left = 0.01
	await _frames(3)
	bottle.total_amount = 60
	bottle.remaining = 60
	await _hold_with_j1()
	for i in range(60):
		if bottle.scores[1] >= 40:
			break
		await _frames()
	bottle.throw_distance = 0.0
	j1.take_damage(25, j2)
	j1.position += Vector2(-35, 0)
	j2.position = bottle.position
	await _frames(30)
	_check(bottle.winner_numbers() == [1] and game.announcement.text.contains("J1 remporte"),
		"Le plus gros buveur gagne, indépendamment du porteur final")
	await _capture("result")


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(folder)
	_check(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK,
		"Capture : " + name)


func _run() -> void:
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.start_match()
	await _frames(3)
	_bind_game()
	_check(game.name == "Match" and game.phase == game.Phase.COUNTDOWN,
		"Le prototype ouvre la partie avec un décompte commun")
	var first: Vector2 = j1.position
	_key(KEY_D, true)
	await _frames(12)
	_check(j1.position == first and bottle.remaining == 2400, "Aucun mouvement ou score avant le départ")
	_key(KEY_D, false)
	_check(is_equal_approx(j1.position.distance_to(bottle.position), j2.position.distance_to(bottle.position)),
		"Départs à égale distance de la bouteille sur la vraie carte")
	await _frames(180)
	_check(game.phase == game.Phase.PLAYING and not game.arena.show_bottle_marker,
		"Signal de départ et une seule bouteille de gameplay")
	await _verify_bottle_contract()
	await _fresh()
	await _verify_possession_and_drops()
	await _verify_second_carrier_actions()
	await _verify_arbitration()
	await _verify_ghost()
	await _fresh()
	await _hold_with_j1()
	await _frames(30)
	var visible := Rect2(8, 58, 624, 244)
	var transform := root.get_canvas_transform()
	_check(visible.has_point(transform * j1.position) and visible.has_point(transform * j2.position)
		and visible.has_point(transform * (bottle.position + Vector2(0, -38))),
		"Le cadrage commun garde personnages et bouteille hors du HUD")
	await _capture("bottle-carried")
	await _verify_pause_and_end()
	game.pause_match()
	game.return_to_title()
	await _frames(3)
	_check(not paused and current_scene.name == "Main" and not is_instance_valid(current_scene.intro),
		"Retour au titre sans pause résiduelle ni relecture d’introduction")
	await _finish_report("MATCH CHECK")


func _finish_report(label: String) -> void:
	var folder := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(folder)
	var report_name := "verification-headless.json" if DisplayServer.get_name() == "headless" \
		else "verification-rendered.json"
	var report := FileAccess.open(folder.path_join(report_name), FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures,
			"results": results, "engine": Engine.get_version_info().string,
			"scene": "res://scenes/match/match.tscn",
			"rendered": DisplayServer.get_name() != "headless",
			"status": "passed" if failures.is_empty() else "failed"}, "\t") + "\n")
	print(label, ": ", "PASS" if failures.is_empty() else failures, " (", checks, " checks)")
	# Let stopped audio voices release their streams before terminating a fixed-fps run.
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
	await _frames(2)
	OS.delay_msec(100)
	quit(0 if failures.is_empty() else 1)
