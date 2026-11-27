extends "res://tools/verify_match.gd"
## Public v0.2 composition. Scenario fixtures are separate from the full unchanged round.

var routes: Array[Dictionary] = []


func _initialize() -> void:
	output_dir = "res://../output/gameplay/2026-11-27-v02"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence="):
			output_dir = argument.trim_prefix("--evidence=")
	create_timer(180).timeout.connect(func():
		push_error("V02 CHECK: timeout")
		quit(2))
	_run.call_deferred()


func _bind_game() -> void:
	game = current_scene
	bottle = game.bottle
	j1 = game.players[0]
	j2 = game.players[1]
	j2.controls._random.seed = 20261127


func _new_round() -> void:
	_key(KEY_D, false)
	_key(KEY_R, false)
	_key(KEY_SPACE, false)
	_mouse(false, Vector2.ZERO)
	game.replay()
	await _frames(3)
	_bind_game()
	game.countdown_left = 0.01
	await _frames(3)


func _verify_navigation() -> void:
	for scenario in [
		["saloon", Vector2(360,504), Vector2(704,240)],
		["épicerie", Vector2(1072,536), Vector2(800,712)],
		["remise", Vector2(256,816), Vector2(432,688)],
		["enclos", Vector2(1184,224), Vector2(1008,344)],
		["près du couvert", Vector2(1008,344), Vector2(840,432)]]:
		await _new_round()
		j1.combat_enabled = false
		j1.position = Vector2(704, 808)
		j2.position = scenario[1] - Vector2(0,16)
		bottle.configure(game.players, scenario[2] - Vector2(0,16))
		j2.controls.release()
		var elapsed := 0
		var trace: Array[Vector2] = []
		var clear := true
		for frame in range(900):
			if bottle.holder == j2:
				break
			await _frames()
			elapsed += 1
			if frame % 15 == 0:
				trace.append(j2.position)
				clear = clear and game.navigation.clear_point(j2.position)
		_check(bottle.holder == j2, "Garcia rejoint et prend la bouteille : " + scenario[0])
		_check(clear, "Trajet dans les zones libres, sans traverser le décor : " + scenario[0])
		routes.append({"scenario": scenario[0], "frames": elapsed,
			"taken": bottle.holder == j2, "trace": trace})
		print("BOT ROUTE: ", scenario[0], " ", elapsed, " frames, taken=", bottle.holder == j2)
		if scenario[0] == "saloon":
			await _capture("bot-saloon")


func _verify_bot_combat() -> void:
	await _new_round()
	var center: Vector2 = game.arena.tile_point(game.arena.layout.bottle)
	j1.position = center
	j2.position = center + Vector2(250,0)
	bottle.configure(game.players, center)
	j2.controls.release()
	await _frames(3)
	var hits: Array = []
	j1.damaged.connect(func(_amount, attacker): hits.append(attacker))
	var start: Vector2 = j2.position
	for frame in range(480):
		if not hits.is_empty():
			break
		await _frames()
	_check(not hits.is_empty() and hits[0] == j2,
		"Garcia vise et blesse Poncho porteur avec un vrai projectile")
	_check(bottle.holder != j1, "Le tir du bot fait perdre la bouteille au porteur")
	_check(j2.weapon.ammunition < j2.weapon.capacity, "Le bot dépense ses vraies cartouches")
	var inserts: Array = []
	var shots: Array = []
	j2.weapon.cartridge_inserted.connect(func(): inserts.append(true))
	j2.weapon.fired.connect(func(): shots.append(true))
	j2.weapon.ammunition = 0
	j2.weapon.cancel_reload()
	for frame in range(24):
		if j2.weapon.is_reloading():
			break
		await _frames()
	_check(j2.weapon.is_reloading() and j2.weapon.ammunition == 0,
		"Chargeur vide : le bot demande la recharge sans remplissage instantané")
	await _frames(210)
	_check(inserts.size() >= 6 and not shots.is_empty(),
		"Six insertions au rythme existant puis reprise du tir")
	await _capture("bot-combat")
	await _new_round()
	j1.combat_enabled = false
	start = j2.position
	var human_start: Vector2 = j1.position
	_key(KEY_D, true)
	_stick(JOY_AXIS_LEFT_X, 1.0)
	await _frames(10)
	_key(KEY_D, false)
	_stick(JOY_AXIS_LEFT_X, 0.0)
	_check(j1.position.x > human_start.x and j2.position.x < start.x,
		"Clavier et manette ne détournent pas les intentions de Garcia bot")


