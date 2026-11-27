extends SceneTree
## Full village: test ground footprints, all doors and loops with real bodies.

const OUTPUT := "res://../output/arena/2026-11-25-village-v6/"
const FOOT := Vector2(0, 16)
var checks := 0
var failures: Array[String] = []
var folder := ""
var space: PhysicsDirectSpaceState2D
var query := PhysicsShapeQueryParameters2D.new()
var last_block := ""
var connectivity: Dictionary = {}


func _initialize() -> void:
	folder = ProjectSettings.globalize_path(OUTPUT)
	create_timer(60).timeout.connect(func():
		push_error("Village verification timed out")
		quit(2))
	_run.call_deferred()


func _frames(count := 1) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _clear(point: Vector2) -> bool:
	query.transform = Transform2D(0, point)
	var hits := space.intersect_shape(query, 1)
	if not hits.is_empty():
		last_block = "%s at %s" % [hits[0].collider.get_parent().name, point]
	return hits.is_empty()


func _path(points: Array) -> bool:
	for index in range(points.size() - 1):
		var a: Vector2 = points[index]
		var b: Vector2 = points[index + 1]
		var count := maxi(1, ceili(a.distance_to(b) / 4))
		for step in range(count + 1):
			if not _clear(a.lerp(b, float(step) / count)):
				return false
	return true


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw()
	_check(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK, "Capture " + name)


func _verify_connectivity(map) -> void:
	var free: Dictionary = {}
	var perimeter: PackedVector2Array = map.polygon_points(map.layout.perimeter)
	for y in range(16, int(map.world_size().y), 16):
		for x in range(16, int(map.world_size().x), 16):
			var point := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(point, perimeter) and _clear(point):
				free[Vector2i(x / 16, y / 16)] = true
	var start := Vector2i(44, 33)
	var pending: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	var index := 0
	while index < pending.size():
		var cell := pending[index]
		index += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if free.has(next) and not visited.has(next):
				visited[next] = true
				pending.append(next)
	var isolated: Array = []
	for cell in free:
		if not visited.has(cell):
			isolated.append(cell * 16)
	connectivity = {"step": 16, "walkable_cells": free.size(), "reachable_cells": visited.size(), "isolated": isolated}
	_check(isolated.is_empty(), "Toutes les zones libres échantillonnées rejoignent la place : %s" % str(isolated.slice(0, 10)))


