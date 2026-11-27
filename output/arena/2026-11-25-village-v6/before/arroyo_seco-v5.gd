extends Node2D
## The same editable geometry drives the overhead artwork and solid obstacles.

const TILE := 32.0
const DATA_PATH := "res://scenes/arroyo_seco/layout.json"
const ART_PATH := "res://scenes/arroyo_seco/assets/village/"
const KINDS := ["crate", "barrel", "table", "couch", "chair", "pot", "cart", "counter",
	"house_wood", "house_adobe", "goods", "trough", "cactus", "rocks", "tools", "mugs",
	"crate_broken", "chair_broken", "pot_broken", "store_counter"]

@export var show_bottle_marker := true
var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
var sprite_textures: Dictionary = {}
var shadow_textures: Dictionary = {}
var annotations := false:
	set(value):
		annotations = value
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in KINDS:
		sprite_textures[kind] = load(ART_PATH + kind + ".png")
	sprite_textures["shelf"] = sprite_textures["goods"]
	for kind in sprite_textures:
		var silhouette: Image = sprite_textures[kind].get_image()
		silhouette.convert(Image.FORMAT_RGBA8)
		for y in silhouette.get_height():
			for x in silhouette.get_width():
				silhouette.set_pixel(x, y, Color(0.22, 0.16, 0.10, silhouette.get_pixel(x, y).a * 0.12))
		shadow_textures[kind] = ImageTexture.create_from_image(silhouette)
	for wall in layout.walls:
		_add_solid(wall.id, tile_rect(wall.rect), false)
	for prop in layout.props:
		_add_solid(prop.id, tile_rect(prop.rect), prop.breakable)
	queue_redraw()


func world_size() -> Vector2:
	return tile_point(layout.size_tiles)


func tile_point(point: Array) -> Vector2:
	return Vector2(float(point[0]), float(point[1])) * TILE


func tile_rect(values: Array) -> Rect2:
	return Rect2(float(values[0]) * TILE, float(values[1]) * TILE,
		float(values[2]) * TILE, float(values[3]) * TILE)


func polygon_points(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(tile_point(point))
	return result


func _add_solid(id: String, rect: Rect2, breakable: bool) -> void:
	var body := StaticBody2D.new()
	body.name = id
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("planned_breakable", breakable)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	collider.position = rect.get_center()
	body.add_child(collider)
	add_child(body)


func _draw() -> void:
	if sprite_textures.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, world_size()), Color("e6bd7e"))
	var boundary := polygon_points(layout.perimeter)
	draw_colored_polygon(boundary, Color("f0cf91"))
	_draw_sand(boundary)
	for decor in layout.decor:
		if decor.kind == "boardwalk":
			_draw_boardwalk(tile_rect(decor.rect))
	for building in layout.buildings:
		_draw_floor(building)
	for decor in layout.decor:
		var rect := tile_rect(decor.rect)
		if decor.kind == "rug":
			_draw_rug(rect)
		elif sprite_textures.has(decor.kind):
			draw_texture_rect(sprite_textures[decor.kind], rect, false)
	for prop in layout.props:
		_draw_prop(prop)
	for wall in layout.walls:
		_draw_wall(wall)
	if show_bottle_marker:
		_draw_bottle(tile_point(layout.bottle))
	if annotations:
		_draw_annotations()


func _draw_sand(boundary: PackedVector2Array) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 600925
	var size := world_size()
	for i in range(int(size.x * size.y / 1700)):
		var point := Vector2(random.randi_range(3, int(size.x) - 4), random.randi_range(3, int(size.y) - 4))
		if Geometry2D.is_point_in_polygon(point, boundary):
			draw_rect(Rect2(point, Vector2(random.randi_range(1, 3), 1)), Color(0.70, 0.51, 0.28, 0.12))
	for x in [29.0, 34.5]:
		for band in range(6):
			var color := Color(0.72, 0.51, 0.29, 0.012 * (6 - band))
			# Disjoint strips keep the center from accumulating six alpha layers.
			draw_rect(Rect2(Vector2(x * TILE - band * 2, 0), Vector2(2, size.y)), color)
			if band > 0:
				draw_rect(Rect2(Vector2(x * TILE + band * 2, 0), Vector2(2, size.y)), color)
	for y in [9.5, 30.5]:
		draw_rect(Rect2(Vector2(2 * TILE, y * TILE), Vector2(60 * TILE, 2)), Color(0.73, 0.54, 0.32, 0.08))


