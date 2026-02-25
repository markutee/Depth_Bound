extends Area2D

var player_on_ladder: bool = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player: 
		player_on_ladder = true
		print("Player on ladder")



func _on_body_exited(body: Node2D) -> void:
	if body is Player: 
		player_on_ladder = false
		print("Eipä oo ladderilla")
