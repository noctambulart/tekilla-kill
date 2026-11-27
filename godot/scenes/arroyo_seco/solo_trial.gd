extends "res://scenes/arroyo_seco/arena_review.gd"

const CHARACTER := preload("res://scenes/character/character.tscn")
const CONTROLS := preload("res://scenes/character/human_controls.gd")
const FRAMING := preload("res://scenes/camera/group_framing.gd")

const TARGET_SHOT_LAYER := 4

var target: CharacterBody2D
var device_button: Button
var _previous_scale_aspect: Window.ContentScaleAspect
var _previous_scale_stretch: Window.ContentScaleStretch


func _enter_tree() -> void:
	var window := get_window()
	_previous_scale_aspect = window.content_scale_aspect
	_previous_scale_stretch = window.content_scale_stretch
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


func _exit_tree() -> void:
	var window := get_window()
	window.content_scale_aspect = _previous_scale_aspect
	window.content_scale_stretch = _previous_scale_stretch


func _ready() -> void:
	super._ready()
	arena.show_bottle_marker = false
	arena.queue_redraw()
	explorer.combat_enabled = true
	target = CHARACTER.instantiate()
	target.name = "Target"
	target.stationary = true
	target.combat_enabled = true
	target.player_number = 2
	target.player_color = Color("b83d2b")
	target.z_index = explorer.z_index
	target.get_node("HumanControls").source = CONTROLS.Source.JOYPAD
	target.get_node("Visual").character_style = 1
	var hit_area := Area2D.new()
	hit_area.name = "ShotTarget"
	hit_area.collision_layer = TARGET_SHOT_LAYER
	hit_area.collision_mask = 0
	hit_area.monitoring = false
	# Garcia's hat overhangs his body and the small movement collider at ground level.
	var silhouette := ConvexPolygonShape2D.new()
	silhouette.points = PackedVector2Array([
		Vector2(-6, -15), Vector2(6, -15), Vector2(16, -6), Vector2(17, -1),
		Vector2(13, 10), Vector2(5, 14), Vector2(-5, 14), Vector2(-13, 10),
		Vector2(-17, -1), Vector2(-16, -6),
	])
	var hit_shape := CollisionShape2D.new()
	hit_shape.shape = silhouette
	hit_area.add_child(hit_shape)
	target.add_child(hit_area)
	add_child(target)
	if arena.layout.get("grounded_characters", false):
		target.use_village_art()
	$HUD/Top/Title.text = "ARROYO SECO · v0.1"
	device_button = _trial_button("Passer à la manette", _toggle_device)
	_trial_button("Réinitialiser · F2", reset_trial)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_update_device_hint()
	reset_trial()


func reset_trial() -> void:
	get_tree().call_group("revolver_bullets", "queue_free")
	explorer.reset_combat()
	target.reset_combat()
	explorer.position = arena.tile_point(arena.layout.spawns[3])
	target.position = arena.tile_point(arena.layout.bottle)
	explorer.aim_direction = Vector2.RIGHT
	target.aim_direction = Vector2.LEFT
	set_overview(false)


func _process(delta: float) -> void:
	if not overview:
		_update_framing(delta)


func set_overview(enabled: bool) -> void:
	super.set_overview(enabled)
	if enabled:
		view_button.text = "Caméra adaptative · F"
	else:
		_update_framing(0.0)


func _on_viewport_resized() -> void:
	if overview:
		set_overview(true)


func _update_framing(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var safe_area := Rect2(Vector2(12, 30), get_viewport_rect().size - Vector2(24, 56))
	var separation: float = explorer.global_position.distance_to(target.global_position)
	var wide := smoothstep(320.0, 800.0, separation)
	var look_ahead: Vector2 = explorer.velocity.limit_length(explorer.max_speed) / explorer.max_speed
	var ahead: Vector2 = explorer.global_position + look_ahead * (96.0 * wide)
	ahead = ahead.clamp(Vector2.ZERO, arena.world_size())
	var points := PackedVector2Array([explorer.global_position, target.global_position, ahead])
	FRAMING.update(camera, points, safe_area, lerpf(72.0, 160.0, wide), delta)


func _trial_button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(action)
	$HUD/Top.add_child(button)
	$HUD/Top.move_child(button, $HUD/Top/Return.get_index())
	return button


func _toggle_device() -> void:
	if explorer.controls.joypad_device >= 0:
		select_device(-1)
	else:
		var pads := Input.get_connected_joypads()
		if not pads.is_empty():
			select_device(pads[0])


func select_device(device: int) -> void:
	explorer.stop_movement()
	if device >= 0:
		explorer.controls.source = CONTROLS.Source.JOYPAD
		explorer.controls.assign_joypad(device)
	else:
		explorer.controls.use_keyboard_mouse()
	_update_device_hint()


func _update_device_hint() -> void:
	var using_pad: bool = explorer.controls.joypad_device >= 0
	device_button.disabled = not using_pad and Input.get_connected_joypads().is_empty()
	device_button.text = "Passer au clavier" if using_pad else "Passer à la manette"
	$HUD/Help.text = "Sticks : bouger / viser · RT : tir · LT : dash · X / carré : recharger" if using_pad \
		else "ZQSD / WASD · Souris : visée · Clic gauche : tir · Espace : dash · R : recharger"


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and device == explorer.controls.joypad_device:
		select_device(-1)
	else:
		_update_device_hint()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# R already reaches the revolver through the normal input handler.
		if event.physical_keycode == KEY_R:
			return
		if event.physical_keycode == KEY_F2:
			reset_trial()
			get_viewport().set_input_as_handled()
			return
	super._unhandled_key_input(event)
