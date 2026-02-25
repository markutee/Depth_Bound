extends Node2D

const FILL_PERCENTAGE: float = 0.2
const LADDER_CHANGE: float = 0.4
const ROCK_SCENE = preload("res://scenes/rock.tscn")
const LADDER_SCENE = preload("res://scenes/ladder.tscn")

@export var rock_types: Array[RockData] = []


@onready var current_map: Node2D = $Map
@onready var rock_container: Node2D = $RockContainer
@onready var player: Player = $Player


var current_depth: int = 1
var down_ladder: Area2D
var rocks_remaining: int = 0



func _ready() -> void:
	
	_position_objects()
	_generate_rocks()
	
func _position_objects() -> void:
	var player_spawn: Marker2D = current_map.get_node("PlayerSpawn")
	player.reset(player_spawn.position)
	
	#Clear existing rocks
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
	rocks_remaining = num_rocks
	
	var valid_rocks: Array[RockData] = []
	for rock in rock_types:
		if current_depth >= rock.min_depth:
			valid_rocks.append(rock)

	for i in range(num_rocks):
		var cell = available_cells[i]
		var rock = ROCK_SCENE.instantiate()
		
		rock.data = get_random_rock(valid_rocks)

		#Get local position from tilemap
		var local_pos = ground_layer.map_to_local(cell)
		rock.global_position = local_pos
		rock_container.add_child(rock)
		rock.broken.connect(_on_rock_broken)
		
func get_random_rock(options: Array[RockData]) -> RockData:
	var total_weight : int = 0
	for rock in options:
		total_weight += rock.rarity
			
	var roll = randi_range(0, total_weight -1)
	var current_sum: int = 0
		
	for rock in options:
		current_sum += rock.rarity
		if roll < current_sum:
			return rock
	
	return options[0] #fallback to stone if nothing else is picked
	
#-------------------
#Ladder code
#-------------------

func _on_rock_broken(pos: Vector2) -> void:
	rocks_remaining -= 1
	if down_ladder != null:
		return
	var drop_ladder := randf() < LADDER_CHANGE
	if drop_ladder or rocks_remaining == 0:
		_create_down_ladder(pos)
	

func _create_down_ladder(pos: Vector2) -> void:
	down_ladder = LADDER_SCENE.instantiate()
	down_ladder.position = pos
	add_child(down_ladder)
