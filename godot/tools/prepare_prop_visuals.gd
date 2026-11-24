extends SceneTree
## Reproduce issue #42's native texture/scene exports and inspect them on both floors.
## Headless builds exports/manifest; a window additionally captures the comparison.

const ASSETS := "res://scenes/arroyo_seco/assets/"
const EXPORTS := ASSETS + "prop_visuals/"
const OUTPUT := "res://../output/arena/2026-11-24/issue-42/"
const INTACT := ASSETS + "environment-v4.png"
const DESTROYED := ASSETS + "destruction-v1.png"
const KINDS := ["crate","barrel","table","couch","chair","pot","cart","counter"]
const SIZES := [Vector2(40,40),Vector2(40,40),Vector2(64,64),Vector2(128,48),
	Vector2(32,32),Vector2(24,24),Vector2(128,48),Vector2(128,32)]
const BREAKABLE := ["crate","chair","pot"]
const DEBRIS_SIZES := [Vector2(32,22),Vector2(24,16),Vector2(20,14)]

var failures: Array[String] = []
var variants: Array[Dictionary] = []


class Comparison extends Node2D:
	var font := ThemeDB.fallback_font
	var tile: Texture2D
	func _draw() -> void:
		draw_rect(Rect2(0,0,640,360),Color("eee0b8"))
		draw_string(font,Vector2(18,25),"TEQUILA KILL · Mobilier",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("493c2b"))
		var columns := ["Intact","Cassé","Débris"]
		for index in range(columns.size()):
			draw_string(font,Vector2(169+index*160,49),columns[index],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("493c2b"))
		var names := ["Caisse · 40 px","Chaise · 32 px","Pot · 24 px"]
		for row in range(3):
			draw_string(font,Vector2(16,96+row*84),names[row],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("493c2b"))
			for column in range(3):
				var rect := Rect2(138+column*160,62+row*84,144,64)
				draw_rect(rect,Color("f1d88e"))
				draw_rect(Rect2(rect.position+Vector2(72,0),Vector2(72,64)),Color("9faeae"))
				for x in range(3):
					for y in range(2):
						draw_texture_rect_region(tile,Rect2(rect.position+Vector2(72+x*24,y*32),Vector2(24,32)),Rect2(320,32,24,32),Color(1,1,1,.25))
		draw_string(font,Vector2(18,344),"Vue verticale · Ancrage au centre · Sable / dallage",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("655238"))


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _visible_bounds(image: Image, cell: Rect2i) -> Rect2i:
	var minimum := cell.end
	var maximum := cell.position
	for y in range(cell.position.y,cell.end.y):
		for x in range(cell.position.x,cell.end.x):
			if image.get_pixel(x,y).a >= .5:
				minimum = minimum.min(Vector2i(x,y))
				maximum = maximum.max(Vector2i(x,y))
	_check(minimum.x <= maximum.x and minimum.y <= maximum.y,"Cellule vide : %s" % cell)
	minimum = (minimum-Vector2i.ONE).max(cell.position)
	maximum = (maximum+Vector2i.ONE*2).min(cell.end)
	return Rect2i(minimum,maximum-minimum)


