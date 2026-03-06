extends ColorRect

const SUMMARY_ROW_SCENE = preload("res://scenes/summary_row.tscn")
var inventory: Inventory

@onready var summary_vbox: VBoxContainer = $MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/SummaryVbox
@onready var total_label: Label = $MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/TotalLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


func set_inventory(inv: Inventory) -> void:
	inventory = inv

func calculate_summary() -> int:
	var total_earnings: int = 0
	
	#clear ols items
	for i in summary_vbox.get_children():
		i.queue_free()
	
	
	#Go through the players inventory and see how many of each ore there is
	var ores := _count_ores()

	#Loop over aggregated ores and create UI rows
	for key in ores.keys():
		var data = ores[key]
		var row = _create_summary_row(data)
		summary_vbox.add_child(row)
		total_earnings += data["quantity"] * data["value"]
		
	# Update total value
	total_label.text = "Total: %d" % total_earnings
		
	inventory.clear()
		
	return total_earnings
		

func _create_summary_row(data) -> HBoxContainer:
	var summary_row = SUMMARY_ROW_SCENE.instantiate()
	
	summary_row.get_node("TextureRect").texture = data["texture"]
	summary_row.get_node("QuantityLabel").text = "QTY: %d" % data["quantity"]
	summary_row.get_node("ValueLabel").text = "Value: %d" % data["value"]
	summary_row.get_node("TotalLabel").text = "Total: %d" % (data["quantity"] * data["value"])
	
	return summary_row



	
	
	
	

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
