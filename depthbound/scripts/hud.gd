extends CanvasLayer


@onready var depth_label: Label = $DepthRect/DepthLabel
@onready var inventory_ui: Control = $InventoryUI
@onready var summary_ui: ColorRect = $SummaryUI
@onready var shop_ui: ColorRect = $ShopUI


signal back_to_mies
signal go_to_shop

func set_inventory(inv: Inventory):
	inventory_ui.set_inventory(inv)
	summary_ui.set_inventory(inv)
	
func show_summary() -> int:
	var earnings: int = 0
	earnings = summary_ui.calculate_summary()
	summary_ui.visible = true
	return earnings
	
func hide_summary() -> void:
	summary_ui.visible = false
	
	
func show_shop(amount: int) -> void:
	summary_ui.visible = false
	shop_ui.visible = true
	shop_ui.set_gold(amount)
	
func hide_shop() -> void:
	shop_ui.visible = false

func update_depth(value: int) -> void:
	depth_label.text = "Depth: %s" % value


func on_back_to_mines_clicked() -> void:
	back_to_mies.emit()

func _on_summary_ui_go_to_shop() -> void:
	go_to_shop.emit()
