extends CharacterBody2D
## One source for possession, integer amounts drunk, drops and pickup arbitration.

signal emptied
signal possession_changed(holder: Node2D)
signal picked_up(new_holder: Node2D)
signal dropped(previous_holder: Node2D, attacker: Node2D)
## Snapshot after initialization, pickup, loss or a change in amounts.
## Consumers use these amounts for presentation; they never count their own score.
signal state_changed(state: Dictionary)

@export_range(1, 60000) var total_amount := 2400
@export_range(1.0, 6000.0) var drinking_rate := 60.0
@export_range(1.0, 80.0, 1.0) var pickup_radius := 28.0
## Match the characters' ground contact so a drop starts in walkable space.
@export var ground_offset := Vector2.ZERO
@export var draw_placeholder := true
@export var throw_distance := 150.0
@export_range(0.01, 2.0, 0.01) var throw_duration := 0.22
@export_range(0.0, 2.0, 0.01) var former_holder_delay := 0.45
@export_range(0.0, 2.0, 0.01) var holder_stun_duration := 0.8

var holder: Node2D
var remaining := 0
var scores: Dictionary = {}
var participants: Array = []
var _sip_remainders: Dictionary = {}
var _pickup_locks: Dictionary = {}
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
	# Same solid core as a character: a throw cannot enter a passage too narrow to follow.
	shape.radius = 8.0
	collider.shape = shape
	collider.position = ground_offset
	add_child(collider)
	_random.randomize()


func configure(players: Array, origin: Vector2) -> void:
	for player in participants:
		if is_instance_valid(player):
			player.damaged.disconnect(_on_character_damaged.bind(player))
	participants = players.duplicate()
	holder = null
	_pickup_locks.clear()
	_throw_time_left = 0.0
	velocity = Vector2.ZERO
	_ended = false
	global_position = origin
	remaining = total_amount
	scores.clear()
	_sip_remainders.clear()
	for player in participants:
		scores[player.player_number] = 0
		_sip_remainders[player.player_number] = 0.0
		player.damaged.connect(_on_character_damaged.bind(player))
	_publish_state()


func _physics_process(delta: float) -> void:
	if _ended:
		return
	for number in _pickup_locks.keys():
		var left := move_toward(float(_pickup_locks[number]), 0.0, delta)
		if left == 0.0:
			_pickup_locks.erase(number)
		else:
			_pickup_locks[number] = left
	if is_instance_valid(holder) and not holder.is_active():
		_on_character_damaged(0, null, holder)
	if is_instance_valid(holder):
		global_position = holder.global_position
		_drink(delta)
	else:
		_advance_throw(delta)
		_try_pickup()
	queue_redraw()


func _try_pickup() -> void:
	if _ended or remaining <= 0 or is_instance_valid(holder):
		return
	var closest := INF
	var candidates: Array = []
	for player in participants:
		if not is_instance_valid(player) or not player.can_pickup_bottle():
			continue
		if _pickup_locks.has(player.player_number):
			continue
		var distance: float = global_position.distance_squared_to(player.global_position)
		if distance > pickup_radius * pickup_radius:
			continue
		# A generous reach must still respect walls and intact cover between feet.
		var query := PhysicsRayQueryParameters2D.create(global_position + ground_offset,
			player.global_position + ground_offset, 1)
		query.hit_from_inside = true
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
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
	_publish_state()
	picked_up.emit(holder)


func _drink(delta: float) -> void:
	if _ended or not is_instance_valid(holder) or not holder.is_active() or delta <= 0.0:
		return
	var number: int = holder.player_number
	_sip_remainders[number] += delta * drinking_rate
	var amount := mini(remaining, floori(_sip_remainders[number] + 0.000001))
	_sip_remainders[number] -= amount
	scores[number] += amount
	remaining -= amount
	if remaining == 0:
		_ended = true
	if amount > 0:
		_publish_state()
	if _ended:
		emptied.emit()


func _on_character_damaged(amount: int, attacker: Node2D, victim: Node2D) -> void:
	if victim != holder or _ended:
		return
	global_position = victim.global_position
	if amount > 0:
		victim.stun(holder_stun_duration)
	if former_holder_delay > 0.0:
		_pickup_locks[victim.player_number] = former_holder_delay
	holder = null
	var direction := Vector2.ZERO
	if is_instance_valid(attacker):
		direction = (attacker.global_position - global_position).normalized()
	_throw_time_left = throw_duration if not direction.is_zero_approx() else 0.0
	velocity = direction * throw_distance / throw_duration
	possession_changed.emit(null)
	_publish_state()
	dropped.emit(victim, attacker)


func get_state() -> Dictionary:
	return {"holder": holder if is_instance_valid(holder) else null,
		"total_amount": total_amount, "remaining": remaining,
		"scores": scores.duplicate(), "empty": remaining == 0}


func _publish_state() -> void:
	state_changed.emit(get_state())
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
	if not draw_placeholder:
		return
	var carried := is_instance_valid(holder)
	var point := Vector2(0, -38) if carried else ground_offset
	var color := Color("fff0bd")
	draw_arc(Vector2.ZERO if carried else ground_offset, 23 if carried else pickup_radius, 0, TAU, 32, color, 2)
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
