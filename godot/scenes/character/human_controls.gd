extends Node
## Per-character actions keep keyboard and individual joypads isolated.

enum Source { KEYBOARD_MOUSE, JOYPAD }

@export var source: Source = Source.KEYBOARD_MOUSE
@export_range(0.0, 0.9) var stick_deadzone := 0.2

var joypad_device := -1
var _actions: Dictionary = {}
var _mouse_position := Vector2.ZERO


func _ready() -> void:
	_mouse_position = get_viewport().get_mouse_position()
	if source == Source.KEYBOARD_MOUSE:
		var keys := [KEY_A, KEY_D, KEY_W, KEY_S]
		for i in range(4):
			var event := InputEventKey.new()
			# Physical WASD becomes ZQSD on an AZERTY layout.
			event.physical_keycode = keys[i]
			_add_action("move_" + str(i), event)


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


func movement() -> Vector2:
	return _vector("move_")


func aim(character_position: Vector2) -> Vector2:
	if source == Source.JOYPAD:
		return _vector("aim_").normalized()
	var world_mouse := get_viewport().get_canvas_transform().affine_inverse() * _mouse_position
	return (world_mouse - character_position).normalized()


func release() -> void:
	for action in _actions.values():
		Input.action_release(action)


func _input(event: InputEvent) -> void:
	if source == Source.KEYBOARD_MOUSE and event is InputEventMouseMotion:
		_mouse_position = event.position


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
