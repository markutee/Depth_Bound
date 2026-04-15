extends Node2D

const FILL_PERCENTAGE: float = 0.2
const LADDER_CHANCE: float = 0.9
const ROCK_SCENE = preload("res://scenes/rock.tscn")
const LADDER_SCENE = preload("res://scenes/ladder.tscn")
const SECRET_ROOM = preload("res://scenes/levels/secret_room.tscn")
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


var secret_room_found_on_level: Dictionary = {}

var current_map_index: int = 0
var current_depth: int = 1
var down_ladder: Area2D
var rocks_remaining: int = 0
var transition_direction: String = "start"
var is_transitioning: bool = false

var in_secret_room: bool = false
var return_map_index: int = 0
var return_depth: int = 1
var return_player_position: Vector2 = Vector2.ZERO

signal change_depth
signal exit_mine

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	setup_map()

func reset_depth() -> void:
	current_map_index = 0
	current_depth = 1
	transition_direction = "start"
	in_secret_room = false
	secret_room_found_on_level.clear()
	change_depth.emit(current_depth)
	setup_map()

func setup_map() -> void:
	_clear_map()
	await get_tree().process_frame
	if !_generate_map():
		return
	
	_position_objects()
	_generate_rocks()

#-------------------
# Map navigation
#-------------------
func go_to_next_map() -> void:
	if is_transitioning:
		return
	change_map_with_fade("down")

func go_to_previous_map() -> void:
	if is_transitioning:
		return
	change_map_with_fade("up")

func change_map_with_fade(direction: String) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	player.can_move = false

	await fade_out()

	if direction == "down":
		if current_map_index >= MAPS.size() - 1:
			await fade_in()
			player.can_move = true
			is_transitioning = false
			return

		current_map_index += 1
		current_depth = current_map_index + 1
		transition_direction = "down"

	elif direction == "up":
		if current_map_index <= 0:
			await fade_in()
			player.can_move = true
			is_transitioning = false
			return

		current_map_index -= 1
		current_depth = current_map_index + 1
		transition_direction = "up"

	change_depth.emit(current_depth)
	await setup_map()
	await fade_in()

	player.can_move = true
	is_transitioning = false

#-------------------
# Fade
#-------------------
func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.35)
	await tween.finished

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	await tween.finished

#-------------------
# Map setup
#-------------------
func _clear_map() -> void:
	if current_map:
		current_map.queue_free()
		current_map = null

	if down_ladder:
		down_ladder.queue_free()
		down_ladder = null

	for child in $OreContainer.get_children():
		child.queue_free()

	for child in rock_container.get_children():
		child.queue_free()

func _generate_map() -> bool:
	if in_secret_room:
		current_map = SECRET_ROOM.instantiate()
		game.add_child(current_map)
		return true

	if current_map_index < 0 or current_map_index >= MAPS.size():
		return false
	
	current_map = MAPS[current_map_index].instantiate()
	game.add_child(current_map)
	return true
	

func _position_objects() -> void:
	var spawn_node: Marker2D

	if in_secret_room:
		spawn_node = current_map.get_node("PlayerSpawn")
	elif transition_direction == "up" and current_map.has_node("SpawnUp"):
		spawn_node = current_map.get_node("SpawnUp")
	else:
		spawn_node = current_map.get_node("PlayerSpawn")

	player.reset(spawn_node.position)

	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.force_update_scroll()

	if current_map.has_node("ExitDown"):
		var exit_down = current_map.get_node("ExitDown")
		if not exit_down.exit_used.is_connected(_on_level_exit_used):
			exit_down.exit_used.connect(_on_level_exit_used)

	if current_map.has_node("ExitUp"):
		var exit_up = current_map.get_node("ExitUp")
		if not exit_up.exit_used.is_connected(_on_level_exit_used):
			exit_up.exit_used.connect(_on_level_exit_used)

	if current_map.has_node("ExitRail"):
		var exit_rail = current_map.get_node("ExitRail")
		if not exit_rail.exit_used.is_connected(_on_exit_rail_exit_used):
			exit_rail.exit_used.connect(_on_exit_rail_exit_used)

