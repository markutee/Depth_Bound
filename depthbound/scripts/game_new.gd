extends Node2D

const FILL_PERCENTAGE: float = 0.2
const ROCK_SCENE = preload("res://scenes/rock.tscn")

@onready var current_map: Node2D = $Map
@onready var rock_container: Node2D = $RockContainer
@onready var player: Player = $Player


func _ready() -> void:
	_generate_rocks()
	_position_objects()
	
func _position_objects() -> void:
	var player_spawn: Marker2D = current_map.get_node("PlayerSpawn")
	player.reset(player_spawn.position)
	
func _generate_rocks() -> void:
	for child in rock_container.get_children():
		child.queue_free()

	var ground_layer: TileMapLayer = current_map.get_node("Ground")
	var props_layer: TileMapLayer = current_map.get_node("Props")
	var support_layer: TileMapLayer = current_map.get_node("Support")

	var ground_cells: Array[Vector2i] = ground_layer.get_used_cells()
	var available_cells: Array[Vector2i] = []

	for cell in ground_cells:
		var tile_data: TileData = ground_layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue

		if props_layer.get_cell_source_id(cell) != -1:
			continue
		if support_layer.get_cell_source_id(cell) != -1:
			continue

		if tile_data.get_custom_data("can_spawn_rocks") == true:
			available_cells.append(cell)

	available_cells.shuffle()
	print("ground_cells=", ground_cells.size(), " available=", available_cells.size())

	var num_rocks: int = int(available_cells.size() * FILL_PERCENTAGE)

	for i in range(num_rocks):
		var cell := available_cells[i]
		var rock := ROCK_SCENE.instantiate()
		rock_container.add_child(rock)

		var local_pos: Vector2 = ground_layer.map_to_local(cell)
		rock.global_position = ground_layer.to_global(local_pos)
