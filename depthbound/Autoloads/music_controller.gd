extends Node2D


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer



func bgm_play():
	audio_stream_player.stream = preload("res://assets/audio/StaringAtReflections.mp3")
	audio_stream_player.play()
