extends Node2D
## Public v0.3 round; keep two-human fixtures available to the mechanics checks.

const ARENA := preload("res://scenes/arroyo_seco/arroyo_seco.tscn")
const CHARACTER := preload("res://scenes/character/character.tscn")
const BOTTLE := preload("res://scenes/bottle/bottle.gd")
const FRAMING := preload("res://scenes/camera/group_framing.gd")
const BOT := preload("res://scenes/character/bot_controls.gd")
const NAVIGATION := preload("res://scenes/match/arena_navigation.gd")
const PRESENTATION := preload("res://scenes/bottle/bottle_presentation.gd")
const RESERVE := preload("res://scenes/bottle/reserve_indicator.gd")
enum Phase { COUNTDOWN, PLAYING, FINISHED }

@export_range(0.0, 5.0) var countdown_duration := 3.0
@export var bot_enabled := true

var phase := Phase.COUNTDOWN
var countdown_left := 0.0
var world: Node2D
var arena
var bottle
var players: Array = []
var camera: Camera2D
var overlay: PanelContainer
var announcement: Label
var details: Label
var resume_button: Button
var replay_button: Button
var status: Label
var help: Label
var player_labels: Array[Label] = []
var navigation
var presentation
var reserve: Control
var device_button: Button
var result_title_button: Button
var overview := false
var _previous_aspect: Window.ContentScaleAspect
var _previous_stretch: Window.ContentScaleStretch
var _paths_ready := false


func _enter_tree() -> void:
	if get_tree().has_meta("match_test_two_humans"):
		bot_enabled = false
	if bot_enabled:
		_previous_aspect = get_window().content_scale_aspect
		_previous_stretch = get_window().content_scale_stretch
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


func _exit_tree() -> void:
	if bot_enabled:
		get_window().content_scale_aspect = _previous_aspect
		get_window().content_scale_stretch = _previous_stretch


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	# Keep the map's static collision bodies registered during the countdown.
	world.process_mode = Node.PROCESS_MODE_PAUSABLE if bot_enabled else Node.PROCESS_MODE_DISABLED
	add_child(world)
	arena = ARENA.instantiate()
	arena.show_bottle_marker = false
	world.add_child(arena)
	for index in range(2):
		var player = CHARACTER.instantiate()
		player.name = "J%d" % (index + 1)
		player.player_number = index + 1
		player.player_color = Color("3c879b") if index == 0 else Color("b83d2b")
		player.combat_enabled = true
		player.ghost_enabled = true
		player.position = arena.tile_point(arena.layout.spawns[3 if index == 0 else 2])
		player.aim_direction = Vector2.RIGHT if index == 0 else Vector2.LEFT
		player.get_node("HumanControls").source = index
		player.get_node("Visual").character_style = index
		if bot_enabled:
			player.process_mode = Node.PROCESS_MODE_DISABLED
		if bot_enabled and index == 1:
			var old_controls := player.get_node("HumanControls")
			player.remove_child(old_controls)
			old_controls.free()
			var bot := BOT.new()
			bot.name = "HumanControls"
			player.add_child(bot)
		world.add_child(player)
		if arena.layout.get("grounded_characters", false):
			player.use_village_art()
		players.append(player)
	bottle = BOTTLE.new()
	bottle.name = "Bottle"
	bottle.ground_offset = players[0].get_node("CollisionShape2D").position
	bottle.draw_placeholder = not bot_enabled
	if bot_enabled:
		bottle.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(bottle)
	bottle.configure(players, arena.tile_point(arena.layout.bottle))
	bottle.emptied.connect(_finish_match)
	if bot_enabled:
		navigation = NAVIGATION.new()
		players[1].controls.configure(bottle, [players[0]], navigation)
		_prepare_navigation()
		presentation = PRESENTATION.new()
		presentation.process_mode = Node.PROCESS_MODE_DISABLED
		world.add_child(presentation)
		presentation.configure(bottle, self)
	camera = Camera2D.new()
	add_child(camera)
	if bot_enabled:
		_build_round_hud()
	else:
		_build_hud()
	countdown_left = countdown_duration
	var connected := Input.get_connected_joypads()
	if bot_enabled:
		if get_tree().has_meta("poncho_joypad") and get_tree().get_meta("poncho_joypad") in connected:
			_select_device(get_tree().get_meta("poncho_joypad"))
	else:
		assign_joypad(connected[0] if not connected.is_empty() else -1)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_window().focus_exited.connect(pause_match.bind("Fenêtre inactive"))
	get_viewport().size_changed.connect(func(): _update_camera(0.0))
	_update_camera()
	_update_hud()


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if bot_enabled and not _paths_ready:
		return
	if phase == Phase.COUNTDOWN:
		countdown_left = move_toward(countdown_left, 0.0, delta)
		if is_zero_approx(countdown_left):
			phase = Phase.PLAYING
			_release_inputs()
			world.process_mode = Node.PROCESS_MODE_PAUSABLE
			if bot_enabled:
				for node in players + [bottle, presentation]:
					node.process_mode = Node.PROCESS_MODE_INHERIT


