extends Node2D
## The layout is authoritative for both the overhead art and physics obstacles.

const TILE := 32.0
const DATA_PATH := "res://scenes/arroyo_seco/layout.json"
const ATLAS := preload("res://scenes/arroyo_seco/assets/terrain_atlas.png")
const ENVIRONMENT := preload("res://scenes/arroyo_seco/assets/environment-v4.png")
const SPRITE_KINDS := ["crate", "barrel", "table", "couch", "chair", "pot", "cart", "counter"]
static var _sprite_region_cache: Array[Rect2] = []

var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
var sprite_textures: Dictionary = {}
var annotations := false:
	set(value):
		annotations = value
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_sprite_regions()
	for wall in layout.walls:
		_add_solid(wall.id, tile_rect(wall.rect), false)
	for prop in layout.props:
		_add_solid(prop.id, tile_rect(prop.rect), prop.breakable)


func world_size() -> Vector2:
	return tile_point(layout.size_tiles)


func _load_sprite_regions() -> void:
	# The generated sheet has alpha padding. Read each cell's occupied bounds so
	# padding never changes the sprite's drawn footprint or its physics rectangle.
	if _sprite_region_cache.is_empty():
		var sheet := ENVIRONMENT.get_image()
		for index in range(SPRITE_KINDS.size()):
			var column := index % 4
			var row := floori(index / 4.0)
			var x0 := roundi(sheet.get_width() * column / 4.0)
			var x1 := roundi(sheet.get_width() * (column + 1) / 4.0)
			var y0 := roundi(sheet.get_height() * row / 2.0)
			var y1 := roundi(sheet.get_height() * (row + 1) / 2.0)
			_sprite_region_cache.append(_visible_region(sheet, Rect2i(x0,y0,x1-x0,y1-y0)))
	for index in range(SPRITE_KINDS.size()):
		var texture := AtlasTexture.new()
		texture.atlas = ENVIRONMENT
		texture.region = _sprite_region_cache[index]
		sprite_textures[SPRITE_KINDS[index]] = texture
	sprite_textures["shelf"] = sprite_textures["counter"]


func _visible_region(image: Image, cell: Rect2i) -> Rect2:
	# Ignore almost-transparent remnants, which get_used_rect includes. This reads
	# bounds only: the source sheet and its original alpha pixels are unchanged.
	var minimum := cell.end
	var maximum := cell.position
	for y in range(cell.position.y, cell.end.y):
		for x in range(cell.position.x, cell.end.x):
			if image.get_pixel(x,y).a >= .5:
				minimum = minimum.min(Vector2i(x,y))
				maximum = maximum.max(Vector2i(x,y))
	if minimum.x > maximum.x or minimum.y > maximum.y:
		push_error("Cellule de sprite vide : %s" % cell)
		return Rect2(cell)
	minimum = (minimum-Vector2i.ONE).max(cell.position)
	maximum = (maximum+Vector2i.ONE*2).min(cell.end)
	return Rect2(Vector2(minimum),Vector2(maximum-minimum))


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
	var boundary := polygon_points(layout.perimeter)
	draw_colored_polygon(boundary, Color("f1d88e"))
	_draw_sand(boundary)
	for building in layout.buildings:
		_draw_floor(building)
	# Hard shadows fall consistently down-left, below the solid obstacle artwork.
	for wall in layout.walls:
		var rect := tile_rect(wall.rect)
		draw_rect(Rect2(rect.position + Vector2(-6, 8), rect.size), Color(0.18, 0.18, 0.14, 0.20))
	for prop in layout.props:
		var rect := tile_rect(prop.rect)
		draw_rect(Rect2(rect.position + Vector2(-4, 6), rect.size), Color(0.18, 0.18, 0.14, 0.18))
	for decor in layout.decor:
		if decor.kind == "rug":
			_draw_rug(tile_rect(decor.rect))
	for prop in layout.props:
		_draw_prop(prop)
	for wall in layout.walls:
		_draw_wall(wall)
	_draw_thresholds()
	_draw_bottle(tile_point(layout.bottle))
	if annotations:
		_draw_annotations()


