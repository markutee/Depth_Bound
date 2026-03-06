extends Node2D

@onready var game: Node2D = $Game
@onready var hud: CanvasLayer = $HUD

var gold: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	hud.set_inventory(game.player.inventory)
	
	game.change_depth.connect(hud.update_depth)


func _on_game_exit_mine() -> void:
	gold += hud.show_summary()


func _on_hud_back_to_mies() -> void:
	_reset_run()


func _on_hud_go_to_shop() -> void:
	pass # Replace with function body.


func _reset_run() -> void:
	game.reset_depth()
	game.setup_map()
	
	hud.hide_summary()
	
	game.player.can_move = true
