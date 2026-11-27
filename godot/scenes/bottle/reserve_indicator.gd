extends Control

var bottle
var art


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if is_instance_valid(bottle) and art != null:
		art.frame(self, Vector2(size.x / 2.0, 48.8), float(bottle.remaining) / bottle.total_amount)