#-------------------
# Rock generation
#-------------------
func _generate_rocks() -> void:
	if in_secret_room:
		rocks_remaining = 0
		return

	var ground_layer: TileMapLayer = current_map.get_node("Ground")
	var props_layer: TileMapLayer = current_map.get_node("Props")
	var support_layer: TileMapLayer = current_map.get_node("Support")

	var available_cells: Array[Vector2i] = []

	for cell in ground_layer.get_used_cells():
		var tile_data: TileData = ground_layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue

		if props_layer.get_cell_source_id(cell) != -1:
			continue
		if support_layer.get_cell_source_id(cell) != -1:
			continue

		if tile_data.get_custom_data("can_spawn_rocks"):
			available_cells.append(cell)

	available_cells.shuffle()

	var num_rocks: int = int(available_cells.size() * FILL_PERCENTAGE)
	rocks_remaining = num_rocks
	
	var valid_rocks: Array[RockData] = []
	for rock in rock_types:
		if current_depth >= rock.min_depth:
			valid_rocks.append(rock)

	for i in range(min(num_rocks, available_cells.size())):
		var rock = ROCK_SCENE.instantiate()
		var cell = available_cells[i]

		rock.data = get_random_rock(valid_rocks)
		rock.global_position = ground_layer.map_to_local(cell)

		rock_container.add_child(rock)
		rock.broken.connect(_on_rock_broken)

func get_random_rock(options: Array[RockData]) -> RockData:
	var total_weight := 0
	for rock in options:
		total_weight += rock.rarity

	var roll := randi_range(0, total_weight - 1)
	var sum := 0

	for rock in options:
		sum += rock.rarity
		if roll < sum:
			return rock

	return options[0]

#-------------------
# Exit logic
#-------------------
func _on_level_exit_used(direction: int) -> void:
	if is_transitioning:
		return

	if in_secret_room and direction == LevelExit.Direction.UP:
		return_from_secret_room()
		return

	match direction:
		LevelExit.Direction.UP:
			go_to_previous_map()
		LevelExit.Direction.DOWN:
			go_to_next_map()

func _on_exit_rail_exit_used() -> void:
	if is_transitioning or !player.can_move:
		return

	if in_secret_room:
		return_from_secret_room()
		return

	player.can_move = false
	exit_mine.emit()

#-------------------
# Ladder → Secret room
#-------------------
func _on_rock_broken(pos: Vector2) -> void:
	rocks_remaining -= 1

	if in_secret_room:
		return

	if secret_room_found_on_level.get(current_map_index, false):
		return

	if down_ladder != null:
		return
	
	if randf() < LADDER_CHANCE:
		_create_down_ladder(pos)

func _create_down_ladder(pos: Vector2) -> void:
	down_ladder = LADDER_SCENE.instantiate()
	down_ladder.position = pos
	add_child(down_ladder)

	if down_ladder.has_method("set_texture_for_map"):
		down_ladder.set_texture_for_map(current_map_index)

	down_ladder.ladder_used.connect(_on_down_ladder_used)
	print("Ladder created and signal connected")

func _on_down_ladder_used() -> void:
	print("_on_down_ladder_used called")
	enter_secret_room()

func enter_secret_room() -> void:
	if is_transitioning or in_secret_room:
		return

	is_transitioning = true
	player.can_move = false

	return_map_index = current_map_index
	return_depth = current_depth
	return_player_position = player.position
	secret_room_found_on_level[current_map_index] = true
	in_secret_room = true
	transition_direction = "start"

	return_map_index = current_map_index
	return_depth = current_depth
	in_secret_room = true
	transition_direction = "start"

	await fade_out()
	await setup_map()
	await fade_in()

	player.can_move = true
	is_transitioning = false
	print("entered secret room")

func return_from_secret_room() -> void:
	if is_transitioning or !in_secret_room:
		return

	is_transitioning = true
	player.can_move = false

	in_secret_room = false
	current_map_index = return_map_index
	current_depth = return_depth
	transition_direction = "start"
	change_depth.emit(current_depth)

	await fade_out()
	await setup_map()

	player.reset(return_player_position)
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.force_update_scroll()

	await fade_in()

	player.can_move = true
	is_transitioning = false
