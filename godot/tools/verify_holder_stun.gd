extends "res://tools/verify_match.gd"
## Approved balancing trial: partial stun on bottle loss, never invulnerability.


func _bind_game() -> void:
	super._bind_game()
	_ignore_external_focus()


func _ignore_external_focus() -> void:
	# Native automation must keep running if the producer uses another window.
	# Explicit pause is tested below; focus-triggered pause remains in verify_match.
	var handler: Callable = game.pause_match.bind("Fenêtre inactive")
	if root.focus_exited.is_connected(handler):
		root.focus_exited.disconnect(handler)
	if DisplayServer.get_name() != "headless":
		root.grab_focus()
	if paused:
		game.resume_match()


func _move(index: int, held: bool) -> void:
	if index == 0:
		_key(KEY_D, held)
	else:
		_stick(JOY_AXIS_LEFT_X, 1.0 if held else 0.0)


func _dash(index: int, held: bool) -> void:
	if index == 0:
		_key(KEY_SPACE, held)
	else:
		_stick(JOY_AXIS_TRIGGER_LEFT, 1.0 if held else 0.0)


func _fire_up(index: int, held: bool) -> void:
	if index == 0:
		_mouse(held, j1.position + Vector2(0, -100))
	else:
		_stick(JOY_AXIS_RIGHT_Y, -1.0)
		_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0 if held else 0.0)


func _reload(index: int) -> void:
	if index == 0:
		_key(KEY_R, true)
		_key(KEY_R, false)
	else:
		_joy_button(JOY_BUTTON_X, true)
		_joy_button(JOY_BUTTON_X, false)


func _arrange(index: int) -> void:
	await _fresh()
	var victim = game.players[index]
	var attacker = game.players[1 - index]
	victim.position = bottle.position
	attacker.position = bottle.position + Vector2(280, 0)
	await _frames(3)
	_check(bottle.holder == victim, "J%d porte avant le choc" % (index + 1))


func _verify_controls(index: int) -> void:
	await _arrange(index)
	var victim = game.players[index]
	var attacker = game.players[1 - index]
	_move(index, true)
	await _frames(4)
	_dash(index, true)
	await _frames()
	_check(victim.is_dashing(), "J%d est en dash avant le choc" % (index + 1))
	victim.take_damage(25, attacker)
	var point: Vector2 = victim.position
	_check(victim.is_stunned() and not victim.is_dashing()
		and victim.velocity.is_zero_approx() and victim.is_active(),
		"Le choc interrompt le dash de J%d, encore actif et vulnérable" % (index + 1))
	_dash(index, false)
	_fire_up(index, true)
	await _frames()
	_fire_up(index, false)
	_check(victim.weapon.ammunition == 5 and victim.aim_direction.dot(Vector2.UP) > 0.99,
		"J%d peut viser et tirer pendant l’étourdissement" % (index + 1))
	_reload(index)
	_dash(index, true)
	await _frames()
	_check(victim.weapon.is_reloading() and not victim.is_dashing(),
		"J%d peut commencer une recharge, sans nouveau dash" % (index + 1))
	await _frames(25)
	_check(victim.is_stunned() and victim.position.distance_to(point) < 0.01
		and victim.weapon.ammunition == 6,
		"J%d reste immobile malgré le déplacement maintenu ; sa cartouche arrive" % (index + 1))
	victim.take_damage(1, attacker)
	_check(victim.health == 74, "J%d reste blessable pendant l’étourdissement" % (index + 1))
	await _frames(ceili(bottle.holder_stun_duration * 60.0) - 27 + 3)
	_check(not victim.is_stunned() and victim.position.x > point.x
		and not victim.is_dashing(),
		"J%d reprend le déplacement sans dash mis en attente ni prolongation au second dégât" % (index + 1))
	await _arrange(index)
	victim = game.players[index]
	attacker = game.players[1 - index]
	victim.weapon.ammunition = 3
	_reload(index)
	await _frames(4)
	var progress: float = victim.weapon.reload_progress()
	victim.take_damage(25, attacker)
	_check(victim.weapon.is_reloading() and victim.weapon.reload_progress() == progress,
		"J%d conserve la recharge déjà engagée et son horloge au choc" % (index + 1))
	await _frames(21)
	_check(victim.is_stunned() and victim.weapon.ammunition == 4,
		"La recharge engagée de J%d progresse pendant l’étourdissement" % (index + 1))
	victim.take_damage(100, attacker)
	_check(victim.is_ghost() and not victim.is_stunned(),
		"Un coup fatal pendant l’étourdissement de J%d libère le mouvement du fantôme" % (index + 1))
	await _fresh()
	_check(not game.players[index].is_stunned(), "Rejouer efface l’étourdissement de J%d" % (index + 1))


