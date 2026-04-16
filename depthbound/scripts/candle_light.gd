extends Node2D

@onready var light: PointLight2D = $PointLight2D

var base_energy := 0.35
var base_scale := 0.8

var flicker_timer := 0.0
var target_energy := 0.35
var target_scale := 0.8

func _ready() -> void:
	randomize()

	base_energy += randf_range(-0.02, 0.02)
	base_scale += randf_range(-0.02, 0.02)

	light.energy = base_energy
	light.texture_scale = base_scale

func _process(delta: float) -> void:
	flicker_timer -= delta

	if flicker_timer <= 0.0:
		flicker_timer = randf_range(0.08, 0.18)
		target_energy = base_energy + randf_range(-0.05, 0.05)
		target_scale = base_scale + randf_range(-0.03, 0.03)

	light.energy = lerp(light.energy, target_energy, delta * 5.0)
	light.texture_scale = lerp(light.texture_scale, target_scale, delta * 4.0)
