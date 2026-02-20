extends Control

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
 
func _update_display() -> void:
	# Clear existing slot UI
	for child in grid_container.get_children():
		child.queue_free()
