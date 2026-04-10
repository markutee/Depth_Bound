extends Area2D

signal exit_used

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_exit"):
		for body in get_overlapping_bodies():
			if body is Player:
				exit_used.emit()
				return