func _verify_house_occlusion(map: Node2D, actor: CharacterBody2D, target: CharacterBody2D) -> void:
	var actor_start := actor.position
	var target_start := target.position
	actor.stop_movement()
	actor.set_physics_process(false)
	target.set_physics_process(false)
	target.position = Vector2(704, 520)
	for house in map.house_nodes:
		var art: Sprite2D = house.get_node("Art")
		var size := Vector2(art.texture.get_size()) * art.scale
		# Twelve units beyond the facade, left of the steps: clearance for the body radius.
		var front: Vector2 = house.global_position + Vector2(-size.x * 0.3, -24)
		_check(_clear(front + FOOT), "Position libre devant la façade : " + house.name)
		actor.global_position = front
		art.modulate.a = 1.0
		await _frames(12)
		_check(is_equal_approx(art.modulate.a, 1.0), "Maison opaque lorsque le personnage est devant : " + house.name)
		_check(actor.z_index >= house.z_index, "Personnage devant la façade dessiné au premier plan : " + house.name)
		actor.global_position = house.global_position + Vector2(0, -size.y + 32)
		await _frames(12)
		_check(actor.z_index < house.z_index and art.modulate.a < 0.95,
			"Atténuation derrière le toit : " + house.name)
		actor.global_position = front
		await _frames(12)
		_check(is_equal_approx(art.modulate.a, 1.0), "Retour opaque en repassant devant : " + house.name)
	actor.position = actor_start
	target.position = target_start
	actor.set_physics_process(true)
	target.set_physics_process(true)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1920, 1080)
	set_meta("intro_to_title", true)
	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	current_scene.start_arena_review()
	await _frames(4)
	var review = current_scene
	var map = review.arena
	var actor = review.explorer
	_check(map.layout.version == 6 and map.world_size() == Vector2(1440, 960), "Village V6 complet aux proportions recalées")
	_check(map.layout.rooms.size() == 4, "Saloon, épicerie, remise et enclos")
	_check(actor.get_node("Visual").warm_art, "Palette chaude dans la visite")
	_check(actor.get_node("CollisionShape2D").position == FOOT, "Visite avec collision aux pieds")
	space = map.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 8
	query.shape = shape
	query.collision_mask = 1
	var bottle: Vector2 = map.tile_point(map.layout.bottle)
	var distance: float = map.tile_point(map.layout.spawns[0]).distance_to(bottle)
	for index in range(map.layout.spawns.size()):
		var spawn: Vector2 = map.tile_point(map.layout.spawns[index])
		_check(_clear(spawn + FOOT), "Départ libre J%d" % (index + 1) + (" / " + last_block if not _clear(spawn + FOOT) else ""))
		_check(is_equal_approx(spawn.distance_to(bottle), distance), "Départ équidistant J%d" % (index + 1))
		_check(_path([spawn + FOOT, bottle + FOOT]), "Accès direct au centre J%d / %s" % [index + 1, last_block])
	for route in map.layout.routes:
		var points: Array = []
		for p in route.points:
			points.append(map.tile_point(p))
		var free := _path(points)
		_check(free, "Parcours complet : %s%s" % [route.name, " / " + last_block if not free else ""])
	for room in map.layout.rooms:
		var r: Rect2 = map.rect_from(room.rect)
		_check(room.doors.size() >= 2, "Plusieurs accès : " + room.name)
		for side in room.doors:
			var opening: Array = room.doors[side]
			var middle := (float(opening[0]) + float(opening[1])) / 2
			var horizontal: bool = side in ["north", "south"]
			var center := Vector2(middle, r.position.y if side == "north" else r.end.y) if horizontal else Vector2(r.position.x if side == "west" else r.end.x, middle)
			var normal := Vector2.DOWN if horizontal else Vector2.RIGHT
			var tangent := Vector2.RIGHT if horizontal else Vector2.DOWN
			var free := true
			for offset in [-16, 0, 16]:
				free = free and _path([center + tangent * offset - normal * 32, center + tangent * offset + normal * 32])
			_check(free, "Seuil large : %s / %s%s" % [room.name, side, " / " + last_block if not free else ""])
	var houses := 0
	for data in map.layout.props:
		var prop: Node2D = map.prop_nodes[data.id]
		var art: Sprite2D = prop.get_node("Art")
		_check(is_zero_approx(art.rotation) and is_equal_approx(art.scale.x, art.scale.y), "Sprite sans déformation : " + data.id)
		if data.kind == "house" or data.kind.begins_with("house_"):
			houses += 1
			var width := art.texture.get_width() * art.scale.x
			var height := art.texture.get_height() * art.scale.y
			var top_left: Vector2 = map.tile_point(data.position)
			_check(_clear(top_left + Vector2(4, height + 2)) and _clear(top_left + Vector2(width - 4, height + 2)), "Coins transparents libres : " + data.id)
			var free := _path([top_left + Vector2(4, height + 24), top_left + Vector2(4, 40)])
			_check(free, "Marge et débord de toit : " + data.id + (" / " + last_block if not free else ""))
	_check(houses == 4, "Quatre maisons fermées à échelle humaine")
	_verify_connectivity(map)
	_check(not _clear(Vector2(80, 480)), "Mur du saloon solide")
	actor.stop_movement()
	actor.position = Vector2(552, 496)
	_key(KEY_A, true)
	await _frames(25)
	_key(KEY_A, false)
	await _frames(9)
	_check(actor.position.x < 510, "Entrée réelle au clavier dans le saloon")
	actor.stop_movement()
	actor.position = Vector2(104, 480)
	_key(KEY_A, true)
	await _frames(22)
	_key(KEY_A, false)
	await _frames(9)
	_check(absf(actor.position.x - 94) < 1, "Arrêt réel sur le pied du mur")
	review.return_to_title()
	await _frames(3)
	current_scene.start_solo_trial()
	await _frames(4)
	var trial = current_scene
	map = trial.arena
	actor = trial.explorer
	var target = trial.target
	_check(trial.arena.layout.version == 6 and target.stationary, "Carte complète intégrée à l’essai solo")
	_check(target.get_node("Visual").warm_art and target.get_node("CollisionShape2D").position == FOOT, "Garcia : palette et ancrage validés")
	var point: Vector2 = root.get_final_transform() * (root.get_canvas_transform() * target.global_position)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await _frames(2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = point
	click.pressed = true
	Input.parse_input_event(click)
	await _frames(1)
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await _frames(24)
	_check(target.health == 75 and actor.weapon.ammunition == 5, "Tir réel à travers la façade ouverte : cible%d, munitions%d" % [target.health, actor.weapon.ammunition])
	_check(actor.health == 100, "Le projectile ignore la silhouette de son tireur")
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _frames(26)
	_check(actor.weapon.ammunition == 6, "Recharge préservée")
	actor.stop_movement()
	actor.position = bottle - Vector2(60, 0)
	_key(KEY_D, true)
	await _frames(5)
	_key(KEY_SPACE, true)
	await _frames(1)
	_check(actor.is_dashing(), "Dash réel sur la place du village")
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	trial.reset_trial()
	_check(actor.position.is_equal_approx(trial.arena.tile_point(trial.arena.layout.spawns[3])), "Retour au départ V6")
	trial.set_overview(true)
	await _frames(3)
	await _capture("village-overview")
	trial.set_process(false)
	trial.camera.zoom = Vector2.ONE * 0.9
	for view in [
		["saloon-in-game", Vector2(360, 448), Vector2(416, 488), Vector2(704, 520)],
		["shop-in-game", Vector2(1064, 520), Vector2(968, 520), Vector2(1080, 520)],
		["shed-in-game", Vector2(288, 768), Vector2(256, 800), Vector2(440, 800)],
		["yard-in-game", Vector2(1168, 224), Vector2(1160, 224), Vector2(1240, 224)],
		["houses-in-game", Vector2(336, 144), Vector2(216, 205), Vector2(376, 220)],
	]:
		trial.camera.position = view[1]
		actor.stop_movement()
		actor.position = view[2]
		target.position = view[3]
		await _frames(3)
		await _capture(view[0])
	actor.stop_movement()
	actor.position = Vector2(216, 80)
	trial.camera.position = Vector2(240, 144)
	trial.camera.zoom = Vector2.ONE * 1.1
	await _frames(18)
	_check(map.prop_nodes["home-west"].get_node("Art").modulate.a < 0.95, "Personnage lisible derrière le toit")
	await _capture("roof-passage")
	await _verify_house_occlusion(map, actor, target)
	if DisplayServer.get_name() != "headless":
		actor.set_physics_process(false)
		target.set_physics_process(false)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(map.world_size()) + Vector2i(32, 32)
		viewport.disable_3d = true
		viewport.world_2d = World2D.new()
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var clean = load("res://scenes/arroyo_seco/arroyo_seco.tscn").instantiate()
		clean.position = Vector2(16, 16)
		viewport.add_child(clean)
		await _frames(4)
		RenderingServer.force_draw()
		_check(viewport.get_texture().get_image().save_png(folder.path_join("village-map-native.png")) == OK, "Carte complète sans HUD rendue par Godot")
		viewport.queue_free()
	trial.return_to_title()
	await _frames(3)
	current_scene.start_match()
	await _frames(4)
	_check(current_scene.arena.layout.version == 6 and current_scene.players[0].get_node("Visual").warm_art, "Même carte et personnages dans la partie existante")
	var report := {"checks": checks, "failures": failures, "rendered": DisplayServer.get_name() != "headless",
		"connectivity": connectivity,
		"scope": "Village V6 entier, passages et marges aux pieds, scènes réelles et combat conservé. Validation créative et équilibrage à essayer."}
	var file := FileAccess.open(folder.path_join("verification-village.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("VILLAGE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
