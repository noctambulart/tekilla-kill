extends "res://tools/verify_v02.gd"
## Real village, shared attacks, swept dash and public replay contract.

const CENTER := Vector2(704, 512)
const FOOT := Vector2(0, 16)
var fixture_id := 0


func _initialize() -> void:
	output_dir = "res://../output/gameplay/2026-11-27-v03"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence="):
			output_dir = argument.trim_prefix("--evidence=")
	create_timer(120).timeout.connect(func(): quit(2))
	_run.call_deferred()


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw()
	var folder := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(folder)
	_check(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK,
		"Capture : " + name)


func _sandbox() -> void:
	await _new_round()
	for actor in game.players:
		actor.stop_movement()
		actor.set_physics_process(false)
	j2.controls.set_physics_process(false)
	bottle.set_physics_process(false)
	j1.position = CENTER
	j2.position = CENTER + Vector2(180, 0)
	j1.aim_direction = Vector2.RIGHT
	j2.aim_direction = Vector2.LEFT
	await _frames(2)


func _prop(kind: String, center: Vector2):
	fixture_id += 1
	var id := "v03-fixture-%d" % fixture_id
	game.arena._add_prop({"id": id, "kind": kind, "position": [0, 0], "width": 24})
	var prop: Node2D = game.arena.prop_nodes[id]
	var body
	for child in prop.get_children():
		if child is StaticBody2D:
			body = child
	var points := PackedVector2Array()
	for child in body.get_children():
		if child is CollisionPolygon2D:
			points = child.polygon
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var previous: Vector2 = prop.position
	prop.position = center - bounds.get_center()
	prop.z_index = roundi(prop.position.y)
	game.arena.get_node(NodePath(id + "Shadow")).position += prop.position - previous
	return body


func _shoot(actor, target: Vector2) -> void:
	actor.aim_direction = (target - actor.position).normalized()
	actor.weapon.advance(0.25, true, true, true)
	await _frames(12)


func _verify_destruction() -> void:
	await _sandbox()
	var counts := {"crate": 0, "chair": 0, "pot": 0}
	for body in get_nodes_in_group("breakable_props"):
		counts[body.kind] += 1
		_check(body.health == {"crate":125, "chair":75, "pot":25}[body.kind],
			"Résistance de l’objet réel : " + str(body.get_parent().name))
	_check(counts.crate > 0 and counts.chair > 0 and counts.pot > 0,
		"Les trois familles sont raccordées sur le village actuel")
	for kind in ["pot", "chair_n", "crate"]:
		await _sandbox()
		var prop = _prop(kind, CENTER + Vector2(60, 16))
		await _frames(2)
		var required: int = {"pot":1, "chair_n":3, "crate":5}[kind]
		_check(not game.navigation.clear_segment(CENTER, CENTER + Vector2(120,0)),
			"Marche bloquée par l’intact : " + kind)
		j2.position = CENTER + Vector2(120, 0)
		for hit in range(required):
			await _shoot(j1, j2.position)
			_check(j2.health == 100 and prop.broken == (hit == required - 1),
				"La balle s’arrête sur " + kind + " · impact " + str(hit + 1))
		_check(game.navigation.clear_segment(CENTER, CENTER + Vector2(120,0)),
			"Les débris libèrent le passage : " + kind)
		await _shoot(j1, j2.position)
		_check(j2.health == 75, "La ligne de tir traverse les débris : " + kind)
		game.overview = false
		await _capture("broken-" + kind)
	await _sandbox()
	var prop = _prop("crate", CENTER + Vector2(30,16))
	await _frames(2)
	game.navigation.configure(game.arena)
	var cell := Vector2i((CENTER + Vector2(30,16) - game.navigation.grid.offset) / 16.0)
	_check(game.navigation.grid.is_point_solid(cell), "Le couvert occupe la grille du bot")
	prop.take_damage(125, j1)
	await _frames(2)
	game.navigation.route(CENTER, CENTER + Vector2(100,0))
	_check(not game.navigation.grid.is_point_solid(cell), "La casse ouvre aussi les cellules de navigation")
	# Walls remain permanent even after real repeated shots.
	var wall := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2, 60)
	collider.shape = shape
	wall.add_child(collider)
	wall.position = CENTER + Vector2(60,0)
	game.world.add_child(wall)
	j2.position = CENTER + Vector2(100,0)
	await _frames(2)
	for hit in range(3):
		await _shoot(j1, j2.position)
	_check(j2.health == 100 and wall.collision_layer == 1,
		"Un mur reste permanent et arrête les tirs")


