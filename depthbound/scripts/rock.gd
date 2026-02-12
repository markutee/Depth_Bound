extends StaticBody2D
class_name Rock

const ORE_SCENE := preload("res://scenes/ore.tscn")

var health: int


@export var data: RockData

@onready var sprite_2d: Sprite2D = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = data.max_health
	sprite_2d.texture = data.texture


func take_damage(amount: int) -> void:
	health -= amount
	print(health)
	if health <= 0:
		_drop_ore()
		_destroy()


func _destroy() -> void:
	queue_free()


func _drop_ore() -> void:
	var ore = ORE_SCENE.instantiate()
	ore.position = position
	ore.ore_data = data.ore_resource
	
	var game_root = get_parent().get_parent()
	var ore_container = game_root.get_node("OreContainer")
	ore_container.add_child(ore)

	var tween = ore.create_tween()
	#Vertical bounce
	tween.tween_property(ore, "position:y", ore.position.y - 20, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ore, "position:y", ore.position.y, 0.3)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)#.set_delay(0.3)
