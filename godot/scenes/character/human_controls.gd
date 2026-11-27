extends Node
## Per-character actions keep keyboard and individual joypads isolated.

enum Source { KEYBOARD_MOUSE, JOYPAD }

@export var source: Source = Source.KEYBOARD_MOUSE
@export_range(0.0, 0.9) var stick_deadzone := 0.2

var joypad_device := -1
var _actions: Dictionary = {}
var _mouse_position := Vector2.ZERO
var _fire_held := false
var _fire_press := false
var _reload_press := false


func _ready() -> void:
	_mouse_position = get_viewport().get_mouse_position()
	if source == Source.KEYBOARD_MOUSE:
		use_keyboard_mouse()


func use_keyboard_mouse() -> void:
	_remove_actions()
	source = Source.KEYBOARD_MOUSE
	joypad_device = -1
	_mouse_position = get_viewport().get_mouse_position()
	var keys := [KEY_A, KEY_D, KEY_W, KEY_S]
	for i in range(4):
		var event := InputEventKey.new()
		# Physical WASD becomes ZQSD on an AZERTY layout.
		event.physical_keycode = keys[i]
		_add_action("move_" + str(i), event)
	var dash_key := InputEventKey.new()
	dash_key.physical_keycode = KEY_SPACE
	_add_action("dash", dash_key)
	var fire_button := InputEventMouseButton.new()
	fire_button.button_index = MOUSE_BUTTON_LEFT
	_add_action("fire", fire_button)
	var reload_key := InputEventKey.new()
	reload_key.physical_keycode = KEY_R
	_add_action("reload", reload_key)


func assign_joypad(device: int) -> void:
	if source != Source.JOYPAD:
		return
	_remove_actions()
	joypad_device = device
	if device < 0:
		return
	for prefix in ["move_", "aim_"]:
		var first_axis := JOY_AXIS_LEFT_X if prefix == "move_" else JOY_AXIS_RIGHT_X
		for i in range(4):
			var event := InputEventJoypadMotion.new()
			event.device = device
			event.axis = first_axis + (1 if i >= 2 else 0)
			event.axis_value = -1.0 if i % 2 == 0 else 1.0
			_add_action(prefix + str(i), event)
	var trigger := InputEventJoypadMotion.new()
	trigger.device = device
	trigger.axis = JOY_AXIS_TRIGGER_LEFT
	trigger.axis_value = 1.0
	_add_action("dash", trigger)
	InputMap.action_set_deadzone(_actions["dash"], 0.5)
	var fire_trigger := InputEventJoypadMotion.new()
	fire_trigger.device = device
	fire_trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	fire_trigger.axis_value = 1.0
	_add_action("fire", fire_trigger)
	InputMap.action_set_deadzone(_actions["fire"], 0.5)
	var reload_button := InputEventJoypadButton.new()
	reload_button.device = device
	reload_button.button_index = JOY_BUTTON_X
	_add_action("reload", reload_button)


func movement() -> Vector2:
	return _vector("move_")


func dash_just_pressed() -> bool:
	return _actions.has("dash") and Input.is_action_just_pressed(_actions["dash"])


func fire_pressed() -> bool:
	return _fire_held


func consume_fire_press() -> bool:
	var pressed := _fire_press
	_fire_press = false
	return pressed


func consume_reload_press() -> bool:
	var pressed := _reload_press
	_reload_press = false
	return pressed


func aim(character_position: Vector2) -> Vector2:
	if source == Source.JOYPAD:
		return _vector("aim_").normalized()
	var world_mouse := get_viewport().get_canvas_transform().affine_inverse() * _mouse_position
	return (world_mouse - character_position).normalized()


func release() -> void:
	_fire_held = false
	_fire_press = false
	_reload_press = false
	for action in _actions.values():
		Input.action_release(action)


func _input(event: InputEvent) -> void:
	if source == Source.KEYBOARD_MOUSE and event is InputEventMouseMotion:
		_mouse_position = event.position
	if _actions.has("fire") and event.is_action_released(_actions["fire"]):
		_fire_held = false


func _unhandled_input(event: InputEvent) -> void:
	# GUI clicks never become shots. Releases are observed before GUI handling.
	if _actions.has("fire") and event.is_action_pressed(_actions["fire"]):
		if not _fire_held:
			_fire_press = true
		_fire_held = true
	if _actions.has("reload") and not event.is_echo() and event.is_action_pressed(_actions["reload"]):
		_reload_press = true


func _vector(prefix: String) -> Vector2:
	if not _actions.has(prefix + "0"):
		return Vector2.ZERO
	return Input.get_vector(
		_actions[prefix + "0"], _actions[prefix + "1"],
		_actions[prefix + "2"], _actions[prefix + "3"],
		stick_deadzone if source == Source.JOYPAD else 0.0
	)


func _add_action(direction: String, event: InputEvent) -> void:
	var action := StringName("character_%s_%s" % [get_instance_id(), direction])
	InputMap.add_action(action, stick_deadzone)
	InputMap.action_add_event(action, event)
	_actions[direction] = action


func _remove_actions() -> void:
	release()
	for action in _actions.values():
		InputMap.erase_action(action)
	_actions.clear()


func _exit_tree() -> void:
	_remove_actions()
