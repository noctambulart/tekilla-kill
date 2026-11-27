extends "res://tools/verify_v02.gd"
## Short visual/audio review fixture. The unchanged full round is in verify_v02.

func _run() -> void:
	change_scene_to_file("res://scenes/match/match.tscn")
	await _frames(4)
	_bind_game()
	game.countdown_left = 0.01
	await _frames(3)
	j2.controls.set_physics_process(false)
	j2.stop_movement()
	var center: Vector2 = bottle.position
	j1.position = center - Vector2(100,0)
	j2.position = center + Vector2(130,0)
	await _frames(60)
	j1.position = center
	bottle.configure(game.players, center)
	# A documented accumulated-score fixture makes the approved high tier visible.
	bottle.scores = {1:840,2:0}
	bottle.remaining = bottle.total_amount - 840
	await _frames(120)
	j2.controls._aim = Vector2.LEFT
	j2.controls._fire_press = true
	j2.controls._fire = true
	await _frames()
	j2.controls._fire = false
	await _frames(65)
	j2.position = bottle.position + Vector2(20,0)
	j2.controls._movement = Vector2.LEFT
	await _frames(8)
	j2.controls._movement = Vector2.ZERO
	await _frames(60)
	j1.take_damage(j1.health, j2)
	await _frames(90)
	# Shorten only the final gallery sip; conserve the original total exactly.
	bottle.remaining = 60
	bottle.scores[2] = bottle.total_amount - bottle.scores[1] - bottle.remaining
	await _frames(150)
	print("V02 PREVIEW: cues=",game.presentation.cue_counts," scores=",bottle.scores)
	current_scene.queue_free()
	current_scene = null
	await _frames(2)
	OS.delay_msec(100)
	quit()
