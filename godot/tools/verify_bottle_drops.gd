extends "res://tools/verify_match.gd"
## #24: real projectiles for combat; controlled damage for exhaustive map geometry.

const DROPS_OUTPUT := "res://../output/gameplay/2026-11-27-issue-24"
var map_cases := 0


func _clear_feet(point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var core := CircleShape2D.new()
	core.radius = 8.0
	query.shape = core
	query.collision_mask = 1
	query.transform = Transform2D(0, point)
	return bottle.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _fire_at(shooter, victim) -> void:
	if shooter == j1:
		_mouse(true, victim.global_position)
	else:
		var aim: Vector2 = (victim.global_position - shooter.global_position).normalized()
		_stick(JOY_AXIS_RIGHT_X, aim.x)
		_stick(JOY_AXIS_RIGHT_Y, aim.y)
		_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames()
	if shooter == j1:
		_mouse(false, victim.global_position)
	else:
		_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)


func _verify_shot_drop(index: int, fatal: bool) -> void:
	await _fresh()
	var victim = game.players[index]
	var shooter = game.players[1 - index]
	var origin: Vector2 = bottle.position
	victim.position = origin
	shooter.position = origin + Vector2(140, 0)
	await _frames(3)
	_check(bottle.holder == victim, "Prise par J%d avant tir, fatal=%s" % [index + 1, fatal])
	if fatal:
		victim.health = 25
	var losses: Array[Dictionary] = []
	var takes: Array = []
	var transitions: Array[String] = []
	bottle.dropped.connect(func(previous, attacker):
		losses.append({"previous": previous, "attacker": attacker,
			"state": bottle.get_state()})
		transitions.append("loss"))
	bottle.picked_up.connect(func(next):
		takes.append(next)
		transitions.append("take"))
	await _fire_at(shooter, victim)
	for frame in range(20):
		if not losses.is_empty():
			break
		await _frames()
	_check(losses.size() == 1 and bottle.holder == null,
		"Un projectile cause exactement une perte de J%d, fatal=%s" % [index + 1, fatal])
	if losses.is_empty():
		return
	_check(losses[0].previous == victim and losses[0].attacker == shooter
		and losses[0].state.holder == null,
		"Événement de perte : ancien porteur et tireur corrects, état déjà libéré")
	_check(victim.is_ghost() if fatal else victim.health == 75,
		"Le tir applique ses dégâts et le cas fatal passe en fantôme")
	var at_loss: Dictionary = losses[0].state
	# Move the shooter after impact: the captured throw direction must stay fixed.
	shooter.position = origin + Vector2(0, -140)
	victim.position = origin + Vector2(-100, 0)
	await _frames(20)
	_check(bottle.position.distance_to(origin + Vector2(bottle.throw_distance, 0)) < 0.25
		and bottle.velocity.is_zero_approx(),
		"Projection vers la position du tireur à l’impact, sans poursuite ultérieure")
	_check(bottle.remaining == at_loss.remaining and bottle.scores == at_loss.scores,
		"Aucune consommation au sol, scores conservés après le tir")
	victim.take_damage(1, shooter)
	_check(losses.size() == 1, "Un dégât supplémentaire sans possession ne répète pas la perte")
	if not fatal:
		await _capture("j%d-bottle-dropped" % (index + 1))
	shooter.position = bottle.position
	await _frames(3)
	_check(bottle.holder == shooter and takes == [shooter]
		and transitions == ["loss", "take"] and bottle.velocity.is_zero_approx(),
		"Le tireur récupère : une prise distincte de la perte, projection interrompue")
	await _frames(4)
	_check(bottle.scores[shooter.player_number] > at_loss.scores[shooter.player_number]
		and bottle.scores[victim.player_number] == at_loss.scores[victim.player_number],
		"Seul le nouveau porteur boit après récupération")


