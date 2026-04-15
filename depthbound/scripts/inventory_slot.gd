extends RefCounted
class_name InventorySlot

const STACK_SIZE = 5

var ore_data: OreData
var quantity: int = 0

func _init(data: OreData, qty: int) -> void:
	ore_data = data
	quantity = qty

func can_stack(data: OreData) -> bool:
	if ore_data == null or data == null:
		return false
	
	if not ore_data.stackable or not data.stackable:
		return false
	
	return ore_data.name == data.name and quantity < STACK_SIZE

func add_ore() -> void:
	quantity += 1
