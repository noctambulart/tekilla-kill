extends Node2D
## Walk-through for reviewing the arena, not a match or the adaptive match camera.

@onready var arena = $ArroyoSeco
@onready var explorer = $Explorer
@onready var camera: Camera2D = $Camera2D
@onready var view_button: Button = $HUD/Top/View
@onready var plan_button: Button = $HUD/Top/Plan

var overview := false


func _ready() -> void:
	explorer.position = arena.tile_point(arena.layout.spawns[0])
	get_window().focus_exited.connect(explorer.stop_movement)
	set_overview(false)


func _process(_delta: float) -> void:
	if not overview:
		camera.position = _follow_position()


func _follow_position() -> Vector2:
	var half_view := get_viewport_rect().size / 2
	return explorer.position.round().clamp(half_view, arena.world_size() - half_view)


func set_overview(enabled: bool) -> void:
	overview = enabled
	if overview:
		var available := get_viewport_rect().size - Vector2(24, 40)
		var fit: Vector2 = available / arena.world_size()
		camera.zoom = Vector2.ONE * minf(fit.x, fit.y)
		camera.position = arena.world_size() / 2
	else:
		camera.zoom = Vector2.ONE
		camera.position = _follow_position()
	view_button.text = "Voir de près · F" if overview else "Vue d’ensemble · F"
	camera.reset_smoothing()


func toggle_view() -> void:
	set_overview(not overview)


func toggle_plan() -> void:
	arena.annotations = not arena.annotations
	plan_button.text = "Masquer le plan · P" if arena.annotations else "Plan · P"


func return_to_title() -> void:
	explorer.stop_movement()
	get_tree().set_meta("intro_to_title", true)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_F:
			toggle_view()
		KEY_P:
			toggle_plan()
		KEY_R:
			explorer.stop_movement()
			explorer.position = arena.tile_point(arena.layout.spawns[0])
		KEY_ESCAPE:
			return_to_title()
		_:
			return
	get_viewport().set_input_as_handled()
