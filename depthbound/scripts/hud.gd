extends CanvasLayer


@onready var depth_label: Label = $DepthRect/DepthLabel
@onready var inventory_ui: Control = $InventoryUI
@onready var summary_ui: ColorRect = $SummaryUI


func set_inventory(inv: Inventory):
	inventory_ui.set_inventory(inv)
	summary_ui.set_inventory(inv)
	
func show_summary() -> void:
	summary_ui.calculate_summary()
	summary_ui.visible = true

func update_depth(value: int) -> void:
	depth_label.text = "Depth: %s" % value
