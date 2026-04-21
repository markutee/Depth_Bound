extends Node

var audio_stream_player: AudioStreamPlayer

func _ready():
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)

func bgm_play():
	audio_stream_player.stream = preload("res://assets/audio/StaringAtReflections.mp3")
	audio_stream_player.play()
