extends "res://scenes/arroyo_seco/solo_trial.gd"
## Uses the real characters/combat, with study-local foot anchoring and depth.

const FOOT := Vector2(0, 16)


func _ready() -> void:
	super._ready()
	for actor in [explorer, target]:
		actor.get_node("CollisionShape2D").position = FOOT
		actor.get_node("Visual").warm_art = true
	$HUD/Top/Title.text = "SALOON · Étude"
	$HUD/Top/Title.add_theme_font_size_override("font_size", 10)
	plan_button.text = "Passages · P"
	set_overview(true)


func _process(delta: float) -> void:
	super._process(delta)
	for actor in [explorer, target]:
		if is_instance_valid(actor):
			actor.z_index = roundi(actor.position.y + FOOT.y)


func toggle_plan() -> void:
	super.toggle_plan()
	plan_button.text = "Masquer · P" if arena.annotations else "Passages · P"
