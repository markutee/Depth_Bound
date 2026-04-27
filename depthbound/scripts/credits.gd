extends Control

@onready var credits_text: RichTextLabel = $TextureRect/ColorRect/CreditsText


var scroll_speed := 20.0

func _ready():
	credits_text.position.y = get_viewport_rect().size.y

func _process(delta):
	credits_text.position.y -= scroll_speed * delta

	if credits_text.position.y + credits_text.size.y < 0:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