func _verify_melee() -> void:
	await _sandbox()
	j2.position = CENTER + Vector2(25,0)
	await _frames(2)
	var hits: Array = []
	var bullets: Array = []
	j1.weapon.melee_struck.connect(func(target): hits.append(target))
	j1.weapon.fired.connect(func(): bullets.append(true))
	j1.weapon.ammunition = 0
	j1.weapon.advance(0.0, true, true, true)
	_check(j2.health == 75 and hits == [j2] and bullets.is_empty() and j1.weapon.ammunition == 0,
		"Crosse à vide : une unité, aucune balle ni projectile")
	j1.weapon.advance(0.23, true, false, true)
	_check(j2.health == 75, "Cadence commune : aucune deuxième attaque avant 0,24 s")
	j1.weapon.advance(0.011, true, false, true)
	_check(j2.health == 50 and hits.size() == 2, "Maintien : deuxième crosse à cadence normale")
	j2.position = CENTER + Vector2(80,0)
	j1.weapon.ammunition = 2
	j1.weapon.advance(0.25, true, false, true)
	_check(j1.weapon.ammunition == 1 and bullets.size() == 1,
		"Le maintien réévalue et redevient un tir hors de portée")
	await _frames(8)
	await _sandbox()
	for offset in [Vector2(-25,0), Vector2(15,24), Vector2(31,0)]:
		j2.position = CENTER + offset
		await _frames(2)
		_check(j1.weapon.find_melee_target() == null, "Cible exclue de la portée / de l’arc : " + str(offset))
	j2.position = CENTER + Vector2(20,15)
	await _frames(2)
	_check(j1.weapon.find_melee_target() == j2, "Cible admissible à l’intérieur de l’arc de 90°")
	j2.position = CENTER + Vector2(25,0)
	_wall(CENTER + Vector2(12,0))
	await _frames(2)
	_check(j1.weapon.find_melee_target() != j2 and j1.weapon.find_melee_target() != null,
		"La crosse frappe le mur fin qui masque l’adversaire")
	await _sandbox()
	j2.position = CENTER + Vector2(25,0)
	j1.weapon.ammunition = 0
	j1.weapon.advance(0.0, false, false, true, true)
	j1.weapon.advance(0.41, false, false, true)
	await _frames(2)
	j1.weapon.advance(0.0, true, true, true)
	_check(not j1.weapon.is_reloading() and j1.weapon.ammunition == 1 and j2.health == 75,
		"Crosse : nouvel appui interrompt la recharge et conserve la cartouche")
	j1.weapon.ammunition = 0
	j1.weapon.advance(0.25, false, false, true, true)
	j1.weapon.advance(0.01, true, true, true)
	_check(not j1.weapon.is_reloading() and j2.health == 50 and j1.weapon.ammunition == 0,
		"Crosse : interruption possible avant la première cartouche")
	j1.weapon.advance(0.25, true, true, true, false, true)
	_check(j2.health == 50, "Aucune crosse pendant le dash")
	j2.health = 100
	bottle.configure(game.players, j2.position)
	bottle._physics_process(1.0 / 60.0)
	_check(bottle.holder == j2, "Le futur blessé porte la bouteille")
	j1.weapon.advance(0.25, true, true, true)
	_check(j2.health == 75 and bottle.holder == null and j2.is_stunned(),
		"La crosse applique la perte de bouteille et l’étourdissement habituels")
	_check(j2.position == CENTER + Vector2(25,0), "La crosse n’ajoute pas de recul")
	j2.weapon.ammunition = 0
	j2.weapon.advance(0.25, true, true, true)
	_check(j1.health == 75, "La crosse reste disponible au porteur étourdi")
	await _capture("melee-close")
	for hit in range(3):
		j1.weapon.advance(0.25, true, true, true)
	_check(j2.is_ghost() and j2.health == 0, "Quatre crosses déclenchent le fantôme")
	_check(j1.weapon.find_melee_target() == null, "Le fantôme n’est plus une cible de crosse")
	j2.weapon.advance(0.25, true, true, false)
	_check(j1.health == 75, "Le fantôme ne peut pas frapper")


func _dash_steps(count := 8) -> void:
	for index in range(count):
		if j1.is_dashing():
			j1._advance_dash(1.0 / 60.0)
		await _frames()


