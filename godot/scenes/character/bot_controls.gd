extends Node
## Supplies the same intentions as HumanControls; never edits position, ammo or score.

@export var reaction_delay := 0.3
@export var aim_error_degrees := 7.0
@export var decision_interval := 0.2
@export var keep_distance := 300.0
@export var shooting_distance := 270.0

var bottle
var navigation
var opponents: Array = []
var goal := Vector2.ZERO
var target: Node2D
var _movement := Vector2.ZERO
var _aim := Vector2.LEFT
var _fire := false
var _fire_press := false
var _reload_press := false
var _decision_left := 0.0
var _reaction_left := 0.3
var _path := PackedVector2Array()
var _random := RandomNumberGenerator.new()
@onready var actor = get_parent()


func _ready() -> void:
	process_physics_priority = -20
	_random.randomize()


func configure(objective, other_players: Array, paths) -> void:
	bottle = objective
	opponents = other_players
	navigation = paths
	release()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(bottle) or navigation == null:
		return
	if is_instance_valid(target) and not target.is_active():
		target = null
		_set_fire(false)
		_decision_left = 0.0
	_reaction_left = move_toward(_reaction_left, 0.0, delta)
	_decision_left -= delta
	if _decision_left <= 0.0:
		_decision_left = decision_interval
		_decide()
	while not _path.is_empty() and actor.global_position.distance_to(_path[0]) < 7.0:
		_path.remove_at(0)
	_movement = Vector2.ZERO if _path.is_empty() else (
		_path[0] - actor.global_position).normalized()


func _decide() -> void:
	var nearest: Node2D
	var distance := INF
	for opponent in opponents:
		if opponent.is_active():
			var candidate: float = actor.global_position.distance_to(opponent.global_position)
			if candidate < distance:
				distance = candidate
				nearest = opponent
	var next_target: Node2D = nearest
	if is_instance_valid(bottle.holder) and bottle.holder != actor and bottle.holder.is_active():
		next_target = bottle.holder
	if target != next_target:
		target = next_target
		_reaction_left = reaction_delay
	var carrying: bool = bottle.holder == actor
	if actor.is_ghost() or carrying:
		goal = navigation.escape_goal(actor.global_position, nearest.global_position) \
			if is_instance_valid(nearest) and distance < keep_distance else actor.global_position
	elif is_instance_valid(bottle.holder):
		goal = bottle.holder.global_position
	else:
		goal = bottle.global_position
	var can_attack := false
	var can_melee := false
	if is_instance_valid(target) and not actor.is_ghost():
		var offset: Vector2 = target.global_position - actor.global_position
		var query := PhysicsRayQueryParameters2D.create(actor.global_position, target.global_position, 9)
		query.collide_with_areas = true
		query.hit_from_inside = true
		var clear: bool = actor.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
		can_attack = clear and offset.length() < actor.weapon.bullet_range - 40.0
		_aim = offset.normalized().rotated(deg_to_rad(
			_random.randf_range(-aim_error_degrees, aim_error_degrees)))
		can_melee = is_instance_valid(actor.weapon.find_melee_target(_aim))
		can_attack = can_attack or can_melee
		if not carrying and bottle.holder == target and clear and offset.length() < shooting_distance:
			goal = actor.global_position
	_path = navigation.route(actor.global_position, goal) \
		if actor.global_position.distance_to(goal) > 7.0 else PackedVector2Array()
	if actor.is_ghost():
		_set_fire(false)
		_reload_press = false
		return
	if actor.weapon.ammunition == 0 and not can_melee and not actor.weapon.is_reloading():
		_reload_press = true
	_set_fire(can_attack and _reaction_left == 0.0 and (can_melee or (
		not actor.weapon.is_reloading() and actor.weapon.ammunition > 0)))


func _set_fire(pressed: bool) -> void:
	if pressed and not _fire:
		_fire_press = true
	_fire = pressed


func movement() -> Vector2:
	return _movement


func aim(_position: Vector2) -> Vector2:
	return _aim


func dash_just_pressed() -> bool:
	return false


func fire_pressed() -> bool:
	return _fire


func consume_fire_press() -> bool:
	var pressed := _fire_press
	_fire_press = false
	return pressed


func consume_reload_press() -> bool:
	var pressed := _reload_press
	_reload_press = false
	return pressed


func release() -> void:
	_movement = Vector2.ZERO
	_fire = false
	_fire_press = false
	_reload_press = false
	_path.clear()
	_decision_left = 0.0
	_reaction_left = reaction_delay
