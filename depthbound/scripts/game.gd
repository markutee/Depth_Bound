extends Node2D

const FILL_PERCENTAGE: float = 0.2
const LADDER_CHANGE: float = 0.9
const ROCK_SCENE = preload("res://scenes/rock.tscn")
# const LADDER_SCENE = preload("res://scenes/ladder.tscn")
const MAPS = [
	preload("res://scenes/levels/map_1.tscn"),
	preload("res://scenes/levels/map_2.tscn"),
	preload("res://scenes/levels/map_3.tscn"),
	preload("res://scenes/levels/map_4.tscn"),
	preload("res://scenes/levels/map_5.tscn")
]

@export var rock_types: Array[RockData] = []

@onready var current_map: Node2D = $Map
@onready var rock_container: Node2D = $RockContainer
@onready var player: Player = $Player
@onready var game: Node2D = $"."
@onready var exit_rail: Area2D = $ExitRail

var last_map_index: int = -1
var current_depth: int = 1
# var down_ladder: Area2D
var rocks_remaining: int = 0

signal change_depth
signal exit_mine

func _ready() -> void:
	setup_map()

func reset_depth() -> void:
	current_depth = 1
	last_map_index = -1
	change_depth.emit(current_depth)

func setup_map() -> void:
	_clear_map()
	if !_generate_map():
		return
	
	_position_objects()
	_generate_rocks()

#-------------------------------------------------------------------------
# Uusi kokeilu mappien välillä liikkumiseen
#-------------------------------------------------------------------------
func go_to_next_map() -> void:
	if last_map_index >= MAPS.size() - 1:
		print("Viimeinen map saavutettu.")
		return

	current_depth += 1
	change_depth.emit(current_depth)
	setup_map()
#-------------------------------------------------------------------------
#-------------------------------------------------------------------------

func _clear_map() -> void:
	# Remove old map
	if current_map:
		current_map.queue_free()
		current_map = null

	# Delete any down ladders
	# if down_ladder:
	# 	down_ladder.queue_free()
	# 	down_ladder = null

	# Delete any ores that werent collected
	var ore_container = $OreContainer
	for ore in ore_container.get_children():
		ore.queue_free()

func _generate_map() -> bool:
	if last_map_index >= MAPS.size() - 1:
		print("Kaikki mapit käyty läpi, pohja saavutettu.")
		return false
	
	last_map_index += 1
	current_map = MAPS[last_map_index].instantiate()
	game.add_child(current_map)
	return true

func is_on_last_map() -> bool:
	return last_map_index >= MAPS.size() - 1

func _position_objects() -> void:
	var player_spawn: Marker2D = current_map.get_node("PlayerSpawn")
	player.reset(player_spawn.position)
	
	# Position exit rail on top of player spawn
	exit_rail.position = player_spawn.position

	if current_map.has_node("ExitToMap2"):
		var exit_to_map_2 = current_map.get_node("ExitToMap2")
		if not exit_to_map_2.exit_used.is_connected(_on_exit_to_map_2_used):
			exit_to_map_2.exit_used.connect(_on_exit_to_map_2_used)

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

		# Get local position from tilemap
		var local_pos = ground_layer.map_to_local(cell)
		rock.global_position = local_pos
		rock_container.add_child(rock)
		# LADDER DISABLED FOR NOW
		# rock.broken.connect(_on_rock_broken)

func get_random_rock(options: Array[RockData]) -> RockData:
	var total_weight: int = 0
	for rock in options:
		total_weight += rock.rarity
			
	var roll = randi_range(0, total_weight - 1)
	var current_sum: int = 0
		
	for rock in options:
		current_sum += rock.rarity
		if roll < current_sum:
			return rock
	
	return options[0] # fallback to stone if nothing else is picked

#-------------------
# Map exit code
#-------------------
func _on_exit_to_map_2_used() -> void:
	go_to_next_map()

#-------------------
# Ladder code
#-------------------

# func _on_rock_broken(pos: Vector2) -> void:
# 	rocks_remaining -= 1
# 	if down_ladder != null:
# 		return
# 	# Don't generate ladder if on last level
# 	if is_on_last_map():
# 		return
# 	
# 	var drop_ladder := randf() < LADDER_CHANGE
# 	if drop_ladder or rocks_remaining == 0:
# 		_create_down_ladder(pos)

# func _create_down_ladder(pos: Vector2) -> void:
# 	down_ladder = LADDER_SCENE.instantiate()
# 	down_ladder.position = pos
# 	add_child(down_ladder)
# 	down_ladder.ladder_used.connect(_on_down_ladder_used)

func _on_down_ladder_used() -> void:
	current_depth += 1
	change_depth.emit(current_depth)
	setup_map()

func _on_exit_rail_exit_used() -> void:
	go_to_next_map()
	if !player.can_move:
		return
	player.can_move = false
	exit_mine.emit()
