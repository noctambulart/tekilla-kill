extends Control
## First autonomous cut. Timing, framing and sound remain editable for review.

signal finished

const DURATION := 50.0
const FRAME := Vector2(640, 360)
const ASSETS := "res://scenes/intro/assets/"
# start, end, illustration, initial zoom, final zoom, point of attention.
const SHOTS := [
	[0.0, 8.0, "street", 1.0, 1.055, Vector2(0.5, 0.51)],
	[8.0, 16.0, "poncho", 1.0, 1.18, Vector2(0.5, 0.49)],
	[16.0, 24.0, "garcia", 1.0, 1.22, Vector2(0.5, 0.36)],
	[24.0, 25.0, "poncho", 1.30, 1.32, Vector2(0.5, 0.54)],
	[25.0, 26.35, "poncho-gag", 1.32, 1.34, Vector2(0.5, 0.55)],
	[26.35, 28.15, "garcia-reaction", 1.32, 1.36, Vector2(0.5, 0.38)],
	[28.15, 30.0, "poncho", 1.35, 1.39, Vector2(0.5, 0.50)],
	[30.0, 34.0, "garcia", 1.50, 1.65, Vector2(0.5, 0.335)],
	[34.0, 37.0, "poncho", 1.70, 1.90, Vector2(0.5, 0.49)],
	[37.0, 39.5, "garcia", 2.0, 2.20, Vector2(0.5, 0.335)],
	[39.5, 41.0, "poncho", 2.35, 2.55, Vector2(0.5, 0.49)],
	[41.0, 42.0, "garcia", 2.70, 2.90, Vector2(0.5, 0.335)],
	[42.0, 50.0, "eye-closeup", 1.0, 1.08, Vector2(0.5, 0.55)],
]

var elapsed := 0.0
var _done := false
var _textures: Dictionary = {}
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _source := Rect2()
var _picture_size := Vector2.ONE
var _bottle: Texture2D
var exit_fade := 0.0:
	set(value):
		exit_fade = value
		queue_redraw()


func _ready() -> void:
	for shot in SHOTS:
		var key: String = shot[2]
		if not _textures.has(key):
			_textures[key] = load(ASSETS + key + ".png")
	_bottle = load(ASSETS + "bottle.png")
	_music = _make_player("music.wav", -1.0)
	_ambience = _make_player("ambience.wav", -1.0)
	$Skip.visible = not OS.get_cmdline_user_args().has("--intro-clean")
	play_from(0.0)


func _make_player(file: String, gain: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(ASSETS + file)
	player.volume_db = gain
	add_child(player)
	return player


func play_from(seconds: float) -> void:
	elapsed = clampf(seconds, 0.0, DURATION)
	_done = false
	exit_fade = 0.0
	set_process(true)
	if not OS.get_cmdline_user_args().has("--intro-mute"):
		_music.play(elapsed)
		_ambience.play(elapsed)
	queue_redraw()


func review_at(seconds: float) -> void:
	# Used by the review script: freezes a rendered frame, without playing sound.
	elapsed = clampf(seconds, 0.0, DURATION - 0.001)
	set_process(false)
	_music.stop()
	_ambience.stop()
	queue_redraw()


func _process(delta: float) -> void:
	elapsed = minf(elapsed + delta, DURATION)
	queue_redraw()
	if elapsed >= DURATION:
		finish()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var skip := false
	if event is InputEventKey:
		skip = event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]
	elif event is InputEventMouseButton:
		skip = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventJoypadButton:
		skip = event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START]
	if skip:
		get_viewport().set_input_as_handled()
		finish()


func finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	$Skip.hide()
	var transition := create_tween().set_parallel(true)
	transition.tween_property(self, "exit_fade", 1.0, 0.15)
	transition.tween_property(_music, "volume_db", -60.0, 0.15)
	transition.tween_property(_ambience, "volume_db", -60.0, 0.15)
	await transition.finished
	_music.stop()
	_ambience.stop()
	if finished.get_connections().is_empty():
		get_tree().set_meta("intro_to_title", true)
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	else:
		finished.emit()