func _export(texture: Texture2D, region: Rect2i, kind: String, state: String, size: Vector2) -> void:
	var base := kind + "-" + state
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region)
	atlas.filter_clip = true
	var texture_path := EXPORTS+base+".tres"
	_check(ResourceSaver.save(atlas,texture_path)==OK,"Export texture : "+base)
	var sprite := Sprite2D.new()
	sprite.name = base.to_pascal_case()
	sprite.texture = load(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.scale = size/Vector2(region.size)
	sprite.set_meta("prop_kind",kind)
	sprite.set_meta("visual_state",state)
	sprite.set_meta("planned_breakable",kind in BREAKABLE)
	sprite.set_meta("requires_collision",state=="intact")
	var packed := PackedScene.new()
	_check(packed.pack(sprite)==OK,"Préparation scène : "+base)
	var scene_path := EXPORTS+base+".tscn"
	_check(ResourceSaver.save(packed,scene_path)==OK,"Export scène : "+base)
	sprite.free()
	var restored: Sprite2D = load(scene_path).instantiate()
	_check(restored.texture != null and restored.centered and restored.position==Vector2.ZERO,
		"Texture et ancrage relus : "+base)
	_check((restored.texture.get_size()*restored.scale).is_equal_approx(size),"Dimensions relues : "+base)
	_check(restored.get_child_count()==0,"Scène visuelle sans collision ni comportement : "+base)
	restored.free()
	variants.append({"kind":kind,"state":state,"texture":texture_path,"scene":scene_path,
		"draw_size_px":[size.x,size.y],"pivot_normalized":[.5,.5],"origin_px":[0,0],
		"region_px":[region.position.x,region.position.y,region.size.x,region.size.y],
		"blocking_in_game":state=="intact","planned_breakable":kind in BREAKABLE})


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORTS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var intact_texture: Texture2D = load(INTACT)
	var destroyed_texture: Texture2D = load(DESTROYED)
	var intact := intact_texture.get_image()
	var destroyed := destroyed_texture.get_image()
	_check(intact.has_mipmaps()==false and destroyed.has_mipmaps()==false,"Pas de mipmaps pour la planche pixel art")
	_check(intact.get_format()==Image.FORMAT_RGBA8 and destroyed.get_format()==Image.FORMAT_RGBA8,
		"Sources RGBA avec canal alpha")
	for index in range(KINDS.size()):
		var x0 := roundi(intact.get_width()*(index%4)/4.0)
		var x1 := roundi(intact.get_width()*((index%4)+1)/4.0)
		var y0 := roundi(intact.get_height()*floori(index/4.0)/2.0)
		var y1 := roundi(intact.get_height()*(floori(index/4.0)+1)/2.0)
		_export(intact_texture,_visible_bounds(intact,Rect2i(x0,y0,x1-x0,y1-y0)),KINDS[index],"intact",SIZES[index])
	for index in range(6):
		var column := index%3
		var row := floori(index/3.0)
		var x0 := roundi(destroyed.get_width()*column/3.0)
		var x1 := roundi(destroyed.get_width()*(column+1)/3.0)
		var y0 := roundi(destroyed.get_height()*row/2.0)
		var y1 := roundi(destroyed.get_height()*(row+1)/2.0)
		var cell := Rect2i(x0,y0,x1-x0,y1-y0)
		var region := _visible_bounds(destroyed,cell)
		_check(region.size.x < cell.size.x*.9 and region.size.y < cell.size.y*.9,
			"Marge transparente de la cellule %d" % index)
		var kind: String = BREAKABLE[column]
		var size: Vector2 = SIZES[KINDS.find(kind)] if row==0 else DEBRIS_SIZES[column]
		_export(destroyed_texture,region,kind,"broken" if row==0 else "debris",size)
	var manifest := {"version":1,"issue":42,"date":"2026-11-24","variants":variants,
		"intact_source":INTACT,"destruction_source":DESTROYED,
		"coordinates":"Sprite local origin is its center; positions and collisions come from layout.json.",
		"collision_contract":"Visual scenes contain no physics. Keep the intact collision in the owner; release it on destruction. Broken/debris visuals never block or grant bonuses.",
		"integration_status":"Visual lot ready; damage, resistance, collision removal and timing belong to #29/#43."}
	var file := FileAccess.open(ASSETS+"prop-visuals.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	if DisplayServer.get_name() != "headless":
		var board := Comparison.new()
		board.tile = load(ASSETS+"terrain_atlas.png")
		board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(board)
		for row in range(3):
			for column in range(3):
				var state: String = ["intact","broken","debris"][column]
				var sprite: Sprite2D = load(EXPORTS+BREAKABLE[row]+"-"+state+".tscn").instantiate()
				sprite.position = Vector2(210+column*160,94+row*84)
				board.add_child(sprite)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT+"comparaison-etats.png"))==OK,
			"Capture des états sur sable et dallage")
		board.queue_free()
		await process_frame
	var report := {"status":"passed" if failures.is_empty() else "failed","variants_exported":variants.size(),
		"failures":failures,"rendered":DisplayServer.get_name()!="headless",
		"scope":"Exports de 14 textures et scènes relus, dimensions/pivots, alpha et aperçu. Pas de gameplay de destruction."}
	file = FileAccess.open(ProjectSettings.globalize_path(OUTPUT+"verification.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("PROP VISUALS : %d variantes, %d échecs" % [variants.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
