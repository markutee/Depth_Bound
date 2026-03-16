extends Node2D

@onready var game: Node2D = $Game
@onready var hud: CanvasLayer = $HUD

var gold: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	hud.set_inventory(game.player.inventory)
	
	hud.shop_ui.upgrade_purchased.connect(_on_upgrade_purchased)
	game.change_depth.connect(hud.update_depth)
	
	


func _on_game_exit_mine() -> void:
	gold += hud.show_summary()


func _on_hud_back_to_mies() -> void:
	_reset_run()


func _on_hud_go_to_shop() -> void:
	hud.show_shop(gold)


func _reset_run() -> void:
	game.reset_depth()
	game.setup_map()
	
	hud.hide_shop()
	hud.hide_summary()
	
	game.player.can_move = true
	
func _on_upgrade_purchased(upgrade_id: String, cost : int) -> void:
	gold -= cost
	match upgrade_id:
		#Increase pickaxe strenght
		"pickaxe":
			game.player.pickaxe_strength += 1
		#increase oxygen capacity
		#"oxygen":
			#max_oxygen += 100
			#oxygen = max_oxygen
		#add 4 inventory slots
		"inventory":
			game.player.inventory.upgrade_slots(4)
