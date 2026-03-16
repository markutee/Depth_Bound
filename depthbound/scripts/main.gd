extends Node2D

@onready var game: Node2D = $Game
@onready var hud: CanvasLayer = $HUD
@onready var oxygen_timer: Timer = $OxygenTimer

var gold: int = 0
var max_oxygen: int = 100
var oxygen: int
var oxygen_use: int = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	hud.set_inventory(game.player.inventory)
	
	_reset_oxygen()
	
	hud.shop_ui.upgrade_purchased.connect(_on_upgrade_purchased)
	game.change_depth.connect(hud.update_depth)
	
	


func _on_game_exit_mine() -> void:
	oxygen_timer.stop()
	gold += hud.show_summary()


func _on_hud_back_to_mies() -> void:
	_reset_run(false)


func _on_hud_go_to_shop() -> void:
	hud.show_shop(gold)

func _reset_oxygen() -> void:
	oxygen = max_oxygen
	hud.update_oxygen(oxygen)

func _on_oxygen_timer_timeout() -> void:
	oxygen -= oxygen_use
	hud.update_oxygen(oxygen)
	if oxygen <= 0:
		_on_oxygen_empty()

func _on_oxygen_empty() -> void:
	oxygen_timer.stop()
	
	game.player.can_move = false
	#Handle player death
	await game.player.die()
	
	await hud.fade(1.0) #Fade out
	hud.get_node("DeathLabel").visible = true
	game.player.inventory.clear()
	
	await get_tree().create_timer(2.5).timeout
	
	
	_reset_run(true)


func _reset_run(do_fade: bool) -> void:
	_reset_oxygen()
	hud.get_node("DeathLabel").visible = false
	
	game.reset_depth()
	game.setup_map()
	
	hud.hide_shop()
	hud.hide_summary()
	
	if do_fade:
		await hud.fade(0.0) #Fade in
	
	game.player.can_move = true
	
	oxygen_timer.start()
	
func _on_upgrade_purchased(upgrade_id: String, cost : int) -> void:
	gold -= cost
	match upgrade_id:
		#Increase pickaxe strenght
		"pickaxe":
			game.player.pickaxe_strength += 1
		#increase oxygen capacity
		"oxygen":
			max_oxygen += 100
			oxygen = max_oxygen
		#add 4 inventory slots
		"inventory":
			game.player.inventory.upgrade_slots(4)
