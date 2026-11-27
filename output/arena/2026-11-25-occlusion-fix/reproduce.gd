extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func frames(count := 12) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var trial = load("res://scenes/arroyo_seco/solo_trial.tscn").instantiate()
	root.add_child(trial)
	await frames(3)
	trial.set_process(false)
	trial.explorer.set_physics_process(false)
	trial.target.set_physics_process(false)
	trial.target.position = Vector2(704, 520)
	var house = trial.arena.prop_nodes["home-west"]
	trial.explorer.position = house.position + Vector2(-48, -28)
	trial.camera.position = Vector2(240, 144)
	trial.camera.zoom = Vector2.ONE * 1.1
	await frames()
	var alpha: float = house.get_node("Art").modulate.a
	if not is_equal_approx(alpha, 1.0):
		failures.append("Maison transparente devant sa façade : alpha=" + str(alpha))
	if trial.explorer.z_index < house.z_index:
		failures.append("Personnage devant la façade dessiné sous la maison")
	var folder := ProjectSettings.globalize_path("res://../output/arena/2026-11-25-occlusion-fix")
	DirAccess.make_dir_recursive_absolute(folder)
	var stage := "after" if OS.get_cmdline_user_args().has("--after") else "before"
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(folder.path_join(stage + "-front.png"))
	print("HOUSE OCCLUSION: ", "PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