func _verify_recovery_window() -> void:
	await _fresh()
	for player in game.players:
		player.set_physics_process(false)
	bottle.set_physics_process(false)
	bottle.throw_distance = 0.0
	j1.position = bottle.position
	j2.position = bottle.position + Vector2(100, 0)
	bottle._try_pickup()
	j1.take_damage(0, j2)
	_check(bottle.holder == j1, "Une attaque sans dégât ne fait pas perdre la bouteille")
	j1.take_damage(25, j2)
	j1._physics_process(0.10)
	bottle._physics_process(0.10)
	_check(bottle.holder == null, "L’ancien porteur reste exclu après un court instant")
	j2.position = bottle.position
	bottle._try_pickup()
	_check(bottle.holder == j2, "Un autre actif peut ramasser immédiatement pendant le délai")
	j2.take_damage(25, j1)
	bottle._try_pickup()
	_check(bottle.holder == null, "Un échange rapide ne supprime pas le délai du premier porteur")
	j1._physics_process(0.34)
	j2._physics_process(0.34)
	bottle._physics_process(0.34)
	_check(bottle.holder == null, "Chaque ancien porteur attend son propre délai complet")
	j1._physics_process(0.02)
	j2._physics_process(0.02)
	bottle._physics_process(0.02)
	_check(bottle.holder == null, "L’étourdissement bloque encore la reprise après les 0,45 s d’exclusion")
	var until_recovery: float = bottle.holder_stun_duration - 0.46
	j1._physics_process(until_recovery)
	j2._physics_process(until_recovery)
	bottle._physics_process(until_recovery)
	_check(bottle.holder == j1, "Le premier porteur peut reprendre à la fin de son étourdissement, avant le second")
	_check(bottle.remaining == bottle.total_amount,
		"Les prises et pertes rapprochées ne consomment pas deux fois")
	# An authorized opponent can intercept before the throw has finished.
	await _fresh()
	for player in game.players:
		player.set_physics_process(false)
	bottle.set_physics_process(false)
	j1.position = bottle.position
	j2.position = bottle.position + Vector2(10, 0)
	bottle._try_pickup()
	j1.take_damage(25, j2)
	bottle._physics_process(0.01)
	_check(bottle.holder == j2 and bottle.velocity.is_zero_approx(),
		"L’autre actif peut intercepter la bouteille dès le début de la projection")
	_check(bottle.remaining == bottle.total_amount,
		"L’interception ne consomme pas avant la première étape de possession")
	await _fresh()
	await _hold_with_j1()
	j1.take_damage(25, j2)
	var point: Vector2 = bottle.position
	var amount: int = bottle.remaining
	game.pause_match()
	await _frames(40)
	_check(bottle.position == point and bottle.remaining == amount and bottle.holder == null,
		"Une pause fige aussi la projection et la récupération au sol")
	game.resume_match()
	await _frames(2)
	_check(bottle.position.x > point.x and bottle.remaining == amount,
		"La projection reprend après la pause sans consommation au sol")


func _verify_generous_pickup() -> void:
	await _fresh()
	for player in game.players:
		player.set_physics_process(false)
	bottle.set_physics_process(false)
	var origin: Vector2 = bottle.position
	j1.position = origin + Vector2(24,12)
	j2.position = origin + Vector2(100,0)
	bottle._try_pickup()
	_check(bottle.holder == j1, "Ramassage facilité : frôler la bouteille en diagonale suffit")
	bottle.configure(game.players, origin)
	j1.position = origin + Vector2(36,0)
	bottle._try_pickup()
	_check(bottle.holder == null, "La portée élargie reste locale : pas de prise à 36 unités")
	j1.position = origin + Vector2(24,0)
	j1.stun(0.8)
	bottle._try_pickup()
	_check(bottle.holder == null, "La zone élargie ne contourne pas l’étourdissement")
	j1.reset_combat()
	j1.take_damage(100, j2)
	bottle._try_pickup()
	_check(bottle.holder == null, "La zone élargie ne permet pas au fantôme de ramasser")
	j1.reset_combat()
	j2.position = origin + Vector2(-20,0)
	bottle._try_pickup()
	_check(bottle.holder == j2, "Dans la zone élargie, le personnage le plus proche reste prioritaire")
	bottle.configure(game.players, origin)
	j2.position = origin + Vector2(100,0)
	_wall(origin + Vector2(12,0))
	await _frames(2)
	bottle._try_pickup()
	_check(bottle.holder == null, "La portée élargie ne ramasse pas à travers un mur fin")


