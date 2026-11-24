extends CharacterBody2D

@export var player_number := 1
@export var player_color := Color("3c879b")
@export var max_speed := 200.0
@export var acceleration := 1400.0
@export var braking := 1600.0
@export var turning_acceleration := 1300.0

var aim_direction := Vector2.RIGHT

@onready var controls = $HumanControls


func _physics_process(delta: float) -> void:
	var target_velocity: Vector2 = controls.movement() * max_speed
	var rate := acceleration
	# Approach the requested vector from the current one so turns carry momentum.
	if velocity.dot(target_velocity) < 0.999 * velocity.length() * target_velocity.length():
		rate = turning_acceleration
	elif target_velocity.length_squared() < velocity.length_squared():
		rate = braking
	velocity = velocity.move_toward(target_velocity, rate * delta)
	move_and_slide()
	var aiming: Vector2 = controls.aim(global_position)
	if not aiming.is_zero_approx():
		aim_direction = aiming
	queue_redraw()


func stop_movement() -> void:
	controls.release()
	velocity = Vector2.ZERO


func _draw() -> void:
	draw_circle(Vector2(1, 4), 10, Color(0.16, 0.1, 0.06, 0.35))
	draw_arc(Vector2.ZERO, 12, 0, TAU, 32, player_color, 2)
	draw_circle(Vector2.ZERO, 8, player_color.darkened(0.25))
	draw_circle(Vector2(0, -2), 6, Color("e9cd8d"))
	draw_circle(Vector2(0, -2), 3, Color("8c663b"))
	draw_line(aim_direction * 7, aim_direction * 19, Color("352a25"), 3)
	var reticle := aim_direction * 28
	draw_line(reticle - Vector2(3, 0), reticle + Vector2(3, 0), player_color)
	draw_line(reticle - Vector2(0, 3), reticle + Vector2(0, 3), player_color)
	draw_string(ThemeDB.fallback_font, Vector2(-7, -17), "J" + str(player_number),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("30221b"))
