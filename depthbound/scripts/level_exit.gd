extends Area2D
class_name LevelExit
var player_inside: bool = false

signal exit_used(direction)

enum Direction {
	UP,
	DOWN
}

@export var direction: Direction

func _unhandled_input(event: InputEvent) -> void:
	if not player_inside:
		return
	print("INPUT DETECTED")
	
	if direction == Direction.DOWN and event.is_action_pressed("use_ladder"):
		print("Going down ")
		exit_used.emit(direction)

	elif direction == Direction.UP and event.is_action_pressed("use_ladder"):
		exit_used.emit(direction)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
