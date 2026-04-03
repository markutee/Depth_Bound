extends Area2D

var player_inside: bool = false

signal exit_used

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("climb_down_ladder") and player_inside:
		exit_used.emit()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