func _floor_color(floor_kind: String, ratio: float) -> Color:
	if floor_kind == "wood":
		return Color("ae8050").lerp(Color("c79861"), ratio)
	if floor_kind == "earth":
		return Color("c49c68").lerp(Color("d3ad78"), ratio)
	return Color("809ba9").lerp(Color("91a8b1"), ratio)


func _draw_floor(building: Dictionary) -> void:
	var polygon := polygon_points(building.polygon)
	var minimum := polygon[0]
	var maximum := polygon[0]
	for point in polygon:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	var colors := PackedColorArray()
	for point in polygon:
		colors.append(_floor_color(building.floor, (point.y - minimum.y) / maxf(1, maximum.y - minimum.y)))
	draw_polygon(polygon, colors)
	# Quiet floor joints clipped to the polygon, never bleeding through walls.
	var spacing := 16 if building.floor == "wood" else 32
	for y in range(int(minimum.y) + spacing, int(maximum.y), spacing):
		var intersections: Array[float] = []
		for index in range(polygon.size()):
			var a := polygon[index]
			var b := polygon[(index + 1) % polygon.size()]
			if minf(a.y, b.y) <= y and y < maxf(a.y, b.y):
				intersections.append(a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
		intersections.sort()
		for index in range(0, intersections.size() - 1, 2):
			draw_line(Vector2(intersections[index], y), Vector2(intersections[index + 1], y), Color(0.28, 0.36, 0.39, 0.09))
	if building.floor == "stone":
		for y in range(int(minimum.y), int(maximum.y), 32):
			for x in range(int(minimum.x) + 32, int(maximum.x), 32):
				if Geometry2D.is_point_in_polygon(Vector2(x, y + 16), polygon):
					draw_line(Vector2(x, y + 2), Vector2(x, y + 30), Color(0.28, 0.36, 0.39, 0.065))
	_draw_floor_fades(building, polygon, minimum, maximum)


func _draw_floor_fades(building: Dictionary, polygon: PackedVector2Array, minimum: Vector2, maximum: Vector2) -> void:
	if building.floor == "earth":
		return
	for edge_key in building.doors:
		var edge := int(edge_key)
		var a := polygon[edge]
		var b := polygon[(edge + 1) % polygon.size()]
		var direction := (b - a).normalized()
		var inward := Vector2(-direction.y, direction.x)
		for span in building.doors[edge_key]:
			var first := Vector2(span[0] * TILE, a.y) if is_equal_approx(a.y, b.y) else Vector2(a.x, span[0] * TILE)
			var last := Vector2(span[1] * TILE, a.y) if is_equal_approx(a.y, b.y) else Vector2(a.x, span[1] * TILE)
			var color := _floor_color(building.floor, clampf((first.y - minimum.y) / maxf(1, maximum.y - minimum.y), 0, 1))
			for band in range(12):
				var near := -inward * band * 4.0
				var far := -inward * (band + 1) * 4.0
				var tint := color
				tint.a = pow(1.0 - float(band) / 12.0, 1.5) * 0.86
				draw_colored_polygon(PackedVector2Array([first + near, last + near, last + far, first + far]), tint)


func _draw_boardwalk(rect: Rect2) -> void:
	draw_rect(rect, Color("b68551"))
	for y in range(int(rect.position.y) + 8, int(rect.end.y), 10):
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.36, 0.22, 0.13, 0.22))