func _verify_bot_ghost() -> void:
	await _new_round()
	var center: Vector2 = bottle.position
	j2.position = center
	j1.position = center + Vector2(100,0)
	await _frames(12)
	_check(bottle.holder == j2 and bottle.scores[2] > 0, "Garcia porte et boit avant le fantôme")
	j2.take_damage(100, j1)
	var amount: int = bottle.scores[2]
	var origin: Vector2 = j2.position
	var shots: Array = []
	j2.weapon.fired.connect(func(): shots.append(true))
	await _frames(15)
	_check(j2.is_ghost() and j2.health > 0 and j2.health < 100 and j2.position.distance_to(origin) < 10,
		"Garcia fantôme s’écarte très lentement pendant une récupération progressive")
	_check(bottle.holder != j2 and shots.is_empty() and not j2.weapon.is_reloading(),
		"Le bot fantôme ne tire, ne recharge et ne ramasse pas")
	_check(game.presentation.particle_count(j2) == 0 and j2.visual.material != null,
		"Fantôme désaturé, toutes les étoiles d’ivresse masquées")
	var health: int = j2.health
	j2.take_damage(100, j1)
	_check(j2.health == health, "Garcia fantôme est invulnérable")
	await _capture("ghost-close")
	game.overview = true
	await _frames(2)
	await _capture("ghost-far")
	game.overview = false
	game._update_camera(0.0)
	health = j2.health
	var before_clock: float = game.presentation.clock
	var before_bot: Vector2 = j2.position
	var before_amount: int = bottle.remaining
	var before_camera: Vector2 = game.camera.position
	var before_zoom: Vector2 = game.camera.zoom
	game.pause_match()
	await _frames(40)
	_check(j2.position == before_bot and j2.health == health and bottle.remaining == before_amount
		and game.presentation.clock == before_clock and game.camera.position == before_camera
		and game.camera.zoom == before_zoom, "Pause : bot, vie, consommation, caméra et étoiles figés")
	await _capture("ghost-pause")
	game.resume_match()
	var last: Vector2 = j2.position
	for frame in range(330):
		last = j2.position
		await _frames()
		if not j2.is_ghost():
			break
	_check(j2.is_active() and j2.health == 100 and j2.weapon.ammunition == 6
		and j2.position.distance_to(last) < 1,
		"Retour de Garcia sur place, à pleine vie et chargeur plein")
	_check(bottle.scores[2] == amount and game.presentation.particle_count(j2) > 0
		and j2.visual.material == null, "Score, ivresse et couleurs restaurés après le fantôme")
	await _capture("ghost-return")
	j2.take_damage(25, j1)
	_check(j2.health == 75 and game.phase == game.Phase.PLAYING,
		"Retour vulnérable sans nouveau round ni résultat")
	# The opponent also becomes untargetable immediately, between AI decisions.
	j1.take_damage(100, j2)
	await _frames()
	_check(j2.controls.target == null and not j2.controls.fire_pressed(),
		"Le bot cesse immédiatement de viser et tirer sur un adversaire devenu fantôme")


func _verify_human_device() -> void:
	await _new_round()
	j2.controls.set_physics_process(false)
	j2.stop_movement()
	# Exercise shooting in open ground. Close cover intentionally substitutes
	# a melee strike in v0.3 and is verified separately by verify_v03_review.
	j1.position = Vector2(704,512)
	j2.position = Vector2(884,512)
	game._select_device(7)
	var origin: Vector2 = j1.position
	_stick(JOY_AXIS_LEFT_X, 1.0)
	_stick(JOY_AXIS_RIGHT_Y, 1.0)
	await _frames(6)
	_check(j1.position.x > origin.x and j1.aim_direction.dot(Vector2.DOWN) > 0.99,
		"La manette choisie commande déplacement et visée de Poncho")
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames()
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check(j1.weapon.ammunition == 5, "RT tire avec le revolver commun de Poncho")
	_joy_button(JOY_BUTTON_X, true)
	_joy_button(JOY_BUTTON_X, false)
	await _frames(2)
	_check(j1.weapon.is_reloading(), "X / carré recharge Poncho à la manette")
	Input.joy_connection_changed.emit(7, false)
	await _frames(2)
	_check(paused and j1.controls.joypad_device < 0, "Déconnexion de la manette de Poncho : pause commune")
	Input.joy_connection_changed.emit(7, true)
	await _frames(2)
	_check(paused and j1.controls.joypad_device == 7, "Reconnexion : pas de reprise automatique")
	game.resume_button.pressed.emit()
	game._select_device(-1)
	_stick(JOY_AXIS_LEFT_X, 0.0)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	_check(not paused and j1.controls.source == j1.controls.Source.KEYBOARD_MOUSE,
		"Reprise volontaire puis retour aux commandes clavier/souris")


