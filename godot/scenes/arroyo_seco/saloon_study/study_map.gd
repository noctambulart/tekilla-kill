extends Node2D
## A bounded art/physics study. V5 stays available until this treatment is accepted.

const ROOT := "res://scenes/arroyo_seco/saloon_study/"
const OLD_ART := "res://scenes/arroyo_seco/assets/village/"
var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "layout.json"))
var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/provenance.json"))
var show_bottle_marker := false
var solids: Array[PackedVector2Array] = []
var prop_nodes: Dictionary = {}
var wall_textures: Dictionary = {}
var asset_paths: Dictionary = {}
var annotations := false:
	set(value):
		annotations = value
		queue_redraw()


class WallArt extends Node2D:
	var extent := Vector2.ZERO
	var fence := false
	var front := false
	var textures: Dictionary = {}

	func _draw() -> void:
		var horizontal := extent.x > extent.y
		var kind := ("fence_h" if horizontal else "fence_v") if fence else ("front" if front else ("wall_h" if horizontal else "wall_v"))
		var texture: Texture2D = textures[kind]
		# Uniform scale and cropped final modules: never stretch wood grain or windows.
		var factor := (20.0 if fence else (28.0 if front else 21.0)) / texture.get_height() if horizontal else 16.0 / texture.get_width()
		var length := extent.x if horizontal else extent.y + 10
		var axis_pixels := float(texture.get_width() if horizontal else texture.get_height())
		var margin := axis_pixels * (0.18 if fence else (0.08 if front else 0.025))
		var tile_length := (axis_pixels - margin * 2) * factor
		for index in range(ceili(length / tile_length)):
			var at := index * tile_length
			var piece := minf(tile_length, length - at)
			var size := Vector2(piece, texture.get_height() * factor) if horizontal else Vector2(texture.get_width() * factor, piece)
			var start := Vector2(-extent.x / 2 + at, extent.y / 2 - size.y) if horizontal else Vector2(-size.x / 2, -extent.y / 2 - 10 + at)
			var destination := Rect2(start, size)
			var source := Rect2(Vector2(margin, 0) if horizontal else Vector2(0, margin), size / factor)
			draw_texture_rect_region(texture, Rect2(start + Vector2(4, 3), size), source, Color(0.24, 0.16, 0.11, 0.16))
			draw_texture_rect_region(texture, destination, source)
		var post: Texture2D = textures["post"]
		var post_size := Vector2(post.get_size()) * (13.0 if fence else 18.0) / post.get_width()
		var physical_length := extent.x if horizontal else extent.y
		var count := maxi(1, ceili(physical_length / 96.0))
		for index in range(count + 1):
			var at := float(index) * physical_length / count
			var point := Vector2(-extent.x / 2 + at, extent.y / 2) if horizontal else Vector2(0, -extent.y / 2 + at)
			draw_texture_rect(post, Rect2(point - Vector2(post_size.x / 2, post_size.y), post_size), false)


func world_size() -> Vector2:
	return Vector2(layout["size"][0], layout["size"][1])


func tile_point(point: Array) -> Vector2:
	# The review/trial contract accepts points; this study stores world units.
	return Vector2(point[0], point[1])


func rect_from(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2], values[3])


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["wall_h", "wall_v", "post", "front", "fence_h", "fence_v"]:
		wall_textures[kind] = load(ROOT + "assets/" + kind + ".png")
	_add_ground()
	var room := rect_from(layout.room)
	var north: Array = layout.doors.north
	var east: Array = layout.doors.east
	var south: Array = layout.doors.south
	_add_wall("north-west", Rect2(room.position.x, room.position.y - 6, north[0] - room.position.x, 12))
	_add_wall("north-east", Rect2(north[1], room.position.y - 6, room.end.x - north[1], 12))
	_add_wall("west", Rect2(room.position.x - 6, room.position.y, 12, room.size.y))
	_add_wall("east-back", Rect2(room.end.x - 6, room.position.y, 12, east[0] - room.position.y))
	_add_wall("east-front", Rect2(room.end.x - 6, east[1], 12, room.end.y - east[1]))
	_add_wall("south-west", Rect2(room.position.x, room.end.y - 6, south[0] - room.position.x, 12))
	_add_wall("south-east", Rect2(south[1], room.end.y - 6, room.end.x - south[1], 12))
	for index in range(layout.fences.size()):
		_add_wall("yard-%d" % index, rect_from(layout.fences[index]), true)
	# A plainly visible fence bounds this review area.
	for values in [[24, 24, 784, 8], [24, 24, 8, 648], [800, 24, 8, 648], [24, 664, 784, 8]]:
		_add_wall("limit-%d" % get_child_count(), rect_from(values), true)
	for data in layout.props:
		_add_prop(data)
	for data in layout.decor:
		_add_prop(data, false)
	queue_redraw()


func _add_ground() -> void:
	_add_room_ground(rect_from(layout.room), layout.doors, "stone", true)


func _floor_path(kind: String) -> String:
	return ROOT + "assets/" + kind + ".png"


