extends RefCounted
## Keeps world points inside a safe screen rectangle, even when they move quickly.

const CLOSEST_ZOOM := 0.85

static func update(camera: Camera2D, points: PackedVector2Array, safe_area: Rect2,
		margin: float, delta: float) -> void:
	if points.is_empty() or safe_area.size.x <= 0.0 or safe_area.size.y <= 0.0:
		return
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	bounds = bounds.grow(margin)
	var fit := safe_area.size / bounds.size
	var goal_zoom := minf(CLOSEST_ZOOM, minf(fit.x, fit.y))
	var progress := 1.0 - exp(-7.0 * delta) if delta > 0.0 else 1.0
	# Zoom out immediately when the current view is too tight. Zoom back in gradually.
	var scale := minf(goal_zoom, lerpf(camera.zoom.x, goal_zoom, progress))
	var viewport_center := camera.get_viewport_rect().get_center()
	var safe_start := (safe_area.position - viewport_center) / scale
	var safe_end := (safe_area.end - viewport_center) / scale
	var preferred := bounds.get_center() - (safe_start + safe_end) * 0.5
	var min_center := bounds.end - safe_end
	var max_center := bounds.position - safe_start
	# Limit smoothing to camera positions that keep every point inside the margins.
	camera.global_position = camera.global_position.lerp(preferred, progress).clamp(
		min_center, max_center.max(min_center))
	camera.zoom = Vector2.ONE * scale
	camera.force_update_scroll()