func _verify_covered_carrier() -> void:
	await _new_round()
	j1.position = Vector2(360,488)
	j2.position = Vector2(704,224)
	bottle.configure(game.players, j1.position)
	j2.controls.release()
	await _frames(3)
	var origin: Vector2 = j2.position
	var hits: Array = []
	j1.damaged.connect(func(_amount, attacker): hits.append(attacker))
	var before: int = j2.weapon.ammunition
	await _frames(12)
	_check(j2.weapon.ammunition == before, "Le bot ne tire pas dans le bâtiment qui masque le porteur")
	for frame in range(720):
		if not hits.is_empty():
			break
		await _frames()
	_check(not hits.is_empty() and hits[0] == j2 and j2.position.distance_to(origin) > 80,
		"Garcia contourne le bâtiment, retrouve une ligne de tir et touche le porteur")


func _verify_presentation_and_results() -> void:
	await _new_round()
	j2.controls.set_physics_process(false)
	j2.stop_movement()
	j1.position = bottle.position - Vector2(100,0)
	j2.position = bottle.position + Vector2(100,0)
	await _frames(3)
	await _capture("ground-close")
	game.overview = true
	await _frames(2)
	await _capture("ground-far")
	await _new_round()
	j2.controls.set_physics_process(false)
	j2.stop_movement()
	j1.position = bottle.position
	j2.position = bottle.position + Vector2(100,0)
	await _frames(780)
	var visuals = game.presentation
	var actual_score: int = bottle.scores[1]
	var counts: Array[int] = []
	for amount in [1,240,720,1200,1800,2400]:
		bottle.scores[1] = amount
		counts.append(visuals.particle_count(j1))
	bottle.scores[1] = actual_score
	var increasing := true
	for index in range(1, counts.size()):
		increasing = increasing and counts[index] > counts[index - 1]
	_check(increasing and counts[-1] <= 24,
		"Ivresse : densité croissante sur toute la bouteille, avec un plafond lisible")
	_check(visuals.cue_counts.take == 1 and visuals.particle_count(j1) == 16,
		"Prise : un son, ivresse forte raccordée aux quantités réellement bues")
	await _capture("poncho-carried-close")
	game.overview = true
	await _frames(2)
	await _capture("poncho-carried-far")
	game.overview = false
	game._update_camera(0.0)
	j1.take_damage(25, j2)
	_check(visuals.cue_counts.drop == 1 and visuals.particle_count(j1) == 16,
		"Perte : un son distinct et ivresse conservée sans marquage de possession")
	j2.position = bottle.position + Vector2(25,0)
	await _frames(3)
	_check(bottle.holder == j2 and visuals.cue_counts.take == 2
		and bottle.scores[1] > bottle.scores[2], "Le porteur moins ivre reçoit immédiatement le marquage prioritaire")
	await _capture("transfer-close")
	game.overview = true
	await _frames(2)
	await _capture("transfer-far")
	game.overview = false
	game._update_camera(0.0)
	var a: Dictionary = visuals.star_flight(0, 12, 0.15)
	var b: Dictionary = visuals.star_flight(0, 12, 0.25)
	var c: Dictionary = visuals.star_flight(0, 12, 1.5)
	_check(a.origin == b.origin and a.origin != c.origin and a.point != b.point,
		"Étoiles en vol : origine stable, mouvement effectif, origine renouvelée à la naissance suivante")
	_check(visuals.star_flight(0,12,visuals.star_lifetime * 0.75).point.y >
		visuals.star_flight(0,12,visuals.star_lifetime * 0.35).point.y,
		"Les étoiles montent puis retombent en cloche")
	# Fixed low-reserve gallery fixture, preserving the amount invariant.
	bottle.set_physics_process(false)
	bottle.scores = {1:1600,2:680}
	bottle.remaining = 120
	await _frames(2)
	await _capture("low-reserve-close")
	game.overview = true
	await _frames(2)
	await _capture("low-reserve-far")
	_verify_reserve_geometry()
	# Result fixtures shorten the last sip, without changing the full-round scenario below.
	await _new_round()
	j2.controls.set_physics_process(false)
	j2.stop_movement()
	j1.position = bottle.position
	j2.position = bottle.position + Vector2(100,0)
	bottle.total_amount = 6
	bottle.configure(game.players, bottle.position)
	await _frames(12)
	_check(game.phase == game.Phase.FINISHED and game.announcement.text.contains("Poncho")
		and game.details.text.contains("100.0"), "Résultat public : gagnant et pourcentage de la bouteille initiale")
	_check(game.presentation.cue_counts.empty == 1
		and not game.presentation._audio.empty.stream_paused,
		"Bouteille vide : un seul son, sa lecture reste possible au résultat")
	var cues: Dictionary = game.presentation.cue_counts.duplicate()
	var clock: float = game.presentation.clock
	await _frames(30)
	_check(cues == game.presentation.cue_counts and clock == game.presentation.clock,
		"Résultat : aucun nouveau son ni animation de jeu")
	await _capture("result-poncho")
	game.replay_button.pressed.emit()
	await _frames(3)
	_bind_game()
	_check(game.phase == game.Phase.COUNTDOWN and bottle.remaining == 2400
		and bottle.scores == {1:0,2:0} and j1.health == 100 and j2.health == 100
		and game.presentation.cue_counts == {"take":0,"drop":0,"empty":0},
		"Rejouer remet partie, bot, réserve, scores, vie et sons à zéro")
	game.countdown_left = 0.01
	await _frames(3)
	j2.controls.set_physics_process(false)
	j1.position = bottle.position + Vector2(-100,0)
	j2.position = bottle.position
	bottle.total_amount = 12
	bottle.configure(game.players, bottle.position)
	bottle.scores = {1:6,2:5}
	bottle.remaining = 1
	await _frames(3)
	_check(game.announcement.text.contains("partagée") and game.details.text.contains("50.0")
		and bottle.winner_numbers() == [1,2], "Égalité exacte : victoire partagée et pourcentage commun")
	await _capture("result-tie")
	game.result_title_button.pressed.emit()
	await _frames(3)
	_check(current_scene.name == "Main" and not paused and not is_instance_valid(current_scene.intro),
		"Retour au titre existant sans relire l’introduction")
	current_scene.start_match()
	await _frames(3)
	_bind_game()


