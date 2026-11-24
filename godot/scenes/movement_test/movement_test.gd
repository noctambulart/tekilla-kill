extends Node2D
## Temporary play area for issue #18; the production arena is a later mission.

const PLAY_AREA := Rect2(24, 64, 592, 232)
const OBSTACLES := [Rect2(286, 128, 68, 104), Rect2(128, 96, 64, 32), Rect2(448, 232, 64, 32)]

@onready var keyboard_character = $Players/J1
@onready var joypad_character = $Players/J2


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_window().focus_exited.connect(_release_controls)
	var joypads := Input.get_connected_joypads()
	assign_joypad(joypads[0] if not joypads.is_empty() else -1)


func assign_joypad(device: int) -> void:
	joypad_character.stop_movement()
	joypad_character.controls.assign_joypad(device)
	$HUD/Controls/JoypadStatus.text = (
		"J2 · Manette connectée — sticks : déplacement / visée"
		if device >= 0 else "J2 · Branche une manette pour jouer à deux"
	)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	var assigned: int = joypad_character.controls.joypad_device
	if connected and assigned < 0:
		assign_joypad(device)
	elif not connected and device == assigned:
		var available := Input.get_connected_joypads()
		assign_joypad(available[0] if not available.is_empty() else -1)


func _release_controls() -> void:
	keyboard_character.stop_movement()
	joypad_character.stop_movement()


func return_to_title() -> void:
	get_tree().set_meta("intro_to_title", true)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("b58350"))
	draw_rect(PLAY_AREA.grow(4), Color("72503a"))
	draw_rect(PLAY_AREA, Color("d4af75"))
	for x in range(32, 616, 32):
		draw_line(Vector2(x, 64), Vector2(x, 296), Color(0.48, 0.34, 0.2, 0.12))
	for y in range(64, 296, 32):
		draw_line(Vector2(24, y), Vector2(616, y), Color(0.48, 0.34, 0.2, 0.12))
	for obstacle in OBSTACLES:
		draw_rect(obstacle, Color("795b42"))
		draw_rect(obstacle.grow(-3), Color("9d7953"))
