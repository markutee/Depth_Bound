extends RefCounted
class_name Inventory

var slots: Array = []
var max_slots: int

signal inventory_changed

func _init(starting_slots: int = 4):
	max_slots = starting_slots
	for i in range(max_slots):
		slots.append(null)

func add_item(data: OreData) -> bool:
	# Try Stacking with existing items
	for slot in slots:
		if slot != null and slot.can_stack(data):
			slot.add_ore()
			inventory_changed.emit()
			return true
	
	
	# Find empty slot
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = InventorySlot.new(data, 1)
			inventory_changed.emit()
			return true
			
	# No space
	return false
