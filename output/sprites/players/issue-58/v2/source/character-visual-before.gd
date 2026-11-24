extends Node2D
## Body stays upright; only the held weapon turns. No gameplay or input rules.

const ASSETS := "res://scenes/character/assets/"
const CELL := Vector2(48, 48)
const ANCHOR := Vector2(24, 26)
const COUNTS := {"idle": 1, "walk": 6, "dash": 4}

@export_enum("Poncho", "Garcia") var character_style := 0:
	set(value):
		character_style = clampi(value, 0, 1)
		if is_node_ready():
			_load_textures()

var animation_state := "idle"
var animation_frame := 0
var weapon_angle := 0.0
var _phase := 0.0
var _state_time := 0.0
var _shot_time := 1.0
var _textures: Dictionary = {}
@onready var actor = get_parent()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_textures()
	if actor.has_node("Revolver"):
		actor.get_node("Revolver").fired.connect(func(): _shot_time = 0.0)


func _load_textures() -> void:
	var style := "poncho" if character_style == 0 else "garcia"
	for state in COUNTS:
		_textures[state] = load(ASSETS + style + "/" + state + ".png")
		_textures["hat_" + state] = load(ASSETS + style + "/hat_" + state + ".png")
	for arm in ["arm_idle", "walk_arm", "fire"]:
		_textures[arm] = load(ASSETS + "poncho/" + arm + ".png")
	queue_redraw()


func _process(delta: float) -> void:
	# Use actual movement too: walking into a solid wall must stop the loop.
	var speed := minf(actor.velocity.length(), actor.get_real_velocity().length())
	var next_state := "dash" if actor.is_dashing() else ("walk" if speed > 4.0 else "idle")
	if next_state != animation_state:
		animation_state = next_state
		_phase = 0.0
		_state_time = 0.0
	_state_time += delta
	_shot_time += delta
	match animation_state:
		"walk":
			_phase += delta * 8.0 * clampf(speed / actor.max_speed, 0.4, 1.3)
			animation_frame = int(_phase) % 6
		"dash":
			animation_frame = mini(int(_state_time / actor.dash_duration * 4.0), 3)
		_:
			animation_frame = 0
	weapon_angle = actor.aim_direction.angle()
	queue_redraw()


func _draw_frame(texture: Texture2D, frame: int) -> void:
	draw_texture_rect_region(texture, Rect2(-ANCHOR, CELL),
		Rect2(Vector2(frame * 48, 0), CELL))


func _draw() -> void:
	if _textures.is_empty():
		return
	draw_set_transform(Vector2(-2, 14), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 10, Color(0.19, 0.13, 0.08, 0.25))
	draw_set_transform(Vector2.ZERO)
	_draw_frame(_textures[animation_state], animation_frame)
	draw_set_transform(Vector2.ZERO, weapon_angle)
	if _shot_time < 4.0 / 18.0:
		_draw_frame(_textures.fire, mini(int(_shot_time * 18.0), 3))
	elif animation_state == "walk":
		_draw_frame(_textures.walk_arm, animation_frame)
	else:
		_draw_frame(_textures.arm_idle, 0)
	draw_set_transform(Vector2.ZERO)
	# Restore exact body pixels over the hand, not a differently colored patch.
	_draw_frame(_textures["hat_" + animation_state], animation_frame)
