extends "res://scenes/arroyo_seco/saloon_study/study_map.gd"
## Full village reuses the accepted study's art, scale and ground footprints.

const FULL_ART := "res://scenes/arroyo_seco/assets/village_v6/"
const DATA_PATH := "res://scenes/arroyo_seco/layout.json"
const BREAKABLE := preload("res://scenes/arroyo_seco/breakable_prop.gd")
@export_range(1, 20) var pot_resistance := 1
@export_range(1, 20) var chair_resistance := 3
@export_range(1, 20) var crate_resistance := 5
var collision_revision := 0
var house_nodes: Array[Node2D] = []


func _init() -> void:
	show_bottle_marker = true
	layout = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	var additions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FULL_ART + "provenance.json"))
	for kind in additions.assets:
		manifest.assets[kind] = additions.assets[kind]
		asset_paths[kind] = FULL_ART + kind + ".png"


func tile_rect(values: Array) -> Rect2:
	return rect_from(values)


func polygon_points(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(tile_point(point))
	return result


func _floor_path(kind: String) -> String:
	return FULL_ART + kind + ".png" if kind in ["wood", "earth"] else super._floor_path(kind)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["wall_h", "wall_v", "post", "front", "fence_h", "fence_v"]:
		wall_textures[kind] = load(ROOT + "assets/" + kind + ".png")
	for index in range(layout.rooms.size()):
		var room: Dictionary = layout.rooms[index]
		_add_room_ground(rect_from(room.rect), room.doors, room.floor, index == 0)
	for wall in layout.walls:
		_add_wall(wall.id, rect_from(wall.rect), wall.fence, wall.get("front", false))
	for prop in layout.props:
		_add_prop(prop)
		if prop.kind == "house" or prop.kind.begins_with("house_"):
			house_nodes.append(prop_nodes[prop.id])
	for decor in layout.decor:
		_add_prop(decor, false)
	queue_redraw()


func _process(delta: float) -> void:
	# Let players remain visible when their feet can pass behind a roof.
	var actors := get_tree().get_nodes_in_group("characters")
	for house in house_nodes:
		var art: Sprite2D = house.get_node("Art")
		var size := Vector2(art.texture.get_size()) * art.scale
		var bounds := Rect2(house.global_position - Vector2(size.x / 2, size.y), size)
		var obscured := false
		for actor in actors:
			if actor.get_world_2d() != get_world_2d():
				continue
			var silhouette := Rect2(actor.global_position + Vector2(-16, -20), Vector2(32, 36))
			# Use the same facade depth as drawing; the steps are not an occluder.
			var foot_depth := roundi(actor.global_position.y + 16)
			if foot_depth < house.z_index and bounds.intersects(silhouette):
				obscured = true
				break
		art.modulate.a = move_toward(art.modulate.a, 0.6 if obscured else 1.0, delta * 4)


func _add_prop(data: Dictionary, blocking := true) -> void:
	super._add_prop(data, blocking)
	if not blocking:
		return
	var prop: Node2D = prop_nodes[data.id]
	if not prop.get_meta("planned_breakable", false):
		return
	var kind: String = "chair" if data.kind.begins_with("chair_") else data.kind
	if kind not in ["pot", "chair", "crate"]:
		return
	var resistance := pot_resistance if kind == "pot" else (chair_resistance if kind == "chair" else crate_resistance)
	for child in prop.get_children():
		if child is StaticBody2D:
			child.set_script(BREAKABLE)
			child.configure(prop, get_node(NodePath(str(prop.name) + "Shadow")), kind, resistance)
			child.destroyed.connect(func():
				collision_revision += 1
				# Keep the development collision overlay in sync with the live map.
				for polygon in child.get_children():
					if polygon is CollisionPolygon2D:
						var points := PackedVector2Array()
						for point in polygon.polygon:
							points.append(point + prop.position)
						solids.erase(points)
				queue_redraw())


func _draw() -> void:
	for rug in layout.rugs:
		var r := rect_from(rug.rect)
		draw_rect(r, Color("a6513f"))
		draw_rect(r.grow(-3), Color("e3b66c"), false, 2)
		for x in range(10, int(r.size.x), 15):
			var p := r.position + Vector2(x, r.size.y / 2)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(4, 0), p + Vector2(0, 4), p + Vector2(-4, 0)]), Color("e3b66c"))
	if show_bottle_marker:
		_draw_bottle(tile_point(layout.bottle))
	if annotations:
		for room in layout.rooms:
			draw_rect(rect_from(room.rect), Color(0.2, 0.8, 0.6, 0.08))
			draw_string(ThemeDB.fallback_font, tile_point(room.rect) + Vector2(24, 30), room.name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("30291f"))
		for polygon in solids:
			draw_colored_polygon(polygon, Color(0.85, 0.2, 0.14, 0.30))
		for route in layout.routes:
			draw_polyline(polygon_points(route.points), Color(0.18, 0.40, 0.43, 0.65), 2)
		for index in range(layout.spawns.size()):
			var point := tile_point(layout.spawns[index]) + Vector2(0, 16)
			draw_string(ThemeDB.fallback_font, point + Vector2(-7, -20), "J%d" % (index + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("30291f"))


func _draw_bottle(point: Vector2) -> void:
	draw_rect(Rect2(point + Vector2(-5, -7), Vector2(10, 15)), Color("315d2b"))
	draw_rect(Rect2(point + Vector2(-3, -13), Vector2(6, 7)), Color("4f8136"))
	draw_rect(Rect2(point + Vector2(-3, -15), Vector2(6, 3)), Color("b88e43"))
	draw_rect(Rect2(point + Vector2(-4, -1), Vector2(8, 6)), Color("edda92"))
	draw_rect(Rect2(point + Vector2(-3, -6), Vector2(2, 5)), Color("86b74d"))
