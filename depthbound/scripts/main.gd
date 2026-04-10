extends Node2D

@onready var game: Node2D = $Game
@onready var hud: CanvasLayer = $HUD
@onready var fade: AnimationPlayer = $Fade

var gold: int = 1000000

func _ready() -> void:
	fade.play("fade_in")
	
	hud.set_inventory(game.player.inventory)
	
	hud.shop_ui.upgrade_purchased.connect(_on_upgrade_purchased)
	game.change_depth.connect(hud.update_depth)

func _on_game_exit_mine() -> void:
	gold += hud.show_summary()

func _on_hud_back_to_mies() -> void:
	_reset_run(false)

func _on_hud_go_to_shop() -> void:
	hud.show_shop(gold)

func _reset_run(do_fade: bool) -> void:
	hud.get_node("DeathLabel").visible = false
	game.player.inventory.clear()
	game.reset_depth()
	game.setup_map()
	
	hud.hide_shop()
	hud.hide_summary()
	
	if do_fade:
		await hud.fade(0.0) # Fade in
	
	game.player.can_move = true

func _on_upgrade_purchased(upgrade_id: String, cost: int) -> void:
	gold -= cost
	
	match upgrade_id:
		# Increase pickaxe strength
		"pickaxe":
			game.player.pickaxe_strength += 1
		
		# Increase lamp strength
		"lamp":
			game.player.upgrade_lamp()
		
		# Add 4 inventory slots
		"inventory":
			game.player.inventory.upgrade_slots(4)
