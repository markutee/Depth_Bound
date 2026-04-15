extends Area2D

@export var artefact_data: ArtefactData
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	if artefact_data == null:
		print("artefact_data puuttuu: ", name)
		return

	sprite_2d.texture = artefact_data.texture

func _on_body_entered(body: Node2D) -> void:
	if artefact_data == null:
		print("Pickup estetty, artefact_data puuttuu: ", name)
		return

	if body is Player:
		if body.add_ore(artefact_data):
			queue_free()
