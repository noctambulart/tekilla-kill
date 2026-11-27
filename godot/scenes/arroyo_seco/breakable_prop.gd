extends StaticBody2D
## Owns the intact footprint; broken art is purely visual.

signal destroyed

var health := 25
var broken := false
var kind := "pot"
var _art: Sprite2D
var _shadow: Sprite2D
var _shot_area: Area2D
var _visible_extent := 24.0
var _visible_area := 576.0
var _ground_anchor := Vector2.ZERO
var _shadow_ground_y := 0.0
var _flash := 0.0


func configure(prop: Node2D, shadow: Sprite2D, type: String, resistance: int) -> void:
	kind = type
	health = resistance * 25
	_art = prop.get_node("Art")
	_shadow = shadow
	var used := _art.texture.get_image().get_used_rect()
	var visible := Vector2(used.size) * _art.scale
	_visible_extent = maxf(visible.x, visible.y)
	_visible_area = visible.x * visible.y
	_ground_anchor = _art.position + Vector2(
		used.get_center().x - _art.texture.get_width() / 2.0,
		used.end.y - _art.texture.get_height() / 2.0) * _art.scale
	_shadow_ground_y = _shadow.position.y + _art.texture.get_height() * _art.scale.y * 0.13
	add_to_group("breakable_props")
	if kind != "crate":
		add_to_group("dash_over_props")
	# Shots meet the visible object; feet keep the accepted ground footprint.
	_shot_area = Area2D.new()
	_shot_area.name = "ShotTarget"
	_shot_area.collision_layer = 8
	_shot_area.collision_mask = 0
	_shot_area.monitoring = false
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = _art.texture.get_size() * _art.scale * Vector2(0.85, 1.0)
	collider.shape = rectangle
	collider.position = _art.position
	_shot_area.add_child(collider)
	add_child(_shot_area)


func take_damage(amount: int, _attacker: Node2D) -> void:
	if broken or amount <= 0:
		return
	health = maxi(0, health - amount)
	_flash = 0.12
	if health > 0:
		return
	broken = true
	collision_layer = 0
	_shot_area.collision_layer = 0
	for child in get_children():
		if child is CollisionPolygon2D or child is CollisionShape2D:
			child.set_deferred("disabled", true)
	var texture: Texture2D = load("res://scenes/arroyo_seco/assets/village/" + kind + "_broken.png")
	_art.texture = texture
	var used := texture.get_image().get_used_rect()
	# Keep a comparable visual envelope as the object collapses sideways:
	# neither the dominant dimension nor its bounding area should shrink.
	var extent_scale := _visible_extent / maxi(used.size.x, used.size.y)
	var area_scale := sqrt(_visible_area / float(used.size.x * used.size.y))
	_art.scale = Vector2.ONE * maxf(extent_scale, area_scale)
	_art.position = _ground_anchor - Vector2(
		used.get_center().x - texture.get_width() / 2.0,
		used.end.y - texture.get_height() / 2.0) * _art.scale
	_shadow.texture = texture
	_shadow.scale = _art.scale * Vector2(1.04, 0.30)
	_shadow.position.y = _shadow_ground_y - texture.get_height() * _art.scale.y * 0.13
	get_parent().set_meta("planned_breakable", false)
	destroyed.emit()


func _process(delta: float) -> void:
	_flash = move_toward(_flash, 0.0, delta)
	_art.modulate = Color.WHITE.lerp(Color(1.8, 1.5, 1.1), _flash / 0.12)