func _draw() -> void:
	if _textures.is_empty():
		return
	var shot: Array = SHOTS[-1]
	for candidate in SHOTS:
		if elapsed < candidate[1]:
			shot = candidate
			break
	var progress := clampf((elapsed - shot[0]) / (shot[1] - shot[0]), 0.0, 1.0)
	var zoom := lerpf(shot[3], shot[4], smoothstep(0.0, 1.0, progress))
	var picture: Texture2D = _textures[shot[2]]
	_picture_size = picture.get_size()
	var crop_size := Vector2(_picture_size.x, _picture_size.x * 9.0 / 16.0) / zoom
	var focus: Vector2 = shot[5] * _picture_size
	var origin := focus - crop_size / 2.0
	origin.x = clampf(origin.x, 0.0, _picture_size.x - crop_size.x)
	origin.y = clampf(origin.y, 0.0, maxf(0.0, _picture_size.y - crop_size.y))
	_source = Rect2(origin, crop_size)
	draw_texture_rect_region(picture, Rect2(Vector2.ZERO, FRAME), _source)
	if shot[2] == "street":
		_draw_dust()
	if elapsed >= 24.0 and elapsed < 26.35:
		var nose := Vector2(0.50, 0.655 if shot[2] == "poncho-gag" else 0.59)
		var landing := _project(nose)
		var arrival := clampf((elapsed - 24.0) / 1.0, 0.0, 1.0)
		var fly_position := Vector2(-25, 80).lerp(landing, smoothstep(0.0, 1.0, arrival))
		fly_position.y += sin(elapsed * 26.0) * (1.0 - arrival) * 12.0
		_draw_fly(fly_position, arrival < 0.99)
	elif elapsed >= 28.15 and elapsed < 28.8:
		var departure := (elapsed - 28.15) / 0.65
		_draw_fly(_project(Vector2(0.50, 0.59)).lerp(Vector2(680, 30), departure), true)
	if shot[2] == "eye-closeup":
		_draw_reflection()
	var fade := maxf(exit_fade, maxf(1.0 - elapsed / 1.2, (elapsed - 49.2) / 0.8))
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, FRAME), Color(0.035, 0.018, 0.012, clampf(fade, 0, 1)))


func _project(normalized: Vector2) -> Vector2:
	return (normalized * _picture_size - _source.position) / _source.size * FRAME


func _draw_fly(at: Vector2, flying: bool) -> void:
	var p := at.round()
	var wing := 3.0 if flying and sin(elapsed * 140.0) > 0.0 else 1.0
	draw_rect(Rect2(p + Vector2(-8, -wing - 4), Vector2(6, 3)), Color(0.91, 0.82, 0.64, 0.95))
	draw_rect(Rect2(p + Vector2(2, -wing - 4), Vector2(6, 3)), Color(0.91, 0.82, 0.64, 0.95))
	draw_rect(Rect2(p + Vector2(-3, -4), Vector2(6, 7)), Color(0.055, 0.035, 0.025))
	draw_rect(Rect2(p + Vector2(-2, -5), Vector2(4, 2)), Color(0.22, 0.12, 0.08))
	for side in [-1, 1]:
		draw_line(p + Vector2(side * 2, 0), p + Vector2(side * 6, 5), Color(0.075, 0.045, 0.035), 1)


func _draw_dust() -> void:
	for i in range(34):
		var x := fposmod(i * 53.0 + elapsed * (9.0 + i % 5), 720.0) - 40.0
		var y := 253.0 + i % 8 * 10.0 + sin(elapsed + i) * 2.0
		var alpha := 0.07 + (sin(elapsed * 0.8 + i) + 1.0) * 0.025
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(12 + i % 6 * 3, 1 + i % 2)), Color(0.97, 0.76, 0.43, alpha))


func _draw_reflection() -> void:
	var reveal := smoothstep(44.8, 47.0, elapsed)
	if reveal <= 0.0:
		return
	var center := _project(Vector2(0.50, 0.55))
	var dimension := Vector2(84, 120) * (FRAME.x / _source.size.x * _picture_size.x / 640.0)
	draw_texture_rect(_bottle, Rect2(center - dimension / 2.0, dimension), false, Color(0.82, 0.88, 0.61, reveal * 0.86))
	# A restrained moving glint keeps the bottle reading as a reflection.
	var glint_alpha := sin(clampf((elapsed - 46.0) / 2.4, 0.0, 1.0) * PI) * 0.36
	draw_line(center + Vector2(-13, -31), center + Vector2(-20, -14), Color(1.0, 0.87, 0.61, glint_alpha), 2)
