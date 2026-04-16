extends Area2D

@export var artefact_data: ArtefactData

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var glow_pivot: Node2D = $GlowPivot
@onready var rays: Sprite2D = $GlowPivot/Rays

var base_scale := 0.2
var pulse_speed := 2.5
var pulse_amount := 0.06
var pulse_time := 0.0 

func _ready() -> void:
	if artefact_data == null:
		print("artefact_data puuttuu: ", name)
		return

	sprite_2d.texture = artefact_data.texture
	
# varmistetaan että rays pyörii keskeltä
	rays.centered = true
	rays.offset = Vector2.ZERO
	rays.position = Vector2.ZERO
	
func _process(delta: float) -> void:
	glow_pivot.rotation += delta * 0.8
	# Sykkiminen
	pulse_time += delta
	var pulse := 1.0 + sin(pulse_time * pulse_speed) * pulse_amount
	rays.scale = Vector2.ONE * (base_scale * pulse)

func _on_body_entered(body: Node2D) -> void:
	if artefact_data == null:
		print("Pickup estetty, artefact_data puuttuu: ", name)
		return

	if body is Player:
		if body.add_ore(artefact_data):
			queue_free()