func _verify_dash_over_props() -> void:
	for kind in ["pot", "chair_n"]:
		await _sandbox()
		var prop = _prop(kind, CENTER + FOOT + Vector2(34,0))
		await _frames(2)
		j1._begin_dash(Vector2.RIGHT)
		await _dash_steps(3)
		await _capture("dash-" + kind)
		await _dash_steps(5)
		_check(absf(j1.position.x - CENTER.x - j1.dash_speed * j1.dash_duration) < 0.1
			and not prop.broken and prop.health == (25 if kind == "pot" else 75),
			"Dash franchit sans dégâts, à portée normale : " + kind)
		_check(j1.get_collision_exceptions().is_empty(), "Fin du dash : collisions restaurées")
	await _sandbox()
	var first = _prop("pot", CENTER + FOOT + Vector2(0,26))
	var second = _prop("chair_n", CENTER + FOOT + Vector2(0,45))
	await _frames(2)
	j1._begin_dash(Vector2.DOWN)
	await _dash_steps()
	_check(absf(j1.position.y - CENTER.y - 67.2) < 0.1 and not first.broken and not second.broken,
		"Un dash franchit deux petits objets intacts")
	for blocker in ["arrival", "wall", "crate", "opponent", "margin"]:
		await _sandbox()
		_prop("pot", CENTER + FOOT + Vector2(34,0))
		match blocker:
			"arrival": _prop("chair_n", CENTER + FOOT + Vector2(66,0))
			"crate": _prop("crate", CENTER + FOOT + Vector2(58,0))
			"opponent": j2.position = CENTER + Vector2(60,0)
			"wall": _wall(CENTER + Vector2(55,16))
			"margin": _wall(CENTER + Vector2(77,16))
		await _frames(2)
		j1._begin_dash(Vector2.RIGHT)
		await _dash_steps()
		_check(j1.position.x < CENTER.x + 18.0 and j1._dash_point_clear(j1.position),
			"Arrivée / trajet refusé, arrêt devant le pot : " + blocker)
	await _sandbox()
	_prop("crate", CENTER + FOOT + Vector2(34,0))
	await _frames(2)
	j1._begin_dash(Vector2.RIGHT)
	await _dash_steps()
	_check(j1.position.x < CENTER.x + 18.0, "Une caisse reste bloquante pendant le dash")
	for interruption in ["stun", "ghost", "stop"]:
		await _sandbox()
		_prop("pot", CENTER + FOOT + Vector2(34,0))
		await _frames(2)
		j1._begin_dash(Vector2.RIGHT)
		await _dash_steps(3)
		_check(not j1._dash_point_clear(j1.position), "Franchissement en cours avant interruption : " + interruption)
		match interruption:
			"stun": j1.stun(0.8)
			"ghost": j1.take_damage(100, j2)
			"stop": j1.stop_movement()
		_check(not j1.is_dashing() and j1._dash_point_clear(j1.position)
			and j1.get_collision_exceptions().is_empty(),
			"Interruption sans emprisonnement dans le pot : " + interruption)
	await _sandbox()
	_prop("pot", CENTER + FOOT + Vector2(34,0))
	await _frames(2)
	j1._begin_dash(Vector2.RIGHT)
	await _dash_steps(3)
	var position: Vector2 = j1.position
	var clock: float = j1._dash_time_left
	game.pause_match()
	await _frames(5)
	_check(j1.position == position and j1._dash_time_left == clock, "Pause au-dessus du pot : position et temps figés")
	game.resume_match()
	await _dash_steps(5)
	_check(j1.position.x > CENTER.x + 66.0, "Reprise du franchissement après pause")


func _verify_recovery() -> void:
	await _sandbox()
	var units: Array = []
	j1.health_unit_recovered.connect(func(unit): units.append(unit))
	j1.take_damage(100, j2)
	j1._advance_ghost(0.625)
	_check(j1._ghost_health > 12 and j1._ghost_health < 13 and units.is_empty(),
		"Le premier segment se remplit progressivement avant le son")
	j1._advance_ghost(0.625)
	_check(j1.health == 25 and units == [1], "Première unité complétée à 1,25 s : un son")
	j1.set_physics_process(true)
	game.pause_match()
	await _frames(30)
	_check(j1.health == 25 and units == [1], "Pause : récupération et sons figés")
	game.resume_match()
	j1.set_physics_process(false)
	await _frames(2)
	await _capture("ghost-segments")
	j1._advance_ghost(1.25)
	j1._advance_ghost(1.25)
	_check(j1.health == 75 and units == [1,2,3] and j1.is_ghost(), "Trois segments restaurés successivement à 3,75 s")
	j1._advance_ghost(1.25)
	_check(j1.health == 100 and units == [1,2,3,4] and not j1.is_ghost(),
		"Quatrième son à cinq secondes et retour au combat")
	var feedback = load("res://scenes/character/shot_feedback.gd")
	_check(feedback._make_clip(feedback.Cue.RECOVERY).data != j1.reload_audio.stream.data,
		"Le son de vie diffère de l’insertion de cartouche")
	await _new_round()
	_check(j1.health == 100 and j1._recovered_units == 0 and not j1.is_ghost()
		and game.arena.collision_revision == 0, "Rejouer restaure vie, récupération et décor intacts")


