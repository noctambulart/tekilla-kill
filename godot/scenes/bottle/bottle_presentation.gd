extends Node2D
## V11: independently show possession, cumulative drunkenness and real bottle levels.

const ART := preload("res://scenes/bottle/bottle_art.gd")
const STAR_REFERENCE_TIME := 1.35
const ORIGINS := [Vector2(-9,-12), Vector2(8,2), Vector2(-11,8), Vector2(3,-15),
	Vector2(10,-8), Vector2(-5,0), Vector2(1,10), Vector2(-8,-6),
	Vector2(7,-13), Vector2(-10,3), Vector2(5,6), Vector2(0,-9)]
@export var bob_speed := 4.0
@export var star_height := 1.1
@export var star_spread := 1.05
@export var star_size := 1.1
@export_range(0.25, 3.0, 0.05) var star_density := 1.35
@export_range(0.25, 2.0, 0.05, "suffix:s") var star_lifetime := 0.8
var bottle
var art = ART.new()
var clock := 0.0
var cue_counts := {"take": 0, "drop": 0, "empty": 0}
var _audio: Dictionary = {}


func configure(objective, match_root: Node) -> void:
	bottle = objective
	z_index = 2000
	for cue in cue_counts:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://scenes/bottle/assets/" + cue + ".wav")
		player.volume_db = -3.0
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		match_root.add_child(player)
		_audio[cue] = player
	bottle.picked_up.connect(func(_holder): _play("take"))
	bottle.dropped.connect(func(_previous, _attacker): _play("drop"))
	bottle.emptied.connect(func(): _play("empty"))
	bottle.state_changed.connect(func(_state): queue_redraw())


func _play(cue: String) -> void:
	cue_counts[cue] += 1
	_audio[cue].play()


func _exit_tree() -> void:
	for player in _audio.values():
		if is_instance_valid(player):
			player.stop()


func _process(delta: float) -> void:
	clock += delta
	queue_redraw()


func particle_count(player) -> int:
	if player.is_ghost() or bottle.scores.get(player.player_number, 0) == 0:
		return 0
	var fraction := clampf(float(bottle.scores[player.player_number]) / bottle.total_amount, 0.0, 1.0)
	# Keep small amounts readable, then grow throughout the whole bottle.
	return maxi(1, roundi(lerpf(4.0, 18.0, sqrt(fraction)) * star_density))


func _seed(index: int, cycle: int, channel: int) -> float:
	return fposmod(sin((index + 1) * 127.1 + (cycle + 19) * 311.7 + channel * 74.7) * 43758.5453, 1.0)


func star_flight(index: int, count: int, time: float) -> Dictionary:
	var phase := time + index * star_lifetime / count
	var cycle := floori(phase / star_lifetime)
	var age := phase - cycle * star_lifetime
	var flight_time := age * STAR_REFERENCE_TIME / star_lifetime
	var point: Vector2 = ORIGINS[posmod(index * 5 + cycle * 7, ORIGINS.size())]
	var origin := point + Vector2(_seed(index, cycle, 0) - 0.5, _seed(index, cycle, 1) - 0.5) * 2.0
	var side := signf(origin.x) if absf(origin.x) > 2.0 else (-1.0 if _seed(index, cycle, 2) < 0.5 else 1.0)
	var launch := 52.0 + minf(0.0, origin.y) * 0.7 + _seed(index, cycle, 3) * 8.0
	var spread := 17.0 + _seed(index, cycle, 4) * 12.0
	return {"origin": origin, "age": age, "point": origin + Vector2(
		side * spread * flight_time * star_spread,
		(-launch * flight_time + 55.0 * flight_time * flight_time) * star_height)}


func _star(point: Vector2, radius: float, rotation: float, alpha: float, possession := false) -> void:
	var polygon := PackedVector2Array()
	var edges := 8 if possession else 10
	for i in range(edges):
		var angle := -PI / 2.0 + i * TAU / edges + rotation
		var length := radius if i % 2 == 0 else radius * (0.22 if possession else 0.43)
		polygon.append(point + Vector2(cos(angle), sin(angle)) * length)
	if possession:
		draw_circle(point, radius * 1.7, Color(1.0, 0.85, 0.43, alpha * 0.12))
	draw_colored_polygon(polygon, Color(1.0, 0.95, 0.67, alpha))


func _draw() -> void:
	if not is_instance_valid(bottle):
		return
	var fill: float = float(bottle.remaining) / bottle.total_amount
	var camera := get_viewport().get_camera_2d()
	var zoom: float = maxf(0.1, camera.zoom.x) if camera != null else 1.0
	for player in bottle.participants:
		var count := particle_count(player)
		for i in range(count):
			var particle := star_flight(i, count, clock)
			var fade := clampf(minf((star_lifetime - particle.age) / (star_lifetime * 0.32 / STAR_REFERENCE_TIME),
				(23.0 - particle.point.y) / 9.0), 0.0, 1.0)
			var alpha := 0.92 * minf(1.0, particle.age / (star_lifetime * 0.09 / STAR_REFERENCE_TIME)) * fade
			_star(player.global_position + particle.point,
				(1.35 + (i % 3) * 0.15) * star_size,
				(-1.0 if i % 2 == 0 else 1.0) * particle.age * STAR_REFERENCE_TIME / star_lifetime * 1.6, alpha)
	if is_instance_valid(bottle.holder) and not bottle.holder.is_ghost():
		# V11 minimums are screen sizes: keep the target obvious when zooming out.
		var height := maxf(27.0, (58.0 / 3.0) / zoom)
		var bob := sin(clock * bob_speed) * maxf(3.0, (5.0 / 3.0) / zoom)
		var clearance := maxf(36.5, 18.0 / zoom)
		var point: Vector2 = bottle.holder.global_position + Vector2(0, -clearance - height / 2.0 + bob)
		art.bottle(self, point, height, fill)
		var offsets := [Vector2(-11,-5), Vector2(11,-3), Vector2(-8,7), Vector2(9,8)]
		for i in range(4):
			var alpha := 0.2 + 0.8 * pow(maxf(0.0, sin(clock * 2.2 + i * 1.55)), 2)
			_star(point + offsets[i] / zoom, maxf(3.7, (8.0 / 3.0) / zoom), 0.0, alpha, true)
	else:
		var height := maxf(32.0, 22.0 / zoom)
		var foot: Vector2 = bottle.global_position + bottle.ground_offset
		var point := foot - Vector2(0, height / 2.0 - 1.0)
		draw_circle(foot + Vector2(0, 1), maxf(6.0, (10.0 / 3.0) / zoom), Color(0.2, 0.12, 0.06, 0.2))
		art.bottle(self, point, height, fill)
		_star(point + Vector2(-height * 0.4, -height * 0.15), 2.0 / zoom, 0.0, 0.8, true)
		_star(point + Vector2(height * 0.4, height * 0.1), (5.0 / 3.0) / zoom, 0.0, 0.65, true)
