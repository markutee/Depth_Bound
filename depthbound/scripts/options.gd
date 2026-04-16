extends Control
var previous_menu: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _on_volume_value_changed(value):
	AudioServer.set_bus_volume_linear(0, value)

func _on_check_box_toggled(toggled_on):
	AudioServer.set_bus_mute(0, toggled_on)


func _on_back_pressed() -> void:
	print("BACK")
	print("previous_menu = ", previous_menu)
	print("previous_menu visible before = ", previous_menu.visible if previous_menu != null else "null")

	if previous_menu != null:
		previous_menu.show()
		print("previous_menu visible after = ", previous_menu.visible)

	queue_free()
