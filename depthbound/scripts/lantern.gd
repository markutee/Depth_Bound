extends Node2D

@onready var light: PointLight2D = $PointLight2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var base_energy := 0.6
var base_scale := 2.4

var flicker_timer := 0.0
var target_energy := 0.6
var target_scale := 2.4

func _ready() -> void:
	randomize()
	sprite.play("idle")

	base_energy += randf_range(-0.05, 0.05)
	base_scale += randf_range(-0.05, 0.05)

	light.energy = base_energy
	light.texture_scale = base_scale

func _process(delta: float) -> void:
	flicker_timer -= delta

	if flicker_timer <= 0.0:
		flicker_timer = randf_range(0.07, 0.16)

		# 👇 isompi vaihtelu kuin aiemmin
		target_energy = base_energy + randf_range(-0.15, 0.15)
		target_scale = base_scale + randf_range(-0.10, 0.10)

	# 👇 hieman nopeampi reagointi
	light.energy = lerp(light.energy, target_energy, delta * 6.0)
	light.texture_scale = lerp(light.texture_scale, target_scale, delta * 5.0)
