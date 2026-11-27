extends SceneTree

var failures: Array[String] = []
var report: Array = []
var folder: String

func _initialize() -> void:
	_run.call_deferred()

func frames() -> void:
	for i in range(4):
		await process_frame

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var stage := "after" if OS.get_cmdline_user_args().has("--after") else "before"
	folder = ProjectSettings.globalize_path("res://../output/camera/2026-11-25-wider")
	DirAccess.make_dir_recursive_absolute(folder)
	var trial = load("res://scenes/arroyo_seco/solo_trial.tscn").instantiate()
	root.add_child(trial)
	current_scene = trial
	await frames()
	trial.set_process(false)
	trial.explorer.set_physics_process(false)
	trial.target.set_physics_process(false)
	for scenario in [
		["close", Vector2(650, 520), Vector2(704, 520)],
		["far", Vector2(200, 480), Vector2(1250, 480)],
		["vertical", Vector2(704, 150), Vector2(704, 820)],
		["edge", Vector2(100, 60), Vector2(180, 60)],
	]:
		trial.explorer.position = scenario[1]
		trial.target.position = scenario[2]
		trial.explorer.velocity = Vector2.ZERO
		trial._update_framing(0.0)
		await frames()
		RenderingServer.force_draw()
		var size: Vector2 = trial.get_viewport_rect().size
		var safe := Rect2(Vector2(12, 30), size - Vector2(24, 56))
		var positions: Array = []
		for actor in [trial.explorer, trial.target]:
			var point: Vector2 = trial.camera.get_canvas_transform() * actor.global_position
			positions.append([point.x, point.y])
			if not safe.has_point(point):
				failures.append(stage + "/" + scenario[0] + ": personnage hors de la zone sûre")
		report.append({"scenario": scenario[0], "zoom": trial.camera.zoom.x,
			"viewport": [size.x, size.y], "positions": positions})
		if scenario[0] in ["close", "far"]:
			root.get_texture().get_image().save_png(folder.path_join(stage + "-" + scenario[0] + ".png"))
	# The real movement anticipation and smoothing must also preserve the safe frame.
	trial.explorer.velocity = Vector2(210, 0)
	trial.explorer.position = Vector2(140, 480)
	trial.target.position = Vector2(1300, 480)
	trial.camera.zoom = Vector2.ONE
	trial._update_framing(1.0 / 60.0)
	if trial.camera.zoom.x >= 0.5:
		failures.append("Dézoom immédiat insuffisant après déplacement rapide")
	trial.set_overview(true)
	trial.set_overview(false)
	if stage == "after" and trial.camera.zoom.x > 0.85:
		failures.append("Limite de rapprochement dépassée après retour de la vue d’ensemble")
	var file := FileAccess.open(folder.path_join(stage + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"scenarios": report, "failures": failures}, "\t"))
	print("CAMERA REVIEW: ", "PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