func _verify_full_round() -> void:
	await _new_round()
	var frames := 0
	var takes: Array = []
	bottle.picked_up.connect(func(holder): takes.append(holder.player_number))
	for frame in range(7200):
		if game.phase == game.Phase.FINISHED:
			break
		await _frames()
		frames += 1
		if frame % 1200 == 0:
			print("FULL ROUND: frame=",frame," reserve=",bottle.remaining," bot=",j2.position)
	_check(game.phase == game.Phase.FINISHED and bottle.remaining == 0,
		"Round complet sans fixture de quantité ou téléportation jusqu’à bouteille vide")
	_check(bottle.total_amount == 2400 and bottle.scores[1] + bottle.scores[2] == 2400
		and takes.has(2), "Contenu d’origine conservé, prise réelle de Garcia et victoire calculée")
	await _capture("full-round-result")
	print("FULL ROUND COMPLETED: ",frames," frames; scores=",bottle.scores)


func _verify_reserve_geometry() -> void:
	# Compare the actual cached bottle pixels with the approved V10 outer ellipse.
	var image: Image = game.presentation.art.full.get_image()
	var scale := (100.0 / 3.0) / image.get_height()
	var outside := 0
	var maximum := 0.0
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a <= 20.0 / 255.0:
				continue
			var dx := (x + 0.5 - image.get_width() / 2.0) * scale
			var dy := (y + 0.5 - image.get_height() / 2.0) * scale
			var equation := pow(dx / 14.4, 2) + pow(dy / 20.8, 2)
			maximum = maxf(maximum, equation)
			outside += int(equation > 1.0)
			count += 1
	_check(outside == 0, "Bouteille fixe V10 : tous les pixels visibles contenus dans l’ovale extérieur")
	var folder := ProjectSettings.globalize_path(output_dir + "/checks")
	DirAccess.make_dir_recursive_absolute(folder)
	var report := FileAccess.open(folder.path_join("reserve-geometry.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"pixels_checked":count,"outside_outer_oval":outside,
		"max_ellipse_equation":maximum,"outer_radii":[14.4,20.8],"bottle_height":100.0/3.0},"\t")+"\n")


func _run() -> void:
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.get_node("CenterContainer/Content/SoloTrialButton").pressed.emit()
	await _frames(3)
	_bind_game()
	_check(game.name == "Match" and game.bot_enabled and game.phase == game.Phase.COUNTDOWN,
		"Jouer ouvre le duel fixe Poncho humain / Garcia bot")
	var start: Vector2 = j2.position
	await _frames(20)
	_check(j2.position == start and bottle.remaining == 2400 and bottle.scores == {1:0,2:0},
		"Le bot et les quantités attendent le départ commun")
	_check(game.presentation.particle_count(j1) == 0 and game.presentation.particle_count(j2) == 0,
		"Aucune ivresse initiale, interface graphique sans HUD textuel de scores")
	await _capture("countdown")
	await _verify_navigation()
	await _verify_bot_combat()
	await _verify_bot_ghost()
	await _verify_human_device()
	await _verify_covered_carrier()
	await _verify_presentation_and_results()
	await _verify_full_round()
	var folder := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(folder)
	var report := FileAccess.open(folder.path_join("bot-routes.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(routes,"\t") + "\n")
	await _finish_report("V02 CHECK")