func _verify_inputs_v03() -> void:
	await _sandbox()
	j2.position = CENTER + Vector2(25,0)
	j1.set_physics_process(true)
	await _frames(2)
	_mouse(true, j2.position)
	await _frames(2)
	_mouse(false, j2.position)
	_check(j2.health == 75 and j1.weapon.ammunition == 6, "Clic réel : crosse remplace le tir au contact")
	await _sandbox()
	j2.position = CENTER + Vector2(25,0)
	game._select_device(7)
	j1.set_physics_process(true)
	_stick(JOY_AXIS_RIGHT_X, 1.0)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames(2)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	_check(j2.health == 75 and j1.weapon.ammunition == 6, "RT simulé : même crosse à la manette")
	game._select_device(-1)
	await _sandbox()
	var prop = _prop("pot", CENTER + FOOT + Vector2(34,0))
	j1.set_physics_process(true)
	_key(KEY_D, true)
	await _frames(3)
	var start: Vector2 = j1.position
	_key(KEY_SPACE, true)
	await _frames()
	_check(j1.is_dashing(), "Espace en déplacement lance le franchissement")
	_key(KEY_SPACE, false)
	_key(KEY_D, false)
	_mouse(true, j2.position)
	await _frames(7)
	_mouse(false, j2.position)
	_check(j1.position.x > start.x + 66 and j1.weapon.ammunition == 6 and not prop.broken,
		"Entrées réelles : franchissement complet, tir ignoré pendant le dash")
	await _sandbox()
	var real_prop: Node2D = game.arena.prop_nodes["street-crate"]
	j1.position = real_prop.position + Vector2(-60,-16)
	j2.position = real_prop.position + Vector2(60,-16)
	await _frames(2)
	await _capture("street-cover-intact")
	for hit in range(5):
		await _shoot(j1, j2.position)
	_check(game.arena.collision_revision == 1 and j2.health == 100,
		"Cinq tirs détruisent la caisse de rue réelle sans toucher Garcia derrière")
	await _capture("street-cover-broken")


func _verify_bot_v03() -> void:
	await _sandbox()
	j1.position = CENTER + Vector2(25,0)
	j2.position = CENTER
	j2.weapon.ammunition = 0
	j2.set_physics_process(true)
	j2.controls.set_physics_process(true)
	j2.controls.reaction_delay = 0.0
	j2.controls.release()
	await _frames(5)
	_check(j1.health < 100 and j2.weapon.ammunition == 0,
		"Garcia bot utilise la même crosse au contact, même à vide")
	await _sandbox()
	var prop = _prop("crate", CENTER + Vector2(65,16))
	j2.position = CENTER
	j1.position = CENTER + Vector2(130,0)
	bottle.configure(game.players, j1.position)
	bottle._physics_process(1.0 / 60.0)
	await _frames(2)
	j2.controls.release()
	j2.controls._decide()
	_check(not j2.controls.fire_pressed() and not j2.controls._path.is_empty(),
		"Garcia poursuit un porteur masqué au lieu de tirer dans une caisse")
	prop.take_damage(125, j1)
	await _frames(2)
	j2.controls._reaction_left = 0.0
	j2.controls._decide()
	_check(j2.controls.fire_pressed(), "Garcia reconnaît immédiatement la ligne de tir ouverte par la casse")
	# Exercise the public bot through pickup and the unchanged result flow too.
	await _verify_navigation()
	await _verify_full_round()


func _run() -> void:
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.start_match()
	await _frames(3)
	_bind_game()
	_check(game.bot_enabled and game.status.text.contains("v0.3"), "Jouer lance la v0.3 publique")
	await _verify_destruction()
	await _verify_melee()
	await _verify_dash_over_props()
	await _verify_recovery()
	await _verify_inputs_v03()
	await _verify_bot_v03()
	await _finish_report("V03 CHECK")