func _draw_wall(wall: Dictionary) -> void:
	var rect := tile_rect(wall.rect)
	if wall.material == "house":
		draw_texture_rect(sprite_textures[wall.kind], rect, false)
		return
	var horizontal := rect.size.x >= rect.size.y
	var length := rect.size.x if horizontal else rect.size.y
	if wall.material == "rock":
		for at in range(0, int(length), 32):
			var step := Vector2(at, 0) if horizontal else Vector2(0, at)
			var size := Vector2(minf(32, length - at), rect.size.y) if horizontal else Vector2(rect.size.x, minf(32, length - at))
			var piece := Rect2(rect.position + step, size)
			if horizontal:
				draw_texture_rect(sprite_textures["rocks"], piece, false)
			else:
				draw_set_transform(piece.get_center(), PI / 2)
				var rotated_size := Vector2(size.y, size.x)
				draw_texture_rect(sprite_textures["rocks"], Rect2(-rotated_size / 2, rotated_size), false)
				draw_set_transform(Vector2.ZERO)
		return
	if wall.material == "fence":
		draw_rect(rect, Color("9c7144"))
		draw_rect(rect.grow(-2), Color("c99b5d"))
		for at in range(0, int(length) + 1, 32):
			var point := rect.position + (Vector2(at, rect.size.y / 2) if horizontal else Vector2(rect.size.x / 2, at))
			_draw_post(point, 11)
		return
	draw_rect(rect.grow(1), Color("6b4b31"))
	draw_rect(rect, Color("c3a377"))
	draw_rect(rect.grow(-2), Color("e2c795"))
	if horizontal:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("b38552"))
		draw_line(rect.position + Vector2(1, 4), rect.position + Vector2(rect.size.x - 1, 4), Color("f5dbac"))
	else:
		draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), Color("b38552"))
		draw_line(rect.position + Vector2(4, 1), rect.position + Vector2(4, rect.size.y - 1), Color("f5dbac"))
	for at in range(0, int(length) + 1, 64):
		var point := rect.position + (Vector2(at, rect.size.y / 2) if horizontal else Vector2(rect.size.x / 2, at))
		_draw_post(point, 16)
	_draw_post(rect.get_center() + (Vector2(length / 2, 0) if horizontal else Vector2(0, length / 2)), 16)


func _draw_post(point: Vector2, width: float) -> void:
	var rect := Rect2(point - Vector2.ONE * width / 2, Vector2(width, width))
	draw_rect(rect.grow(1), Color("6b4b31"))
	draw_rect(rect, Color("ae7c49"))
	draw_rect(Rect2(rect.position + Vector2(2, 1), Vector2(width - 4, 5)), Color("e8ba77"))


func _draw_prop(prop: Dictionary) -> void:
	var rect := tile_rect(prop.rect)
	var kind: String = prop.kind
	if prop.get("visual_state", "intact") == "broken" and sprite_textures.has(kind + "_broken"):
		kind += "_broken"
	if not sprite_textures.has(kind):
		return
	var texture: Texture2D = sprite_textures[kind]
	var shadow: Texture2D = shadow_textures[kind]
	if kind in ["counter", "shelf", "goods", "mugs", "tools"] and rect.size.y > rect.size.x:
		draw_set_transform(rect.get_center() + Vector2(-2, 3), PI / 2)
		draw_texture_rect(shadow, Rect2(-Vector2(rect.size.y, rect.size.x) / 2, Vector2(rect.size.y, rect.size.x)), false)
		draw_set_transform(rect.get_center(), PI / 2)
		draw_texture_rect(texture, Rect2(-Vector2(rect.size.y, rect.size.x) / 2, Vector2(rect.size.y, rect.size.x)), false)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture_rect(shadow, Rect2(rect.position + Vector2(-2, 3), rect.size), false)
		draw_texture_rect(texture, rect, false)


func _draw_rug(rect: Rect2) -> void:
	draw_rect(rect, Color("a14e3d"))
	draw_rect(rect.grow(-3), Color("ddb46d"), false, 2)
	for x in range(10, int(rect.size.x) - 8, 20):
		var center := rect.position + Vector2(x, rect.size.y / 2)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -5), center + Vector2(5, 0), center + Vector2(0, 5), center + Vector2(-5, 0)]), Color("dbad62"))


func _draw_bottle(point: Vector2) -> void:
	draw_rect(Rect2(point + Vector2(-5, -7), Vector2(10, 15)), Color("315d2b"))
	draw_rect(Rect2(point + Vector2(-3, -13), Vector2(6, 7)), Color("4f8136"))
	draw_rect(Rect2(point + Vector2(-3, -15), Vector2(6, 3)), Color("b88e43"))
	draw_rect(Rect2(point + Vector2(-4, -1), Vector2(8, 6)), Color("edda92"))
	draw_rect(Rect2(point + Vector2(-3, -6), Vector2(2, 5)), Color("86b74d"))


func _draw_annotations() -> void:
	for route in layout.routes:
		draw_polyline(polygon_points(route.points), Color("b05c46") if route.id in ["saloon", "west"] else Color("427f8b"), 2)
	for building in layout.buildings:
		draw_string(ThemeDB.fallback_font, tile_point(building.label), building.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("30291f"))
	for label in layout.labels:
		draw_string(ThemeDB.fallback_font, tile_point(label.position), label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("564c33"))
	for index in range(layout.spawns.size()):
		var point := tile_point(layout.spawns[index])
		draw_string(ThemeDB.fallback_font, point + Vector2(-8, -18), "J%d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("243b42"))
