extends Node2D

const FILL_PERCENTAGE: float = 0.2
const LADDER_CHANCE: float = 0.2
const ROCK_SCENE = preload("res://scenes/rock.tscn")
const LADDER_SCENE = preload("res://scenes/ladder.tscn")
const SECRET_ROOM = preload("res://scenes/levels/secret_room.tscn")
const LADDER_USE_DISTANCE: float = 24.0
const MAPS = [
	preload("res://scenes/levels/map_1.tscn"),
	preload("res://scenes/levels/map_2.tscn"),
	preload("res://scenes/levels/map_3.tscn"),
	preload("res://scenes/levels/map_4.tscn"),
	preload("res://scenes/levels/map_5.tscn")
]

@export var rock_types: Array[RockData] = []
@onready var audio_stream_player: AudioStreamPlayer = $MusicController/AudioStreamPlayer

var current_map: Node2D
@onready var rock_container: Node2D = $RockContainer
@onready var player: Player = $Player
@onready var game: Node2D = $"."
@onready var fade_rect: ColorRect = $FadeLayer/ColorRect

var secret_room_found_on_level: Dictionary = {}
var secret_room_looted_on_level: Dictionary = {}
var secret_room_artifact_index_on_level: Dictionary = {}
var block_secret_room_entry: bool = false
var secret_room_entry_cooldown: bool = false

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
var ladder_map_index: int = -1
var allow_secret_room_entry: bool = false
var spawned_ladders: Dictionary = {}
var down_ladder_spawn_map_index: int = -1
var level_rock_data: Dictionary = {}
var rock_instance_to_cell: Dictionary = {}

# UUSI: tallennetaan taso, jolta poistuttiin exit raililla
var last_exit_rail_map_index: int = 0
var last_exit_rail_depth: int = 1
var has_saved_exit_rail_return: bool = false

# UUSI: määrää mitä spawnia käytetään kun kenttä ladataan
# "start" = normaali aloitus
# "up" = tullaan alemmasta tasosta takaisin ylöspäin
# "exit_rail_return" = palataan takaisin kaivokseen exit railin jälkeen
var spawn_mode: String = "start"

signal change_depth
signal exit_mine

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	setup_map()

func reset_depth() -> void:
	current_map_index = 0
	current_depth = 1
	transition_direction = "start"
	spawn_mode = "start"
	in_secret_room = false
	block_secret_room_entry = false
	secret_room_found_on_level.clear()
	secret_room_looted_on_level.clear()
	secret_room_artifact_index_on_level.clear()
	secret_room_entry_cooldown = false
	level_rock_data.clear()
	rock_instance_to_cell.clear()
	spawned_ladders.clear()
	down_ladder_spawn_map_index = -1
	change_depth.emit(current_depth)
	setup_map()

# UUSI:
# Kutsu tätä silloin, kun pelaaja tulee takaisin kaivokseen ulkomaailmasta
func return_to_saved_exit_rail_level() -> void:
	if !has_saved_exit_rail_return:
		reset_depth()
		return

	current_map_index = last_exit_rail_map_index
	current_depth = last_exit_rail_depth
	transition_direction = "start"
	spawn_mode = "exit_rail_return"
	in_secret_room = false

	change_depth.emit(current_depth)
	setup_map()

func setup_map() -> void:
	allow_secret_room_entry = false
	_clear_map()
	await get_tree().process_frame
	if !_generate_map():
		return

	_position_objects()
	_generate_rocks()
	_restore_ladder_for_current_map()
	allow_secret_room_entry = !in_secret_room

	if !in_secret_room:
		_start_secret_room_entry_cooldown()

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
	allow_secret_room_entry = false
	_clear_down_ladder()

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
		spawn_mode = "start"

	elif direction == "up":
		if current_map_index <= 0:
			await fade_in()
			player.can_move = true
			is_transitioning = false
			return

		current_map_index -= 1
		current_depth = current_map_index + 1
		transition_direction = "up"
		spawn_mode = "up"

		change_depth.emit(current_depth)
	await setup_map()
	await fade_in()

	player.can_move = true
	is_transitioning = false

	# Odota yksi frame ennen kuin ladderiin saa taas mennä,
	# jotta transitionin aikana tulevat overlap/signaalit eivät vedä secret roomiin.
	await get_tree().process_frame
	block_secret_room_entry = false

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

	_clear_down_ladder()

	for child in $OreContainer.get_children():
		child.queue_free()

	for child in rock_container.get_children():
		child.queue_free()

	rock_instance_to_cell.clear()

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
	elif spawn_mode == "exit_rail_return" and current_map.has_node("ExitRailSpawn"):
		spawn_node = current_map.get_node("ExitRailSpawn")
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

	if level_rock_data.has(current_map_index):
		_load_saved_rocks()
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

	var valid_rocks: Array[RockData] = []
	for rock in rock_types:
		if current_depth >= rock.min_depth:
			valid_rocks.append(rock)

	var saved_rocks: Array = []

	for i in range(min(num_rocks, available_cells.size())):
		var cell = available_cells[i]
		var rock_data: RockData = get_random_rock(valid_rocks)

		saved_rocks.append({
	"cell": cell,
	"rock_data": rock_data,
	"health": rock_data.max_health
})

	level_rock_data[current_map_index] = saved_rocks
	_load_saved_rocks()

