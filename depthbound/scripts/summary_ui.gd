extends ColorRect

const SUMMARY_ROW_SCENE = preload("res://scenes/summary_row.tscn")
var inventory: Inventory

@onready var summary_vbox: VBoxContainer = $MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/SummaryVbox
@onready var total_label: Label = $MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/TotalLabel

signal back_to_mines
signal go_to_shop

func _ready() -> void:
	visible = false

func set_inventory(inv: Inventory) -> void:
	inventory = inv

func calculate_summary() -> int:
	var total_earnings: int = 0
	
	# Clear old items
	for child in summary_vbox.get_children():
		child.queue_free()
	
	var counted_items := _count_items()
	var ores: Dictionary = counted_items["ores"]
	var artefacts: Dictionary = counted_items["artefacts"]
	
	# Ores section
	if not ores.is_empty():
		
		for key in ores.keys():
			var data = ores[key]
			var row = _create_summary_row(data)
			summary_vbox.add_child(row)
			total_earnings += data["quantity"] * data["value"]
	
	# Artefacts section
	if not artefacts.is_empty():
		
		for key in artefacts.keys():
			var data = artefacts[key]
			var row = _create_summary_row(data)
			summary_vbox.add_child(row)
			total_earnings += data["quantity"] * data["value"]
	
	total_label.text = "Total: %d" % total_earnings
	
	inventory.clear()
	
	return total_earnings

func _create_summary_row(data: Dictionary) -> HBoxContainer:
	var summary_row = SUMMARY_ROW_SCENE.instantiate()
	
	summary_row.get_node("TextureRect").texture = data["texture"]
	summary_row.get_node("QuantityLabel").text = "QTY: %d" % data["quantity"]
	summary_row.get_node("ValueLabel").text = "Value: %d" % data["value"]
	summary_row.get_node("TotalLabel").text = "Total: %d" % (data["quantity"] * data["value"])
	
	return summary_row

func _add_section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	summary_vbox.add_child(label)

func _count_items() -> Dictionary:
	var aggregated_ores := {}
	var aggregated_artefacts := {}
	
	for slot in inventory.slots:
		if slot == null or slot.ore_data == null:
			continue
		
		var item = slot.ore_data
		var item_key = item.resource_path
		
		if item is ArtefactData:
			if not aggregated_artefacts.has(item_key):
				aggregated_artefacts[item_key] = {
					"name": item.name,
					"texture": item.texture,
					"value": item.value,
					"quantity": slot.quantity
				}
			else:
				aggregated_artefacts[item_key]["quantity"] += slot.quantity
		else:
			if not aggregated_ores.has(item_key):
				aggregated_ores[item_key] = {
					"name": item.name,
					"texture": item.texture,
					"value": item.value,
					"quantity": slot.quantity
				}
			else:
				aggregated_ores[item_key]["quantity"] += slot.quantity
	
	return {
		"ores": aggregated_ores,
		"artefacts": aggregated_artefacts
	}

func _on_shop_button_pressed() -> void:
	go_to_shop.emit()

func _on_mines_button_pressed() -> void:
	back_to_mines.emit()
