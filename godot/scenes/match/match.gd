extends Node2D
## First complete two-player match; skills, bots and the full lobby come later.

const ARENA := preload("res://scenes/arroyo_seco/arroyo_seco.tscn")
const CHARACTER := preload("res://scenes/character/character.tscn")
const BOTTLE := preload("res://scenes/bottle/bottle.gd")
enum Phase { COUNTDOWN, PLAYING, FINISHED }

@export_range(0.0, 5.0) var countdown_duration := 3.0

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


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_DISABLED
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
		world.add_child(player)
		players.append(player)
	bottle = BOTTLE.new()
	bottle.name = "Bottle"
	world.add_child(bottle)
	bottle.configure(players, arena.tile_point(arena.layout.bottle))
	bottle.emptied.connect(_finish_match)
	camera = Camera2D.new()
	add_child(camera)
	_build_hud()
	countdown_left = countdown_duration
	var connected := Input.get_connected_joypads()
	assign_joypad(connected[0] if not connected.is_empty() else -1)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_window().focus_exited.connect(pause_match.bind("Fenêtre inactive"))
	_update_camera()
	_update_hud()


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if phase == Phase.COUNTDOWN:
		countdown_left = move_toward(countdown_left, 0.0, delta)
		if is_zero_approx(countdown_left):
			phase = Phase.PLAYING
			_release_inputs()
			world.process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(_delta: float) -> void:
	_update_camera()
	_update_hud()


func _update_camera() -> void:
	var bounds := Rect2(bottle.global_position, Vector2.ZERO)
	for player in players:
		bounds = bounds.expand(player.global_position)
	bounds = bounds.grow(80)
	var available := get_viewport_rect().size - Vector2(32, 128)
	var zoom := minf(1.0, minf(available.x / bounds.size.x, available.y / bounds.size.y))
	camera.zoom = Vector2.ONE * zoom
	camera.position = bounds.get_center()


func _release_inputs() -> void:
	for player in players:
		player.controls.release()
		player.weapon.require_new_press()


func assign_joypad(device: int) -> void:
	players[1].controls.assign_joypad(device)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected and players[1].controls.joypad_device < 0:
		assign_joypad(device)
	elif not connected and device == players[1].controls.joypad_device:
		assign_joypad(-1)
		pause_match("Manette de J2 déconnectée")


func pause_match(reason := "Pause commune") -> void:
	if phase == Phase.FINISHED or get_tree().paused:
		return
	_release_inputs()
	get_tree().paused = true
	announcement.text = "Pause"
	details.text = reason


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
	details.text = "Bouteille vide\nJ1 : %.1f %% bus     J2 : %.1f %% bus" % [
		bottle.score_percent(1), bottle.score_percent(2)]


func _unhandled_input(event: InputEvent) -> void:
	var keyboard_pause: bool = event is InputEventKey and event.physical_keycode == KEY_ESCAPE
	var joypad_pause: bool = event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START \
		and event.device == players[1].controls.joypad_device
	if (keyboard_pause or joypad_pause) and event.is_pressed() and not event.is_echo():
		if get_tree().paused:
			resume_match()
		else:
			pause_match()
		get_viewport().set_input_as_handled()


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
	status = _label(row, "BOUTEILLE · 100 %", 14)
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
	status.text = "BOUTEILLE · %.1f %% · %s" % [100.0 * bottle.remaining / bottle.total_amount,
		"J%d boit" % bottle.holder.player_number if is_instance_valid(bottle.holder) else "Au sol"]
	for i in range(players.size()):
		var player = players[i]
		var state := "Fantôme" if player.is_ghost() else (
			"Recharge" if player.weapon.is_reloading() else "%d/%d balles" % [player.weapon.ammunition, player.weapon.capacity])
		player_labels[i].text = "J%d · %.1f %% bus · %d PV · %s" % [i + 1,
			bottle.score_percent(i + 1), player.health, state]
	help.text = "J2 · Sticks · RT : tir · LT : dash · X / carré : recharger · Start : pause" \
		if players[1].controls.joypad_device >= 0 else "J2 · Branche une manette pour jouer à deux (sinon J2 reste immobile)"
	overlay.visible = phase != Phase.PLAYING or get_tree().paused
	resume_button.visible = get_tree().paused
	replay_button.visible = phase == Phase.FINISHED or get_tree().paused
	if phase == Phase.COUNTDOWN and not get_tree().paused:
		announcement.text = str(ceili(countdown_left))
		details.text = "Passe sur la bouteille pour la ramasser\nBois plus que l’autre joueur pour gagner"
