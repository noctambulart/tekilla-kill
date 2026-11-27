extends "res://tools/verify_v03.gd"
## Producer review: visible debris size and muzzle obstruction at close range.


func _initialize() -> void:
	output_dir = "res://../output/gameplay/2026-11-27-v03-review"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence="):
			output_dir = argument.trim_prefix("--evidence=")
	create_timer(90).timeout.connect(func(): quit(2))
	_run.call_deferred()


func _sandbox() -> void:
	await super._sandbox()
	# These frozen review fixtures also render when macOS hides the test window.
	# Keep the public game's focus-loss pause unchanged.
	for connection in root.get_signal_connection_list("focus_exited"):
		if connection.callable.get_object() == game:
			root.disconnect("focus_exited", connection.callable)
	game.resume_match()
	await _frames(2)


func _verify_close_obstruction() -> void:
	await _sandbox()
	_wall(CENTER + Vector2(24,0))
	await _frames(2)
	var hits: Array = []
	j1.weapon.melee_struck.connect(func(target): hits.append(target))
	j1.weapon.advance(0.25, true, true, true)
	_check(j1.weapon.ammunition == 6 and hits.size() == 1,
		"Mur interceptant le tir à 24 unités : crosse sans cartouche")
	await _capture("wall-melee")
	await _sandbox()
	var prop = _prop("crate", CENTER + Vector2(24,16))
	await _frames(2)
	hits = []
	j1.weapon.melee_struck.connect(func(target): hits.append(target))
	j1.weapon.advance(0.25, true, true, true)
	_check(j1.weapon.ammunition == 6 and hits.size() == 1,
		"Caisse interceptant le tir au contact : crosse sans cartouche")
	_check(prop.health == 100, "La crosse retire les mêmes 25 points qu’une balle à la caisse")
	await _capture("crate-melee")
	j1.weapon.advance(0.23, true, false, true)
	_check(prop.health == 100, "La crosse contre le décor respecte la cadence de 0,24 s")
	j1.weapon.advance(0.011, true, false, true)
	_check(prop.health == 75, "Maintenir le tir répète la crosse contre le décor")
	for hit in range(3):
		j1.weapon.advance(0.25, true, false, true)
	_check(prop.broken and j1.weapon.ammunition == 6, "Cinq crosses cassent la caisse sans munition")
	await _frames(2)
	j1.weapon.advance(0.25, true, false, true)
	_check(j1.weapon.ammunition == 5, "Le maintien reprend le tir quand les débris ne l’interceptent plus")
	await _sandbox()
	_wall(CENTER + Vector2(24,0))
	await _frames(2)
	j1.weapon.ammunition = 0
	j1.weapon.advance(0.0, false, false, true, true)
	j1.weapon.advance(0.01, true, true, true)
	_check(not j1.weapon.is_reloading() and j1._melee_flash > 0.0 and j1.weapon.ammunition == 0,
		"Mur : une crosse à vide interrompt la recharge sur nouvel appui")
	await _sandbox()
	_prop("pot", CENTER + Vector2(24,45))
	await _frames(2)
	j1.weapon.advance(0.25, true, true, true)
	_check(j1.weapon.ammunition == 5, "Un pot proche hors du trajet de tir ne déclenche pas la crosse")
	await _sandbox()
	_wall(CENTER + Vector2(45,0))
	await _frames(2)
	j1.weapon.advance(0.25, true, true, true)
	_check(j1.weapon.ammunition == 5, "Un mur au-delà de 30 unités laisse partir le tir")
	await _sandbox()
	j2.position = CENTER + Vector2(25,0)
	_wall(CENTER + Vector2(29,0))
	await _frames(2)
	j1.weapon.advance(0.25, true, true, true)
	_check(j2.health == 75 and j1.weapon.ammunition == 6,
		"Un adversaire devant le mur reste la cible de la crosse")
	await _sandbox()
	j2.position = CENTER + Vector2(25,0)
	_wall(CENTER + Vector2(12,0))
	await _frames(2)
	j1.weapon.advance(0.25, true, true, true)
	_check(j2.health == 100 and j1.weapon.ammunition == 6,
		"Le mur reçoit la crosse sans toucher l’adversaire derrière")


func _measure_objects() -> void:
	await _sandbox()
	for id in ["street-crate", "shop-pot", "saloon-west-n", "saloon-west-w", "saloon-west-e"]:
		var prop: Node2D = game.arena.prop_nodes[id]
		var art: Sprite2D = prop.get_node("Art")
		var before := Vector2(art.texture.get_image().get_used_rect().size) * art.scale
		var rect := art.texture.get_image().get_used_rect()
		var bottom := art.position.y + (rect.end.y - art.texture.get_height() / 2.0) * art.scale.y
		j1.position = prop.position + Vector2(-45,-16)
		j2.position = prop.position + Vector2(60,-16)
		bottle.position = prop.position + Vector2(-60,40)
		await _frames(2)
		await _capture(id + "-intact")
		for child in prop.get_children():
			if child.has_method("take_damage"):
				child.take_damage(1000, j1)
		var after := Vector2(art.texture.get_image().get_used_rect().size) * art.scale
		_check(maxf(after.x, after.y) >= maxf(before.x, before.y) - 0.01
			and after.x * after.y >= before.x * before.y - 0.01,
			"Taille globale conservée : %s · %s → %s" % [id, before, after])
		rect = art.texture.get_image().get_used_rect()
		var new_bottom := art.position.y + (rect.end.y - art.texture.get_height() / 2.0) * art.scale.y
		_check(absf(bottom - new_bottom) < 0.01 and is_equal_approx(art.scale.x, art.scale.y),
			"Appui au sol et proportions conservés : " + id)
		await _frames(2)
		await _capture(id + "-broken")


func _run() -> void:
	change_scene_to_file("res://scenes/match/match.tscn")
	await _frames(4)
	_bind_game()
	await _verify_close_obstruction()
	await _measure_objects()
	await _finish_report("V03 REVIEW")