func _draw_sand(boundary: PackedVector2Array) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 270323
	# Sparse pixel clusters, avoiding the noisy diagonal texture of the old atlas.
	var size := world_size()
	for i in range(int(size.x * size.y / 500)):
		var point := Vector2(random.randi_range(2, int(size.x)-4), random.randi_range(2, int(size.y)-4))
		if Geometry2D.is_point_in_polygon(point, boundary):
			var color := Color("dac480") if i % 4 == 0 else Color("e8d08a")
			draw_rect(Rect2(point, Vector2(random.randi_range(1, 4), 1)), color)
	# A slightly paler, irregular main street connects south plaza and north exit.
	var street := PackedVector2Array([Vector2(480, 624), Vector2(650, 624),
		Vector2(760, 514), Vector2(742, 305), Vector2(659, 238),
		Vector2(650, 24), Vector2(552, 24), Vector2(537, 233),
		Vector2(491, 329), Vector2(462, 476)])
	for index in range(street.size()):
		street[index] *= 1.5
	draw_colored_polygon(street, Color(0.99, 0.91, 0.67, 0.18))
	for point in [Vector2(44, 152), Vector2(60, 512), Vector2(937, 220),
		Vector2(907, 572), Vector2(406, 602), Vector2(770, 48)]:
		_draw_plant(point * 1.5)


func _draw_floor(building: Dictionary) -> void:
	var polygon := polygon_points(building.polygon)
	var color := Color("9faeae")
	if building.floor == "wood":
		color = Color("a68b58")
	elif building.floor == "earth":
		color = Color("d7c184")
	draw_colored_polygon(polygon, color)
	for y in range(int(layout.size_tiles[1])):
		for x in range(int(layout.size_tiles[0])):
			var point := Vector2(x, y) * TILE
			# Only whole tiles inside the polygon; no texture bleed through doorways.
			var inside := true
			for offset in [Vector2(1, 1), Vector2(31, 1), Vector2(31, 31), Vector2(1, 31)]:
				inside = inside and Geometry2D.is_point_in_polygon(point + offset, polygon)
			if not inside:
				continue
			if building.floor == "stone":
				draw_texture_rect_region(ATLAS, Rect2(point, Vector2(32, 32)),
					Rect2(320, 32, 32, 32), Color(1, 1, 1, .25))
			elif building.floor == "wood":
				for line in range(4):
					draw_line(point + Vector2(0, line * 8), point + Vector2(32, line * 8), Color("8b734c"))
				draw_line(point, point + Vector2(0, 32), Color("8b734c"))


func _draw_wall(wall: Dictionary) -> void:
	var rect := tile_rect(wall.rect)
	if wall.material == "fence":
		draw_rect(rect, Color("735d36"))
		var horizontal := rect.size.x > rect.size.y
		var length := rect.size.x if horizontal else rect.size.y
		for index in range(0, int(length), 24):
			var at := rect.position + (Vector2(index, 0) if horizontal else Vector2(0, index))
			draw_rect(Rect2(at - Vector2(2, 2), Vector2(10, 10)), Color("635638"))
			draw_rect(Rect2(at, Vector2(6, 6)), Color("b59c5d"))
		return
	draw_rect(rect.grow(1), Color("5b635d"))
	draw_rect(rect, Color("a9a88b"))
	draw_rect(rect.grow(-2), Color("c5c3a4"))
	if rect.size.x > rect.size.y:
		for x in range(0, int(rect.size.x)-3, 20):
			var width := minf(18, rect.size.x-x-2)
			draw_rect(Rect2(rect.position+Vector2(x+1,4),Vector2(width,5)),Color("b4b399") if x%40==0 else Color("c6c4a8"))
			draw_rect(Rect2(rect.position+Vector2(x+4,rect.size.y-5),Vector2(minf(7,width),2)),Color("aaa88f"))
		draw_line(rect.position + Vector2(1, 2), rect.position + Vector2(rect.size.x - 1, 2), Color("e3d9b5"), 2)
		for x in range(16, int(rect.size.x), 20):
			draw_line(rect.position + Vector2(x, 2), rect.position + Vector2(x, rect.size.y - 2), Color("97977f"))
	else:
		for y in range(0, int(rect.size.y)-3, 20):
			var height := minf(18, rect.size.y-y-2)
			draw_rect(Rect2(rect.position+Vector2(4,y+1),Vector2(5,height)),Color("b4b399") if y%40==0 else Color("c6c4a8"))
			draw_rect(Rect2(rect.position+Vector2(rect.size.x-5,y+4),Vector2(2,minf(7,height))),Color("aaa88f"))
		draw_line(rect.position + Vector2(2, 1), rect.position + Vector2(2, rect.size.y - 1), Color("e3d9b5"), 2)
		for y in range(16, int(rect.size.y), 20):
			draw_line(rect.position + Vector2(2, y), rect.position + Vector2(rect.size.x - 2, y), Color("97977f"))


