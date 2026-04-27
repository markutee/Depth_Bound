extends Control

@onready var fade: AnimationPlayer = $Fade

var starting := false

func _on_start_pressed() -> void:
	if starting:
		return
	
	starting = true
	fade.play("Fade_out")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_fade_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fade_out" and starting:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