func _load_saved_rocks() -> void:
	var ground_layer: TileMapLayer = current_map.get_node("Ground")
	var saved_rocks: Array = level_rock_data.get(current_map_index, [])

	rocks_remaining = saved_rocks.size()
	rock_instance_to_cell.clear()

	for rock_entry in saved_rocks:
		var rock: Rock = ROCK_SCENE.instantiate() as Rock
		var cell: Vector2i = rock_entry["cell"]
		var rock_data: RockData = rock_entry["rock_data"]
		var saved_health: int = rock_entry["health"]

		rock.data = rock_data
		rock.health = saved_health
		rock.global_position = ground_layer.map_to_local(cell)

		rock_container.add_child(rock)
		rock_instance_to_cell[rock] = cell
		rock.connect("broken", Callable(self, "_on_rock_broken").bind(rock))

		if rock.has_signal("damaged"):
			rock.connect("damaged", Callable(self, "_on_rock_damaged").bind(rock))
		else:
			push_warning("Rock is missing 'damaged' signal: " + str(rock.name))


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

	block_secret_room_entry = true

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

	# UUSI: tallennetaan taso, jolta poistuttiin
	last_exit_rail_map_index = current_map_index
	last_exit_rail_depth = current_depth
	has_saved_exit_rail_return = true

	player.can_move = false
	exit_mine.emit()

#-------------------
# Ladder → Secret room
#-------------------
func _on_rock_broken(pos: Vector2, rock: Rock) -> void:
	rocks_remaining -= 1

	if !in_secret_room and rock_instance_to_cell.has(rock):
		var broken_cell: Vector2i = rock_instance_to_cell[rock]
		var saved_rocks: Array = level_rock_data.get(current_map_index, [])

		for i in range(saved_rocks.size() - 1, -1, -1):
			if saved_rocks[i]["cell"] == broken_cell:
				saved_rocks.remove_at(i)
				break

		level_rock_data[current_map_index] = saved_rocks
		rock_instance_to_cell.erase(rock)

	if in_secret_room:
		return

	if secret_room_found_on_level.get(current_map_index, false):
		return

	if down_ladder != null:
		return

	if spawned_ladders.has(current_map_index):
		return

	if randf() < LADDER_CHANCE:
		_create_down_ladder(pos)

func _restore_ladder_for_current_map() -> void:
	if in_secret_room:
		return

	if !spawned_ladders.has(current_map_index):
		return

	if down_ladder != null:
		return

	var ladder_pos: Vector2 = spawned_ladders[current_map_index]
	down_ladder = LADDER_SCENE.instantiate()
	down_ladder.position = ladder_pos
	current_map.add_child(down_ladder)

	ladder_map_index = current_map_index
	down_ladder_spawn_map_index = current_map_index

	if down_ladder.has_method("set_texture_for_map"):
		down_ladder.set_texture_for_map(current_map_index)

	down_ladder.ladder_used.connect(_on_down_ladder_used)


func _on_rock_damaged(new_health: int, rock: Rock) -> void:
	if in_secret_room:
		return

	if !rock_instance_to_cell.has(rock):
		return

	var damaged_cell: Vector2i = rock_instance_to_cell[rock]
	var saved_rocks: Array = level_rock_data.get(current_map_index, [])

	for i in range(saved_rocks.size()):
		if saved_rocks[i]["cell"] == damaged_cell:
			saved_rocks[i]["health"] = new_health
			break

	level_rock_data[current_map_index] = saved_rocks

func _create_down_ladder(pos: Vector2) -> void:
	down_ladder = LADDER_SCENE.instantiate()
	down_ladder.position = pos
	current_map.add_child(down_ladder)

	ladder_map_index = current_map_index
	down_ladder_spawn_map_index = current_map_index
	spawned_ladders[current_map_index] = pos

	if down_ladder.has_method("set_texture_for_map"):
		down_ladder.set_texture_for_map(current_map_index)

	down_ladder.ladder_used.connect(_on_down_ladder_used)
	print("Ladder created on map: ", ladder_map_index)

func _is_player_close_enough_to_ladder() -> bool:
	if down_ladder == null:
		return false

	return player.global_position.distance_to(down_ladder.global_position) <= LADDER_USE_DISTANCE

func _clear_down_ladder() -> void:
	if down_ladder:
		if down_ladder.ladder_used.is_connected(_on_down_ladder_used):
			down_ladder.ladder_used.disconnect(_on_down_ladder_used)
		down_ladder.queue_free()
		down_ladder = null

func _on_down_ladder_used() -> void:
	if is_transitioning:
		return
	if block_secret_room_entry:
		return
	if secret_room_entry_cooldown:
		return
	if !player.can_move:
		return
	if !allow_secret_room_entry:
		return
	if down_ladder == null:
		return
	if down_ladder_spawn_map_index != current_map_index:
		print("Ignored stale ladder signal. down_ladder_spawn_map_index=", down_ladder_spawn_map_index, " current_map_index=", current_map_index)
		return
	if !_is_player_close_enough_to_ladder():
		print("Ignored ladder use because player is too far from ladder")
		return

	print("_on_down_ladder_used called on map: ", current_map_index)
	allow_secret_room_entry = false
	enter_secret_room()

func enter_secret_room() -> void:
	if is_transitioning or in_secret_room:
		return

	is_transitioning = true
	player.can_move = false
	allow_secret_room_entry = false

	return_map_index = current_map_index
	return_depth = current_depth
	return_player_position = player.position
	secret_room_found_on_level[current_map_index] = true
	in_secret_room = true
	transition_direction = "start"
	spawn_mode = "start"

	_clear_down_ladder()

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
	spawn_mode = "start"
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

	await get_tree().process_frame
	block_secret_room_entry = false

func _start_secret_room_entry_cooldown(duration: float = 0.25) -> void:
	secret_room_entry_cooldown = true
	var timer := get_tree().create_timer(duration)
	await timer.timeout
	secret_room_entry_cooldown = false
