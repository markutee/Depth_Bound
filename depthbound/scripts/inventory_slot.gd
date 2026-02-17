extends RefCounted
class_name InventorySlot

const STACK_SIZE = 5

var ore_data: OreData
var quantity: int = 0


func _init(data: OreData, qty: int) -> void:
	ore_data = data
	quantity = qty


func can_stack(data: OreData) -> bool:
	return ore_data.name == data.name and quantity < STACK_SIZE

func add_ore() -> void:
	quantity += 1