func _prepare_navigation() -> void:
	# Newly added static bodies need physics synchronization before space queries.
	# Freeze participants individually; disabling the map would remove its solids.
	for step in range(2):
		await get_tree().physics_frame
		await get_tree().process_frame
	navigation.configure(arena)
	_paths_ready = true


func _process(delta: float) -> void:
	if not get_tree().paused and phase != Phase.FINISHED:
		_update_camera(delta)
	_update_hud()


func _update_camera(delta := 0.0) -> void:
	if not is_instance_valid(camera) or not camera.is_inside_tree():
		return
	if bot_enabled:
		_update_round_camera(delta)
		return
	var points := PackedVector2Array([bottle.global_position])
	for player in players:
		points.append(player.global_position)
	var safe_area := Rect2(Vector2(16, 64), get_viewport_rect().size - Vector2(32, 128))
	FRAMING.update(camera, points, safe_area, 120.0, delta)


func _release_inputs() -> void:
	for player in players:
		player.controls.release()
		player.weapon.require_new_press()


func assign_joypad(device: int) -> void:
	players[0 if bot_enabled else 1].controls.assign_joypad(device)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if bot_enabled:
		var controls = players[0].controls
		if not connected and device == controls.joypad_device:
			controls.assign_joypad(-1)
			pause_match("Manette de Poncho déconnectée")
		elif connected and controls.source == controls.Source.JOYPAD and controls.joypad_device < 0:
			controls.assign_joypad(device)
			get_tree().set_meta("poncho_joypad", device)
		return
	if connected and players[1].controls.joypad_device < 0:
		assign_joypad(device)
	elif not connected and device == players[1].controls.joypad_device:
		assign_joypad(-1)
		pause_match("Manette de J2 déconnectée")


func pause_match(reason := "Pause commune") -> void:
	if not is_inside_tree() or phase == Phase.FINISHED or get_tree().paused:
		return
	_release_inputs()
	get_tree().paused = true
	announcement.text = "Pause"
	details.text = reason
	if bot_enabled:
		_update_hud()
		resume_button.grab_focus.call_deferred()


func resume_match() -> void:
	_release_inputs()
	get_tree().paused = false


func replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func return_to_title() -> void:
	get_tree().paused = false
	get_tree().set_meta("intro_to_title", true)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _finish_match() -> void:
	phase = Phase.FINISHED
	world.process_mode = Node.PROCESS_MODE_DISABLED
	_release_inputs()
	var winners: Array[int] = bottle.winner_numbers()
	announcement.text = "Victoire partagée !" if winners.size() > 1 else "J%d remporte la partie !" % winners[0]
	if bot_enabled:
		announcement.text = "Victoire partagée !" if winners.size() > 1 else (
			"Poncho remporte la partie !" if winners[0] == 1 else "Garcia remporte la partie !")
		details.text = "%.1f %% de la bouteille bus par chacun" % bottle.score_percent(winners[0]) \
			if winners.size() > 1 else "%.1f %% de la bouteille bus" % bottle.score_percent(winners[0])
		_update_hud()
		replay_button.grab_focus.call_deferred()
		return
	details.text = "Bouteille vide\nJ1 : %.1f %% bus     J2 : %.1f %% bus" % [
		bottle.score_percent(1), bottle.score_percent(2)]