func _draw_prop(prop: Dictionary) -> void:
	var rect := tile_rect(prop.rect)
	if not sprite_textures.has(prop.kind):
		return
	var texture: Texture2D = sprite_textures[prop.kind]
	if prop.kind in ["counter","shelf"] and rect.size.y > rect.size.x:
		draw_set_transform(rect.get_center(), PI/2)
		draw_texture_rect(texture, Rect2(-Vector2(rect.size.y,rect.size.x)/2, Vector2(rect.size.y,rect.size.x)),false)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture_rect(texture, rect, false)


func _draw_rug(rect: Rect2) -> void:
	draw_rect(rect, Color("925649"))
	draw_rect(rect.grow(-3), Color("c2a365"), false, 2)
	for x in range(8, int(rect.size.x) - 8, 12):
		var center := rect.position + Vector2(x, rect.size.y / 2)
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-5), center+Vector2(5,0),
			center+Vector2(0,5), center+Vector2(-5,0)]), Color("b9935c"))


func _draw_plant(point: Vector2) -> void:
	draw_rect(Rect2(point + Vector2(-4, 5), Vector2(16, 4)), Color(0.3, 0.3, 0.13, .2))
	draw_rect(Rect2(point + Vector2(-2, -11), Vector2(5, 16)), Color("6e8741"))
	draw_rect(Rect2(point + Vector2(-8, -5), Vector2(7, 4)), Color("7c9447"))
	draw_rect(Rect2(point + Vector2(3, -8), Vector2(7, 4)), Color("7c9447"))
	draw_rect(Rect2(point + Vector2(-8, -9), Vector2(3, 7)), Color("7c9447"))


func _draw_thresholds() -> void:
	for building in layout.buildings:
		for edge_key in building.doors:
			var edge := int(edge_key)
			var a := tile_point(building.polygon[edge])
			var b := tile_point(building.polygon[(edge + 1) % building.polygon.size()])
			for span in building.doors[edge_key]:
				if is_equal_approx(a.y, b.y):
					draw_line(Vector2(span[0] * TILE, a.y), Vector2(span[1] * TILE, a.y), Color("c9bd90"), 3)
				else:
					draw_line(Vector2(a.x, span[0] * TILE), Vector2(a.x, span[1] * TILE), Color("c9bd90"), 3)


func _draw_bottle(point: Vector2) -> void:
	draw_arc(point, 15, 0, TAU, 24, Color("fff0bd"), 2)
	draw_rect(Rect2(point + Vector2(-5, -7), Vector2(10, 15)), Color("315d2b"))
	draw_rect(Rect2(point + Vector2(-3, -13), Vector2(6, 7)), Color("4f8136"))
	draw_rect(Rect2(point + Vector2(-3, -15), Vector2(6, 3)), Color("b88e43"))
	draw_rect(Rect2(point + Vector2(-4, -1), Vector2(8, 6)), Color("edda92"))
	draw_rect(Rect2(point + Vector2(-3, -6), Vector2(2, 5)), Color("86b74d"))


func _draw_annotations() -> void:
	for route in layout.routes:
		draw_polyline(polygon_points(route.points), Color("a34c39") if route.id == "saloon" else Color("3e7382"), 2)
	for building in layout.buildings:
		draw_string(ThemeDB.fallback_font, tile_point(building.label), building.name,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color("30291f"))
	for label in layout.labels:
		draw_string(ThemeDB.fallback_font, tile_point(label.position), label.text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("564c33"))
	for index in range(layout.spawns.size()):
		var point := tile_point(layout.spawns[index])
		draw_arc(point, 14, 0, TAU, 24, Color("3b6778"), 2)
		draw_string(ThemeDB.fallback_font, point + Vector2(-8, -18), "J%d" % (index + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("243b42"))