func _add_room_ground(room: Rect2, doors: Dictionary, floor_kind: String, base_layer: bool) -> void:
	var ground := Polygon2D.new()
	ground.name = "Ground"
	ground.z_index = -1000
	var size := world_size()
	ground.polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	ground.uv = PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2.ONE, Vector2(0, 1)])
	# A one-pixel white texture gives normalized UVs to this world-space material.
	var pixel := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	pixel.fill(Color.WHITE)
	ground.texture = ImageTexture.create_from_image(pixel)
	var material := ShaderMaterial.new()
	material.shader = load(ROOT + "ground.gdshader")
	material.set_shader_parameter("sand", load(ROOT + "assets/sand.png"))
	material.set_shader_parameter("stone", load(_floor_path(floor_kind)))
	material.set_shader_parameter("base_layer", base_layer)
	material.set_shader_parameter("floor_kind", 0 if floor_kind == "stone" else (1 if floor_kind == "wood" else 2))
	material.set_shader_parameter("world_size", size)
	var r := room
	material.set_shader_parameter("room", Vector4(r.position.x, r.position.y, r.end.x, r.end.y))
	for side in ["north", "east", "south", "west"]:
		var opening: Array = doors.get(side, [-10000, -10000])
		material.set_shader_parameter(side + "_door", Vector2(opening[0], opening[1]))
	ground.material = material
	add_child(ground)


func _solid(parent: Node2D, points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	body.add_child(shape)
	parent.add_child(body)
	var world := PackedVector2Array()
	for point in points:
		world.append(point + parent.position)
	solids.append(world)


func _rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


func _add_wall(id: String, rect: Rect2, fence := false, front := false) -> void:
	var wall := WallArt.new()
	wall.name = id
	wall.position = rect.get_center()
	wall.extent = rect.size
	wall.fence = fence
	wall.front = front or id.begins_with("south-")
	wall.textures = wall_textures
	wall.z_index = int(rect.end.y)
	add_child(wall)
	_solid(wall, _rect_points(Rect2(-rect.size / 2, rect.size)))


func _add_prop(data: Dictionary, blocking := true) -> void:
	var kind: String = data.kind
	var imported: bool = manifest.assets.has(kind)
	var path: String = asset_paths.get(kind, ROOT + "assets/" + kind + ".png" if imported else OLD_ART + kind + ".png")
	var texture: Texture2D = load(path)
	var size := Vector2(texture.get_size()) / 3.0
	if data.has("width"):
		size *= float(data.width) / size.x
	var top_left := tile_point(data.position)
	var anchor := top_left + Vector2(size.x / 2, size.y)
	var prop := Node2D.new()
	prop.name = data.get("id", kind)
	prop.position = anchor
	prop.z_index = roundi(anchor.y)
	if kind == "house" or kind.begins_with("house_"):
		# The facade ends before the protruding steps at the bottom of the image.
		prop.z_index -= 20
	prop.set_meta("planned_breakable", data.get("breakable", kind in ["crate", "pot", "chair_n", "chair_s", "chair_w", "chair_e"]))
	add_child(prop)
	var sprite := Sprite2D.new()
	sprite.name = "Art"
	sprite.texture = texture
	sprite.scale = Vector2.ONE * size.x / texture.get_width()
	sprite.position = Vector2(0, -size.y / 2)
	prop.add_child(sprite)
	# Project the same silhouette onto the floor, never its rectangular canvas.
	var shadow := Sprite2D.new()
	shadow.name = prop.name + "Shadow"
	shadow.texture = texture
	shadow.position = anchor + Vector2(5, -size.y * 0.13 + 3)
	shadow.scale = sprite.scale * Vector2(1.04, 0.30)
	shadow.skew = -0.3
	shadow.modulate = Color(0.27, 0.18, 0.13, 0.25)
	shadow.z_index = -900
	add_child(shadow)
	if not blocking:
		return
	prop_nodes[data.id] = prop
	var origin := -Vector2(size.x / 2, size.y)
	if data.has("footprints"):
		for values in data.footprints:
			var footprint := rect_from(values)
			footprint.position += origin
			_solid(prop, _rect_points(footprint))
	elif kind == "house" or kind.begins_with("house_"):
		var w := size.x
		var h := size.y
		# Ground-level facade and steps. Roof overhang and transparent corners are free.
		var points := PackedVector2Array([Vector2(14, h * 0.46), Vector2(w - 14, h * 0.46),
			Vector2(w - 14, h - 20), Vector2(w * 0.62, h - 20), Vector2(w * 0.62, h),
			Vector2(w * 0.38, h), Vector2(w * 0.38, h - 20), Vector2(14, h - 20)])
		for index in range(points.size()):
			points[index] += origin
		_solid(prop, points)
	elif kind == "bar":
		var front_depth := size.y * 0.28
		_solid(prop, _rect_points(Rect2(origin + Vector2(0, size.y - front_depth), Vector2(size.x, front_depth))))
		_solid(prop, _rect_points(Rect2(origin + Vector2(2, 4), Vector2(14, size.y - front_depth - 4))))
	else:
		# Short front-facing bases leave space behind elevated seats/tabletops.
		var base_height := size.y * (0.55 if kind in ["barrel", "pot"] else 0.38)
		_solid(prop, _rect_points(Rect2(Vector2(-size.x / 2 + 3, -base_height), Vector2(size.x - 6, base_height - 2))))


func _draw() -> void:
	var r := rect_from(layout.rug)
	draw_rect(r, Color("a6513f"))
	draw_rect(r.grow(-3), Color("e3b66c"), false, 2)
	for x in range(10, int(r.size.x), 15):
		var p := r.position + Vector2(x, r.size.y / 2)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(4, 0), p + Vector2(0, 4), p + Vector2(-4, 0)]), Color("e3b66c"))
	if annotations:
		draw_rect(rect_from(layout.room), Color(0.2, 0.8, 0.6, 0.10))
		for polygon in solids:
			draw_colored_polygon(polygon, Color(0.85, 0.2, 0.14, 0.32))
			draw_polyline(polygon + PackedVector2Array([polygon[0]]), Color(0.65, 0.15, 0.1, 0.8), 1)
