extends ColorRect

var player_gold: int = 0
var buttons: Dictionary = {}

var upgrades := {
	"pickaxe": {"level": 0, "max_level": 3, "costs": [200, 500, 1500]},
	"lamp": {"level": 0, "max_level": 3, "costs": [250, 600, 2000]},
	"inventory": {"level": 0, "max_level": 2, "costs": [500, 2500]},
}

@onready var total_label: Label = $MarginContainer/NinePatchRect/MarginContainer/ShopVbox/TotalLabel
@onready var pickaxe_upgrade: HBoxContainer = $MarginContainer/NinePatchRect/MarginContainer/ShopVbox/PickaxeUpgrade
@onready var lamp_upgrade: HBoxContainer = $MarginContainer/NinePatchRect/MarginContainer/ShopVbox/LampUpgrade
@onready var inventory_upgrade: HBoxContainer = $MarginContainer/NinePatchRect/MarginContainer/ShopVbox/InventoryUpgrade

signal back_to_mines
signal upgrade_purchased

func _ready() -> void:
	visible = false
	
	# setup buttons
	pickaxe_upgrade.setup("pickaxe", "Pickaxe")
	lamp_upgrade.setup("lamp", "Lamp")
	inventory_upgrade.setup("inventory", "Inventory Size")
	
	buttons = {
		"pickaxe": pickaxe_upgrade,
		"lamp": lamp_upgrade,
		"inventory": inventory_upgrade,
	}
	
	for button in buttons.values():
		button.upgrade_clicked.connect(_on_upgrade_clicked)
	
	_update_all_buttons()

func set_gold(amount: int) -> void:
	player_gold = amount
	total_label.text = "Total Gold: %d" % player_gold
	
func _on_upgrade_clicked(upgrade_id: String) -> void:
	var upgrade = upgrades[upgrade_id]
	var level = upgrade["level"]
	var max_level = upgrade["max_level"]
	
	# check if can upgrade
	if level >= max_level:
		return
	
	var cost = upgrade["costs"][level]
	if player_gold >= cost:
		# Pay for upgrade
		player_gold -= cost
		set_gold(player_gold)
		upgrade["level"] += 1
		_update_all_buttons()
		# tell main to apply upgrade
		upgrade_purchased.emit(upgrade_id, cost)
	
func _update_all_buttons() -> void:
	for id in upgrades.keys():
		var upgrade = upgrades[id]
		var level = upgrade["level"]
		var max_level = upgrade["max_level"]
		var cost = 0 if level >= max_level else upgrade["costs"][level]
		buttons[id].set_level_and_cost(level, max_level, cost)

func _on_mines_button_pressed() -> void:
	back_to_mines.emit()
