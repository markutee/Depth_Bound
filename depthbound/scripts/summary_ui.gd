extends ColorRect


var inventory: Inventory


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


func set_inventory(inv: Inventory) -> void:
	inventory = inv

func calculate_summary():
	#Go through the players inventory and see how many of each ore there is
	var ores := _count_ores()
	print(ores)
	

func _count_ores() -> Dictionary:
	var aggregated_ores := {}
	
	for slot in inventory.slots:
		if slot == null:
			continue
		var ore_name = slot.ore_data.name
		if not aggregated_ores.has(ore_name):
			# store initial data
			aggregated_ores[ore_name] = {
				"texture": slot.ore_data.texture,
				"value": slot.ore_data.value,
				"quantity": slot.quantity
			}
		else:
			#add quantitys if this ore exists already
			aggregated_ores[ore_name]["quantity"] += slot.quantity
			
	return aggregated_ores
