extends Node2D

@export var artefact_scenes: Array[PackedScene]
@onready var altar: Marker2D = $altar

func _ready() -> void:
	var game = get_parent()
	if game == null:
		return

	var level_index: int = game.return_map_index

	# Jos tämän tason secret room on jo lootattu, ei spawnata enää mitään
	if game.secret_room_looted_on_level.get(level_index, false):
		return

	spawn_artifact_for_level(level_index, game)

func spawn_artifact_for_level(level_index: int, game: Node) -> void:
	if artefact_scenes.is_empty():
		return

	var artifact_index: int

	# Jos tälle tasolle on jo valittu artefacti aiemmin, käytä samaa
	if game.secret_room_artifact_index_on_level.has(level_index):
		artifact_index = game.secret_room_artifact_index_on_level[level_index]
	else:
		artifact_index = randi_range(0, artefact_scenes.size() - 1)
		game.secret_room_artifact_index_on_level[level_index] = artifact_index

	var artefact = artefact_scenes[artifact_index].instantiate()
	add_child(artefact)
	artefact.global_position = altar.global_position

	# Jos artefactissa on collected-signaali, kuunnellaan sitä
	if artefact.has_signal("collected"):
		artefact.connect("collected", Callable(self, "_on_artefact_collected").bind(level_index))
		
func _on_artefact_collected(level_index: int) -> void:
	var game = get_parent()
	if game == null:
		return

	game.secret_room_looted_on_level[level_index] = true
