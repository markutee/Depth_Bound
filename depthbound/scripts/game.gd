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

var current_map: Node2D
@onready var rock_container: Node2D = $RockContainer
@onready var player: Player = $Player
@onready var game: Node2D = $"."
@onready var fade_rect: ColorRect = $FadeLayer/ColorRect
@onready var animation_player: AnimationPlayer = $FadeLayer/AnimationPlayer


var current_map_index: int = 0
var current_depth: int = 1
# var down_ladder: Area2D
var rocks_remaining: int = 0
var transition_direction: String = "start"
var is_transitioning: bool = false

signal change_depth
signal exit_mine

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	setup_map()

func reset_depth() -> void:
	current_map_index = 0
	current_depth = 1
	transition_direction = "start"
	change_depth.emit(current_depth)
	setup_map()

func setup_map() -> void:
	_clear_map()
	await get_tree().process_frame
	if !_generate_map():
		return
	
	_position_objects()
	_generate_rocks()

#-------------------------------------------------------------------------
# Uusi kokeilu mappien välillä liikkumiseen
#-------------------------------------------------------------------------
func go_to_next_map() -> void:
	if is_transitioning:
		return
	change_map_with_fade("down")

func go_to_previous_map() -> void:
	if is_transitioning:
		return
	change_map_with_fade("up")
#-------------------------------------------------------------------------
#-------------------------------------------------------------------------

func change_map_with_fade(direction: String) -> void:
	if is_transitioning:
		return

	is_transitioning = true

	if player.has_method("set"):
		player.can_move = false

	await fade_out()

	if direction == "down":
		if current_map_index >= MAPS.size() - 1:
			await fade_in()
			player.can_move = true
			is_transitioning = false
			print("Viimeinen map saavutettu.")
			return

		current_map_index += 1
		current_depth = current_map_index + 1
		transition_direction = "down"

	elif direction == "up":
		if current_map_index <= 0:
			await fade_in()
			player.can_move = true
			is_transitioning = false
			print("Ensimmäinen map saavutettu.")
			return

		current_map_index -= 1
		current_depth = current_map_index + 1
		transition_direction = "up"

	change_depth.emit(current_depth)
	await setup_map()
	await fade_in()

	player.can_move = true
	is_transitioning = false

func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.35)
	await tween.finished

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	await tween.finished

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

	for child in rock_container.get_children():
		child.queue_free()

func _generate_map() -> bool:
	if current_map_index < 0 or current_map_index >= MAPS.size():
		print("Virheellinen map index: ", current_map_index)
		return false
	
	current_map = MAPS[current_map_index].instantiate()
	game.add_child(current_map)
	return true

func is_on_last_map() -> bool:
	return current_map_index >= MAPS.size() - 1

func _position_objects() -> void:
	var spawn_node: Marker2D

	# Kun tullaan alemmalta tasolta ylöspäin
	if transition_direction == "up" and current_map.has_node("SpawnUp"):
		spawn_node = current_map.get_node("SpawnUp")
	else:
		# Kaikki muut tilanteet (alas + aloitus)
		spawn_node = current_map.get_node("PlayerSpawn")

	player.reset(spawn_node.position)

	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.force_update_scroll()

	if current_map.has_node("ExitRail"):
		var exit_rail = current_map.get_node("ExitRail")
		if not exit_rail.exit_used.is_connected(_on_exit_rail_exit_used):
			exit_rail.exit_used.connect(_on_exit_rail_exit_used)

	if current_map.has_node("ExitDown"):
		var exit_down = current_map.get_node("ExitDown")
		if not exit_down.exit_used.is_connected(_on_level_exit_used):
			exit_down.exit_used.connect(_on_level_exit_used)

	if current_map.has_node("ExitUp"):
		var exit_up = current_map.get_node("ExitUp")
		if not exit_up.exit_used.is_connected(_on_level_exit_used):
			exit_up.exit_used.connect(_on_level_exit_used)

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

	if valid_rocks.is_empty():
		print("Ei valid rocks tällä depthillä: ", current_depth)
		return

	for i in range(min(num_rocks, available_cells.size())):
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
func _on_level_exit_used(direction: int) -> void:
	if is_transitioning:
		return

	match direction:
		LevelExit.Direction.UP:
			go_to_previous_map()
		LevelExit.Direction.DOWN:
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
	go_to_next_map()

func _on_exit_rail_exit_used() -> void:
	if is_transitioning:
		return


	if !player.can_move:
		return
	player.can_move = false
	exit_mine.emit()
