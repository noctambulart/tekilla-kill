extends Control

const INTRO := preload("res://scenes/intro/intro.tscn")

@onready var play_button: Button = $CenterContainer/Content/SoloTrialButton
@onready var title_content: Control = $CenterContainer

var intro: Control


func _ready() -> void:
	if get_tree().has_meta("intro_to_title"):
		get_tree().remove_meta("intro_to_title")
		play_button.grab_focus()
	else:
		start_intro()


func start_intro() -> void:
	if is_instance_valid(intro):
		return
	title_content.hide()
	intro = INTRO.instantiate()
	intro.name = "Intro"
	intro.connect("finished", _on_intro_finished)
	add_child(intro)


func _on_intro_finished() -> void:
	# Defer focus until the skip event has finished propagating.
	_show_title.call_deferred()


func _show_title() -> void:
	if is_instance_valid(intro):
		intro.queue_free()
	intro = null
	title_content.show()
	play_button.grab_focus()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func start_movement_test() -> void:
	get_tree().change_scene_to_file("res://scenes/movement_test/movement_test.tscn")


func start_arena_review() -> void:
	get_tree().change_scene_to_file("res://scenes/arroyo_seco/arena_review.tscn")


func start_solo_trial() -> void:
	get_tree().change_scene_to_file("res://scenes/arroyo_seco/solo_trial.tscn")


func start_saloon_study() -> void:
	get_tree().change_scene_to_file("res://scenes/arroyo_seco/saloon_study/saloon_study.tscn")


func start_match() -> void:
	get_tree().change_scene_to_file("res://scenes/match/match.tscn")
