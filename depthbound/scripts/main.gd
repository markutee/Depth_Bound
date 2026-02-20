extends Node2D

@onready var game: Node2D = $Game
@onready var hud: CanvasLayer = $HUD



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	hud.set_inventory(game.player.inventory)
	
	#game.change_depth.connect(hud.update_depth)
