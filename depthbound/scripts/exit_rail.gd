extends Area2D

var player_on_exit_rail: bool = false

signal exit_used

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_exit"):
		if player_on_exit_rail:
			exit_used.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_on_exit_rail = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_on_exit_rail = false
