extends RefCounted
## Native rendering of the approved V10 bottle and thin oval frame.

var full: ImageTexture
var empty: ImageTexture
var image_size: Vector2


func _init() -> void:
	var original := load("res://scenes/intro/assets/bottle.png") as Texture2D
	var image := original.get_image()
	image = image.get_region(image.get_used_rect())
	image.convert(Image.FORMAT_RGBA8)
	image_size = image.get_size()
	full = ImageTexture.create_from_image(image)
	var glass := image.duplicate() as Image
	for y in range(glass.get_height()):
		for x in range(glass.get_width()):
			var pixel := glass.get_pixel(x, y)
			var decor := y < glass.get_height() * 0.15 or (
				pixel.r > 155.0 / 255.0 and pixel.b < 105.0 / 255.0
				and (pixel.g < 100.0 / 255.0 or pixel.r > pixel.g * 0.86))
			if not decor and pixel.a > 0.0:
				var pale := pixel.lerp(Color(210.0 / 255, 226.0 / 255, 165.0 / 255, pixel.a), 0.77)
				pale.a *= 0.68
				glass.set_pixel(x, y, pale)
	empty = ImageTexture.create_from_image(glass)


func bottle(canvas: CanvasItem, center: Vector2, height: float, fill: float) -> void:
	fill = clampf(fill, 0.0, 1.0)
	var size := Vector2(height * image_size.x / image_size.y, height)
	var rectangle := Rect2(center - size / 2.0, size)
	canvas.draw_texture_rect(empty, rectangle, false)
	if fill > 0.0:
		var source := Rect2(0, image_size.y * (1.0 - fill), image_size.x, image_size.y * fill)
		var destination := Rect2(rectangle.position + Vector2(0, height * (1.0 - fill)),
			Vector2(size.x, height * fill))
		canvas.draw_texture_rect_region(full, destination, source)


func _oval(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(96):
		points.append(center + Vector2(cos(i * TAU / 96.0), sin(i * TAU / 96.0)) * radius)
	canvas.draw_colored_polygon(points, color)


func frame(canvas: CanvasItem, center: Vector2, fill: float) -> void:
	var scale := 88.0 / 55.0 / 3.0
	for layer in [[27, 39, "492b1c"], [26, 38, "c69450"], [25, 37, "92582e"],
		[24, 36, "614024"], [23, 35, "d9b071"], [22, 34, "d5ad74"]]:
		_oval(canvas, center, Vector2(layer[0], layer[1]) * scale, Color(layer[2]))
	for i in range(12):
		var line := PackedVector2Array()
		for step in range(8):
			var angle := i * PI / 6.0 + 0.025 + step * 0.195 / 7.0
			line.append(center + Vector2(cos(angle) * 25, sin(angle) * 37) * scale)
		canvas.draw_polyline(line, Color("714022") if i < 6 else Color("e2b46d"), 0.5)
	bottle(canvas, center, 100.0 / 3.0, fill)
