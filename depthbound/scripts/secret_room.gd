extends Node2D

@export var artefact_scenes: Array[PackedScene]
@onready var altar: Marker2D = $altar

func _ready() -> void:
	print("SECRET_ROOM.GD READY")
	print("artefact_scenes size: ", artefact_scenes.size())
	print("altar found: ", altar != null)
	spawn_artifact()

func spawn_artifact() -> void:
	print("SPAWN_ARTIFACT CALLED")

	if artefact_scenes.is_empty():
		print("artifact_scenes is empty")
		return

	var artefact = artefact_scenes.pick_random().instantiate()
	print("artefact instantiated: ", artefact)

	add_child(artefact)
	artefact.global_position = altar.global_position

	print("artefact spawned at: ", artefact.global_position)