func _verify_boundary(index: int) -> void:
	await _arrange(index)
	var victim = game.players[index]
	var attacker = game.players[1 - index]
	for player in game.players:
		player.set_physics_process(false)
	bottle.set_physics_process(false)
	bottle.throw_distance = 0.0
	victim.take_damage(0, attacker)
	_check(not victim.is_stunned() and bottle.holder == victim, "Zéro dégât ne déclenche rien")
	attacker.take_damage(1, victim)
	_check(not attacker.is_stunned(), "Un blessé sans bouteille n’est pas étourdi")
	victim.take_damage(25, attacker)
	var before_end: float = bottle.holder_stun_duration - 0.01
	victim._physics_process(before_end)
	bottle._physics_process(before_end)
	_check(victim.is_stunned() and not victim.can_pickup_bottle() and bottle.holder == null,
		"J%d ne peut pas reprendre 0,01 s avant la fin, même bouteille à ses pieds" % (index + 1))
	# Capture a frozen fixture so rendering cannot advance the timed input case.
	await _capture("j%d-stunned" % (index + 1))
	victim._physics_process(0.01)
	bottle._physics_process(0.01)
	_check(not victim.is_stunned() and bottle.holder == victim,
		"J%d peut reprendre dès la fin de l’étourdissement, sans exclusion d’une seconde" % (index + 1))
	victim.take_damage(100, attacker)
	_check(victim.is_ghost() and not victim.is_stunned() and bottle.holder == null,
		"Le coup fatal de J%d donne priorité au mode fantôme" % (index + 1))
	_move(index, true)
	await _frames()
	var point: Vector2 = victim.position
	victim._physics_process(0.1)
	_check(victim.position.x > point.x and not victim.can_pickup_bottle(),
		"Le fantôme reste lentement déplaçable sans ramassage")
	victim.reset_combat()
	_check(not victim.is_stunned() and victim.can_pickup_bottle(), "La remise à zéro restaure l’éligibilité")


func _verify_pause_and_bot() -> void:
	# Use the actual public composition for the bot and pause contract.
	remove_meta("match_test_two_humans")
	game.replay()
	await _frames(3)
	game = current_scene
	bottle = game.bottle
	j1 = game.players[0]
	j2 = game.players[1]
	_ignore_external_focus()
	game.countdown_left = 0.01
	await _frames(3)
	j2.position = bottle.position
	j1.position = bottle.position + Vector2(280, 0)
	await _frames(3)
	_check(bottle.holder == j2, "Garcia bot ramasse dans la composition publique")
	j2.take_damage(25, j1)
	var point: Vector2 = j2.position
	var remaining: float = j2._stun_time_left
	game.pause_match()
	await _frames(40)
	_check(j2.is_stunned() and j2._stun_time_left == remaining and j2.position == point,
		"La pause conserve exactement le temps d’étourdissement du bot")
	game.resume_match()
	await _frames(20)
	_check(j2.is_stunned() and j2.position == point and j2.controls.movement().length() > 0,
		"Garcia bot reste immobile malgré son intention de poursuivre la bouteille")
	await _frames(ceili(bottle.holder_stun_duration * 60.0) - 20 + 5)
	_check(not j2.is_stunned() and j2.position.distance_to(point) > 1,
		"Garcia bot reprend sa poursuite après l’étourdissement")


func _run() -> void:
	create_timer(60).timeout.connect(func():
		push_error("HOLDER STUN: timeout")
		quit(2))
	if output_dir == OUTPUT_DIR:
		output_dir = "res://../output/gameplay/2026-11-27-v02-stun-v3/stun"
	change_scene_to_file("res://scenes/match/match.tscn")
	await _frames(3)
	_bind_game()
	_check(bottle.throw_distance == 150.0 and bottle.throw_duration == 0.22
		and bottle.holder_stun_duration == 0.8, "Réglages publics : 150 unités / 0,22 s et étourdissement 0,8 s")
	for index in range(2):
		await _verify_controls(index)
		await _verify_boundary(index)
	await _verify_pause_and_bot()
	await _finish_report("HOLDER STUN")
