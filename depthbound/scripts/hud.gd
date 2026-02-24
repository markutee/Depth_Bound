extends CanvasLayer


@onready var depth_label: Label = $DepthRect/DepthLabel
@onready var inventory_ui: Control = $InventoryUI


func set_inventory(inv: Inventory):
	inventory_ui.set_inventory(inv)

func update_depth(value: int) -> void:
	depth_label.text = "Depth: %s" % value
