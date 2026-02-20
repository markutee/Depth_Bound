extends Control

const SLOT_SCENE = preload("res://scenes/inventory_slot.tscn")

var inventory: Inventory

@onready var grid_container: GridContainer = $GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible


func set_inventory(inv: Inventory) -> void:
	inventory = inv
	inventory.inventory_changed.connect(_update_display)
	_update_display()
	
 
func _update_display() -> void:
	# Clear existing slot UI
	for child in grid_container.get_children():
		child.queue_free()
		
		# Create UI for each inventory slot
	for slot in inventory.slots:
		var slot_ui = create_slot_ui(slot)
		grid_container.add_child(slot_ui)


func create_slot_ui(slot: InventorySlot) -> TextureRect:
	var slot_ui = SLOT_SCENE.instantiate()
	var margin_container = slot_ui.get_node("MarginContainer")
	var icon = margin_container.get_node("ItemIcon")
	var quantity_label = slot_ui.get_node("QuantityLabel")
	
	if slot != null:
		icon.texture = slot.ore_data.texture
		quantity_label.text = "x%d" % slot.quantity
		quantity_label.visible = true
	else:
		icon.texture = null
		quantity_label.visible = false
		
	return slot_ui
