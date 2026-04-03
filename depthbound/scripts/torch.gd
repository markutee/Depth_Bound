extends Node2D

@onready var light: PointLight2D = $PointLight2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var base_energy := 1.25
var base_scale := 2.6

var flicker_timer := 0.0
var target_energy := 1.25
var target_scale := 2.6

func _ready() -> void:
	randomize()
	sprite.play("Torch")

	# Jokaiselle soihdulle hieman eri aloitusarvot
	base_energy += randf_range(-0.08, 0.08)
	base_scale += randf_range(-0.05, 0.05)

	light.energy = base_energy
	light.texture_scale = base_scale

func _process(delta: float) -> void:
	flicker_timer -= delta

	if flicker_timer <= 0.0:
		flicker_timer = randf_range(0.05, 0.14)

		target_energy = base_energy + randf_range(-0.18, 0.18)
		target_scale = base_scale + randf_range(-0.08, 0.08)

	light.energy = lerp(light.energy, target_energy, delta * 7.0)
	light.texture_scale = lerp(light.texture_scale, target_scale, delta * 5.0)
