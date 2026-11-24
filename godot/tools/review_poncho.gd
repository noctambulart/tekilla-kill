extends SceneTree
## Independent art review for #38. Playable-character integration belongs to #40.

class ArtBoard extends Node2D:
	var textures: Dictionary = {}
	var manifest: Dictionary = {}
	var hat_textures: Dictionary = {}
	var old_arm: Texture2D
	var previous_arms: Array = []
	var elapsed := 0.0
	var directions := false
	var comparison := false


	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()


	func frame(name: String) -> Texture2D:
		var frames: Array = textures[name]
		var fps: float = manifest.animations[name].fps_preview
		return frames[int(elapsed * fps) % frames.size()]


	func draw_layer(texture: Texture2D, at: Vector2, scale_factor: float, angle: float = 0.0, weapon: bool = false) -> void:
		var aim := Vector2(manifest.aim_pivot[0], manifest.aim_pivot[1])
		var pivot := aim if weapon else Vector2(24, 40)
		var origin := at + (aim-Vector2(24, 40)) * scale_factor if weapon else at
		draw_set_transform(origin, angle, Vector2.ONE * scale_factor)
		draw_texture(texture, -pivot)
		draw_set_transform(Vector2.ZERO)


	func draw_actor(at: Vector2, scale_factor: float, body: Texture2D, gun: Texture2D, bottle: Texture2D = null, angle: float = 0.0, hat: Texture2D = null) -> void:
		if hat != null:
			draw_layer(body, at, scale_factor)
			draw_layer(gun, at, scale_factor, angle, true)
			if bottle != null:
				draw_layer(bottle, at, scale_factor)
			draw_layer(hat, at, scale_factor)
			return
		if sin(angle) < -0.1:
			draw_layer(gun, at, scale_factor, angle, true)
		draw_layer(body, at, scale_factor)
		if sin(angle) >= -0.1:
			draw_layer(gun, at, scale_factor, angle, true)
		if bottle != null:
			draw_layer(bottle, at, scale_factor)


	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color("eeddb8"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(14, 23), "PONCHO · Recherche de silhouettes retenue · " + str(manifest.version).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("39251b"))
		var idle_arm: Texture2D = textures.arm_idle[0] if textures.has("arm_idle") else textures.fire[0]
		var idle_hat: Texture2D = hat_textures.idle[0] if hat_textures.has("idle") else null
		if comparison:
			var labels := ["V3 · main trop basse", "V4 · main masquée", "V4 · course"] if manifest.version == "v4" else ["V2 · main fixe", "V3 · marche", "V3 · course"]
			for i in range(3):
				var name := "sprint" if i == 2 else "walk"
				var phase := int(elapsed * manifest.animations[name].fps_preview) % 6
				var arm: Texture2D = (previous_arms[phase] if not previous_arms.is_empty() else old_arm) if i == 0 else textures[name+"_arm"][phase]
				var hat: Texture2D = null if i == 0 and previous_arms.is_empty() else hat_textures[name][phase]
				draw_actor(Vector2(106+i*212, 230), 4.0, textures[name][phase], arm, null, 0, hat)
				draw_string(font, Vector2(30+i*212, 270), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("39251b"))
			return
		if directions:
			draw_string(font, Vector2(14, 50), "Corps maintenu droit · visée indépendante dans huit directions", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("604633"))
			for i in range(8):
				draw_actor(Vector2(40+i*80, 190), 1.0, textures.idle[0], idle_arm, null, i*PI/4, idle_hat)
				draw_string(font, Vector2(30+i*80, 220), str(i*45) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("39251b"))
			return
		var examples := [["walk", "Marche"], ["sprint", "Sprint"], ["dash", "Dash"],
			["fire", "Tir / recul"], ["reload", "Rechargement"], ["drink", "Boisson"]]
		for i in range(examples.size()):
			var name: String = examples[i][0]
			var at := Vector2(106 + (i%3)*212, 158 + (i/3)*164)
			draw_rect(Rect2(at-Vector2(90, 118), Vector2(180, 130)), Color("d2ac73"))
			var body: Texture2D = frame(name) if name in ["walk", "sprint", "dash"] else textures.idle[0]
			var gun: Texture2D = frame(name) if name in ["fire", "reload"] else idle_arm
			if name in ["walk", "sprint"] and textures.has(name+"_arm"):
				gun = frame(name+"_arm")
			var bottle: Texture2D = frame(name) if name == "drink" else null
			var body_name: String = name if name in ["walk", "sprint", "dash"] else "idle"
			var hat: Texture2D = null
			if hat_textures.has(body_name):
				var phase: int = int(elapsed * manifest.animations[body_name].fps_preview) % hat_textures[body_name].size()
				hat = hat_textures[body_name][phase]
			draw_actor(at, 3.0, body, gun, bottle, 0, hat)
			draw_string(font, at+Vector2(-65, 25), examples[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("39251b"))


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var base := ProjectSettings.globalize_path("res://../output/sprites/poncho/issue-38")
	var version := "v2" if OS.get_cmdline_user_args().has("--v2") else ("v3" if OS.get_cmdline_user_args().has("--v3") else "v4")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("exports/"+version+"/manifest.json")))
	var board := ArtBoard.new()
	board.manifest = manifest
	var count := 0
	for name in manifest.animations:
		board.textures[name] = []
		for i in range(int(manifest.animations[name].frames)):
			var path := base.path_join("exports/%s/%s/%02d.png" % [version, name, i])
			var image := Image.load_from_file(path)
			if image == null or image.get_size() != Vector2i(48, 48):
				push_error("Invalid frame: " + path)
				quit(1)
				return
			board.textures[name].append(ImageTexture.create_from_image(image))
			count += 1
	for name in manifest.get("hat_occlusion", {}):
		board.hat_textures[name] = []
		for i in range(int(manifest.animations[name].frames)):
			var path := base.path_join("exports/%s/%s/%02d.png" % [version, manifest.hat_occlusion[name], i])
			board.hat_textures[name].append(ImageTexture.create_from_image(Image.load_from_file(path)))
	board.old_arm = ImageTexture.create_from_image(Image.load_from_file(base.path_join("exports/v2/fire/00.png")))
	if version == "v4":
		for i in range(6):
			board.previous_arms.append(ImageTexture.create_from_image(Image.load_from_file(base.path_join("exports/v3/walk_arm/%02d.png" % i))))
	root.add_child(board)
	if OS.get_cmdline_user_args().has("--verify-animation"):
		var seen: Dictionary = {}
		var rendered: Dictionary = {}
		for name in manifest.animations:
			seen[name] = {}
		for sample_index in range(60):
			await create_timer(0.05).timeout
			for name in manifest.animations:
				var index: int = int(board.elapsed * manifest.animations[name].fps_preview) % board.textures[name].size()
				seen[name][index] = true
				if manifest.animations[name].has("sync_with"):
					var body_name: String = manifest.animations[name].sync_with
					var body_index: int = int(board.elapsed * manifest.animations[body_name].fps_preview) % board.textures[body_name].size()
					if index != body_index:
						push_error("Arm/body phase mismatch: " + name)
						quit(1)
						return
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				rendered[hash(root.get_texture().get_image().get_data())] = true
		for name in manifest.animations:
			if seen[name].size() != int(manifest.animations[name].frames):
				push_error("Animation did not visit every frame: " + name)
				quit(1)
				return
		if DisplayServer.get_name() != "headless" and rendered.size() < 4:
			push_error("Animated rendering did not change")
			quit(1)
			return
		print("PONCHO ANIMATED REVIEW: PASS (", manifest.animations.size(), " sequences, ", rendered.size(), " rendered states, arm/body phases synchronized)")
		quit(0)
		return
	if OS.get_cmdline_user_args().has("--animate"):
		return
	board.set_process(false)
	if DisplayServer.get_name() != "headless":
		for moment in [0.0, 0.125, 0.25, 0.375, 0.5]:
			board.elapsed = moment
			board.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := base.path_join("review/poncho-%s-godot-%03d.png" % [version, int(moment*1000)])
			if root.get_texture().get_image().save_png(path) != OK:
				quit(1)
				return
		board.directions = true
		board.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(base.path_join("review/poncho-"+version+"-directions-godot.png")) != OK:
			quit(1)
			return
		if version in ["v3", "v4"]:
			board.directions = false
			board.comparison = true
			board.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(base.path_join("review/poncho-"+version+"-comparison-godot.png")) != OK:
				quit(1)
				return
	print("PONCHO LOT REVIEW: PASS (", count, " frames)")
	quit(0)