func _unhandled_input(event: InputEvent) -> void:
	var keyboard_pause: bool = event is InputEventKey and event.physical_keycode == KEY_ESCAPE
	var joypad_pause: bool = event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START \
		and event.device == players[0 if bot_enabled else 1].controls.joypad_device
	if (keyboard_pause or joypad_pause) and event.is_pressed() and not event.is_echo():
		if get_tree().paused:
			resume_match()
		else:
			pause_match()
		get_viewport().set_input_as_handled()
	elif bot_enabled and event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_F:
			overview = not overview
		elif event.physical_keycode == KEY_P:
			arena.annotations = not arena.annotations


func _label(parent: Node, text: String, size := 12) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _panel(parent: Node, rectangle: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rectangle.position
	panel.size = rectangle.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("30221b")
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var top := _panel(hud, Rect2(0, 0, 640, 58))
	var rows := VBoxContainer.new()
	top.add_child(rows)
	var row := HBoxContainer.new()
	rows.add_child(row)
	status = _label(row, "BOUTEILLE · Au sol", 14)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(row, "Pause · Échap", pause_match)
	_button(row, "Titre", return_to_title)
	var scores := HBoxContainer.new()
	rows.add_child(scores)
	for i in range(2):
		var label := _label(scores, "")
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", players[i].player_color.lightened(0.55))
		player_labels.append(label)
	var bottom := _panel(hud, Rect2(0, 302, 640, 58))
	var footer := VBoxContainer.new()
	bottom.add_child(footer)
	_label(footer, "Porte la bouteille pour boire · Tire sur le porteur pour la récupérer", 11)
	_label(footer, "J1 · ZQSD / WASD · Souris · Clic : tir · Espace : dash · R : recharger", 10)
	help = _label(footer, "", 10)
	overlay = _panel(hud, Rect2(132, 112, 376, 152))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	overlay.add_child(content)
	announcement = _label(content, "3", 22)
	announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details = _label(content, "Passe sur la bouteille pour la ramasser", 11)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume_button = _button(content, "Reprendre", resume_match)
	replay_button = _button(content, "Rejouer", replay)


func _update_hud() -> void:
	if bot_enabled:
		_update_round_hud()
		return
	status.text = "BOUTEILLE · %s" % ("Vide" if bottle.remaining == 0 else (
		"J%d boit" % bottle.holder.player_number if is_instance_valid(bottle.holder) else "Au sol"))
	for i in range(players.size()):
		var player = players[i]
		var state := "Fantôme" if player.is_ghost() else (
			"Recharge" if player.weapon.is_reloading() else "%d/%d balles" % [player.weapon.ammunition, player.weapon.capacity])
		player_labels[i].text = "J%d · %d PV · %s" % [i + 1, player.health, state]
	help.text = "J2 · Sticks · RT : tir · LT : dash · X / carré : recharger · Start : pause" \
		if players[1].controls.joypad_device >= 0 else "J2 · Branche une manette pour jouer à deux (sinon J2 reste immobile)"
	overlay.visible = phase != Phase.PLAYING or get_tree().paused
	resume_button.visible = get_tree().paused
	replay_button.visible = phase == Phase.FINISHED or get_tree().paused
	if phase == Phase.COUNTDOWN and not get_tree().paused:
		announcement.text = str(ceili(countdown_left))
		details.text = "Passe sur la bouteille pour la ramasser\nBois plus que l’autre joueur pour gagner"


func _build_round_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var top := HBoxContainer.new()
	top.name = "Top"
	top.position = Vector2(8, 2)
	top.size = Vector2(get_viewport_rect().size.x - 16, 22)
	top.add_theme_constant_override("separation", 6)
	hud.add_child(top)
	status = _label(top, "ARROYO SECO · v0.3", 12)
	status.add_theme_color_override("font_color", Color("33291c"))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	device_button = _button(top, "Passer à la manette", _toggle_device)
	_button(top, "Vue · F", func(): overview = not overview)
	_button(top, "Pause", pause_match)
	_button(top, "Titre", return_to_title)
	for child in top.get_children():
		child.add_theme_font_size_override("font_size", 10 if child is Button else 12)
	reserve = RESERVE.new()
	reserve.name = "Reserve"
	reserve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reserve.size = Vector2(64, 80)
	reserve.bottle = bottle
	reserve.art = presentation.art
	hud.add_child(reserve)
	help = _label(hud, "", 10)
	help.add_theme_color_override("font_color", Color("33291c"))
	overlay = _panel(hud, Rect2(132, 112, 376, 152))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	overlay.add_child(content)
	announcement = _label(content, "3", 20)
	announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details = _label(content, "", 11)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume_button = _button(content, "Reprendre", resume_match)
	replay_button = _button(content, "Rejouer", replay)
	result_title_button = _button(content, "Retour au titre", return_to_title)
	for button in [resume_button, replay_button, result_title_button]:
		button.focus_mode = Control.FOCUS_ALL


func _toggle_device() -> void:
	var connected := Input.get_connected_joypads()
	if players[0].controls.source == players[0].controls.Source.JOYPAD:
		_select_device(-1)
	elif not connected.is_empty():
		_select_device(connected[0])


func _select_device(device: int) -> void:
	players[0].stop_movement()
	if device >= 0:
		players[0].controls.source = players[0].controls.Source.JOYPAD
		players[0].controls.assign_joypad(device)
		get_tree().set_meta("poncho_joypad", device)
	else:
		players[0].controls.use_keyboard_mouse()
		get_tree().remove_meta("poncho_joypad")


func _update_round_camera(delta: float) -> void:
	if overview:
		var available := get_viewport_rect().size - Vector2(24, 100)
		var fit: Vector2 = available / arena.world_size()
		camera.zoom = Vector2.ONE * minf(fit.x, fit.y)
		camera.position = arena.world_size() / 2.0
		return
	var points := PackedVector2Array([bottle.global_position])
	for player in players:
		points.append(player.global_position + Vector2(0, -78))
		points.append(player.global_position + Vector2(0, 36))
	var separation: float = players[0].global_position.distance_to(players[1].global_position)
	var wide := smoothstep(320.0, 800.0, separation)
	var look: Vector2 = players[0].velocity.limit_length(players[0].max_speed) / players[0].max_speed
	points.append(players[0].global_position + look * 96.0 * wide)
	var safe := Rect2(Vector2(12, 72), get_viewport_rect().size - Vector2(24, 96))
	FRAMING.update(camera, points, safe, lerpf(72.0, 160.0, wide), delta)


func _update_round_hud() -> void:
	var size := get_viewport_rect().size
	$HUD/Top.size.x = size.x - 16
	reserve.position = Vector2(size.x / 2.0 - 32, 0)
	help.position = Vector2(8, size.y - 16)
	var joypad: bool = players[0].controls.source == players[0].controls.Source.JOYPAD
	device_button.text = "Passer au clavier" if joypad else "Passer à la manette"
	device_button.disabled = not joypad and Input.get_connected_joypads().is_empty()
	help.text = "Sticks · RT : tir / crosse au contact · LT : dash · X / carré : recharger · Start : pause" if joypad else \
		"ZQSD / WASD · Souris · Clic : tir / crosse au contact · Espace : dash · R : recharger · Échap : pause"
	overlay.position = (size - overlay.size) / 2.0
	overlay.visible = phase != Phase.PLAYING or get_tree().paused
	resume_button.visible = get_tree().paused
	replay_button.visible = phase == Phase.FINISHED or get_tree().paused
	result_title_button.visible = phase == Phase.FINISHED or get_tree().paused
	if phase == Phase.COUNTDOWN and not get_tree().paused:
		announcement.text = str(ceili(countdown_left))
		details.text = "Poncho contre Garcia\nPasse sur la bouteille pour la ramasser"
