extends CharacterBody2D
## One source for possession, integer amounts drunk, drops and pickup arbitration.

signal emptied
signal possession_changed(holder: Node2D)

@export_range(1, 60000) var total_amount := 2400
@export_range(1.0, 6000.0) var drinking_rate := 60.0
@export var pickup_radius := 15.0
@export var throw_distance := 90.0
@export_range(0.01, 2.0, 0.01) var throw_duration := 0.22
@export_range(0.0, 2.0, 0.01) var former_holder_delay := 0.45

var holder: Node2D
var remaining := 0
var scores: Dictionary = {}
var participants: Array = []
var _sip_remainders: Dictionary = {}
var _former_holder: Node2D
var _pickup_lock_left := 0.0
var _throw_time_left := 0.0
var _ended := false
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	z_index = 10
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	collider.shape = shape
	add_child(collider)
	_random.randomize()


func configure(players: Array, origin: Vector2) -> void:
	participants = players.duplicate()
	global_position = origin
	remaining = total_amount
	for player in participants:
		scores[player.player_number] = 0
		_sip_remainders[player.player_number] = 0.0
		player.damaged.connect(_on_character_damaged.bind(player))


func _physics_process(delta: float) -> void:
	if _ended:
		return
	_pickup_lock_left = move_toward(_pickup_lock_left, 0.0, delta)
	if is_instance_valid(holder):
		global_position = holder.global_position
		_drink(delta)
	else:
		_advance_throw(delta)
		_try_pickup()
	queue_redraw()


func _try_pickup() -> void:
	var closest := INF
	var candidates: Array = []
	for player in participants:
		if not is_instance_valid(player) or not player.is_active():
			continue
		if player == _former_holder and _pickup_lock_left > 0.0:
			continue
		var distance: float = global_position.distance_squared_to(player.global_position)
		if distance > pickup_radius * pickup_radius:
			continue
		if distance < closest:
			closest = distance
			candidates = [player]
		elif distance == closest:
			candidates.append(player)
	if candidates.is_empty():
		return
	holder = candidates[_random.randi_range(0, candidates.size() - 1)]
	velocity = Vector2.ZERO
	_throw_time_left = 0.0
	global_position = holder.global_position
	possession_changed.emit(holder)


func _drink(delta: float) -> void:
	var number: int = holder.player_number
	_sip_remainders[number] += delta * drinking_rate
	var amount := mini(remaining, floori(_sip_remainders[number] + 0.000001))
	_sip_remainders[number] -= amount
	scores[number] += amount
	remaining -= amount
	if remaining == 0:
		_ended = true
		emptied.emit()


func _on_character_damaged(_amount: int, attacker: Node2D, victim: Node2D) -> void:
	if victim != holder or _ended:
		return
	global_position = victim.global_position
	_former_holder = victim
	_pickup_lock_left = former_holder_delay
	holder = null
	var direction := Vector2.ZERO
	if is_instance_valid(attacker):
		direction = (attacker.global_position - global_position).normalized()
	_throw_time_left = throw_duration if not direction.is_zero_approx() else 0.0
	velocity = direction * throw_distance / throw_duration
	possession_changed.emit(null)
	queue_redraw()


func _advance_throw(delta: float) -> void:
	if _throw_time_left <= 0.0:
		return
	if move_and_collide(velocity * minf(delta, _throw_time_left)):
		_throw_time_left = 0.0
		velocity = Vector2.ZERO
	else:
		_throw_time_left = move_toward(_throw_time_left, 0.0, delta)
		if is_zero_approx(_throw_time_left):
			velocity = Vector2.ZERO


func winner_numbers() -> Array[int]:
	var best := -1
	var winners: Array[int] = []
	for number in scores:
		if scores[number] > best:
			best = scores[number]
			winners = [int(number)]
		elif scores[number] == best:
			winners.append(int(number))
	winners.sort()
	return winners


func score_percent(number: int) -> float:
	return 100.0 * scores.get(number, 0) / total_amount


func _draw() -> void:
	var carried := is_instance_valid(holder)
	var point := Vector2(0, -38) if carried else Vector2.ZERO
	var color := Color("fff0bd")
	draw_arc(Vector2.ZERO, 23 if carried else 16, 0, TAU, 32, color, 2)
	draw_circle(point + Vector2(1, 5), 9, Color(0.2, 0.15, 0.08, 0.25))
	draw_rect(Rect2(point + Vector2(-5, -7), Vector2(10, 15)), Color("23482d"))
	draw_rect(Rect2(point + Vector2(-3, -13), Vector2(6, 7)), Color("4f8136"))
	draw_rect(Rect2(point + Vector2(-3, -15), Vector2(6, 3)), Color("b88e43"))
	var level := 12.0 * remaining / total_amount
	draw_rect(Rect2(point + Vector2(-3, 6 - level), Vector2(6, level)), Color("86b74d"))
	draw_rect(Rect2(point + Vector2(-4, -1), Vector2(8, 5)), Color("edda92"))
	if carried:
		draw_line(point + Vector2(-11, -4), point + Vector2(-8, -4), color, 2)
		draw_line(point + Vector2(8, -4), point + Vector2(11, -4), color, 2)
