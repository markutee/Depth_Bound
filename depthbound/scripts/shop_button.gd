extends HBoxContainer

signal upgrade_clicked

var upgrade_id: String

@onready var button: Button = $Button
@onready var level_label: Label = $LevelLabel
@onready var cost_label: Label = $CostLabel


func setup(id: String, Display_name: String) -> void:
	upgrade_id = id
	button.text = Display_name
	
func set_level_and_cost(level: int, max_level: int, cost: int) -> void:
	if level >= max_level:
		level_label.text = "Max Level"
		cost_label.text = "Max Level"
		button.disabled = true
	else:
		level_label.text = "Level %d/%d" % [level, max_level]
		cost_label.text = "%d gold" % cost
		button.disabled = false


func _on_button_pressed() -> void:
	upgrade_clicked.emit(upgrade_id)
