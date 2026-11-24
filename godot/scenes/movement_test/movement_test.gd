extends Node2D
## Temporary movement/combat trial for #18–#21; not a complete match.

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
		"J2 · Sticks : bouger / viser · RT : tir · LT : dash · X / carré : recharger"
		if device >= 0 else "J2 · Branche une manette pour jouer à deux"
	)


func _process(_delta: float) -> void:
	var status: Array[String] = []
	for character in [keyboard_character, joypad_character]:
		var ammunition: int = character.weapon.ammunition
		var state := "%d/%d balles" % [ammunition, character.weapon.capacity]
		if character.health == 0:
			state = "Réinitialiser l’essai"
		elif character.weapon.is_reloading():
			state += " · recharge"
		elif ammunition == 0:
			state = "VIDE"
		status.append("J%d : %d PV · %s" % [character.player_number, character.health, state])
	$HUD/Controls/Subtitle.text = "     |     ".join(status)


func reset_trial() -> void:
	for bullet in get_tree().get_nodes_in_group("revolver_bullets"):
		bullet.queue_free()
	keyboard_character.reset_combat()
	joypad_character.reset_combat()
	keyboard_character.position = Vector2(160, 208)
	joypad_character.position = Vector2(480, 144)
	keyboard_character.aim_direction = Vector2.RIGHT
	joypad_character.aim_direction = Vector2.LEFT


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