func _project_on_map(feet: Vector2, direction: Vector2, name: String, full_throw := false) -> void:
	var offset: Vector2 = j1.get_node("CollisionShape2D").position
	var origin := feet - offset
	for player in game.players:
		player.reset_combat()
	j1.position = origin
	j2.position = origin + direction * (bottle.throw_distance + 100.0)
	bottle.configure(game.players, origin)
	bottle._try_pickup()
	j1.take_damage(1, j2)
	j1.position = origin - direction * (bottle.throw_distance + 100.0)
	bottle._physics_process(0.5)
	var end_feet: Vector2 = bottle.position + offset
	var accessible := _clear_feet(end_feet)
	var segments := maxi(1, ceili(feet.distance_to(end_feet) / 3.0))
	for step in range(segments + 1):
		accessible = accessible and _clear_feet(feet.lerp(end_feet, float(step) / segments))
	_check(accessible and Geometry2D.is_point_in_polygon(end_feet,
		game.arena.polygon_points(game.arena.layout.perimeter)),
		"Chute accessible avec le gabarit des personnages : " + name)
	_check(bottle.holder == null and bottle.remaining == bottle.total_amount
		and bottle.velocity.is_zero_approx(), "Arrêt au sol, sans consommation : " + name)
	if full_throw:
		_check(end_feet.distance_to(feet) >= 89.75
			and end_feet.distance_to(feet) <= bottle.throw_distance + 0.25,
			"La bouteille traverse au moins les 90 unités de l’ouverture libre : " + name)
	j2.position = bottle.position
	bottle._try_pickup()
	_check(bottle.holder == j2, "Récupération après chute près du décor : " + name)
	map_cases += 1


func _verify_map_geometry() -> void:
	await _fresh()
	for player in game.players:
		player.set_physics_process(false)
	bottle.set_physics_process(false)
	var perimeter: PackedVector2Array = game.arena.polygon_points(game.arena.layout.perimeter)
	for wall in game.arena.layout.walls:
		var rect: Rect2 = game.arena.tile_rect(wall.rect)
		var normal := Vector2.RIGHT if rect.size.y > rect.size.x else Vector2.DOWN
		var half := rect.size.x / 2.0 if normal == Vector2.RIGHT else rect.size.y / 2.0
		for side in [-1.0, 1.0]:
			var feet: Vector2 = rect.get_center() + normal * side * (half + 10.0)
			if not _clear_feet(feet) or not Geometry2D.is_point_in_polygon(feet, perimeter):
				continue
			_project_on_map(feet, -normal * side, "%s / %s" % [wall.id, side])
	_check(map_cases >= 40, "Au moins 40 chutes près des murs, clôtures et bords réels")
	for passage in [
		["saloon-est", Vector2(500, 520), Vector2.RIGHT],
		["saloon-nord", Vector2(328, 304), Vector2.UP],
		["épicerie-ouest", Vector2(900, 536), Vector2.LEFT],
		["remise-nord", Vector2(256, 760), Vector2.UP],
		["enclos-ouest", Vector2(1090, 224), Vector2.LEFT]]:
		_check(_clear_feet(passage[1]), "Départ libre dans le passage " + passage[0])
		_project_on_map(passage[1], passage[2], passage[0], true)


func _run() -> void:
	if output_dir == OUTPUT_DIR:
		output_dir = DROPS_OUTPUT
	change_scene_to_file("res://scenes/match/match.tscn")
	await _frames(3)
	_bind_game()
	for index in range(2):
		await _verify_shot_drop(index, false)
		await _verify_shot_drop(index, true)
	await _verify_recovery_window()
	await _verify_generous_pickup()
	await _verify_map_geometry()
	print("MAP DROP CASES: ", map_cases)
	await _finish_report("BOTTLE DROPS")
