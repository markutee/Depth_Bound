extends Control

var locked := false

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			await resume()
		else:
			pause()

func pause() -> void:
	visible = true
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func resume() -> void:
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	await $AnimationPlayer.animation_finished
	visible = false

func close_pause_menu() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_pressed() -> void:
	await resume()

func _on_main_menu_pressed() -> void:
	close_pause_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
