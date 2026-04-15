extends Area2D

var player_on_ladder: bool = false

@export var default_texture: Texture2D
@export var map_5_texture: Texture2D

@onready var sprite_2d: Sprite2D = $Sprite2D

signal ladder_used

func set_texture_for_map(map_index: int) -> void:
	if map_index == 4:
		sprite_2d.texture = map_5_texture
	else:
		sprite_2d.texture = default_texture

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_ladder"):
		print("Space painettu")
		if player_on_ladder:
			print("Ladder used")
			ladder_used.emit()

func _on_body_entered(body: Node2D) -> void:
	if body is Player: 
		player_on_ladder = true
