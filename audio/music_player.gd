class_name MusicPlayer
extends AudioStreamPlayer

static var instance: MusicPlayer

func _enter_tree():
	instance = self

# Called when the node enters the scene tree for the first time.
func _ready():
	ScriptManager.register_handler("music.play", _handle_music_play)
	ScriptManager.register_handler("music.stop", _handle_music_stop)

func _handle_music_play(args: Dictionary):
	volume_db = 0.0
	if "res" in args and args["res"] != "":
		stream = Utils.load_audio(args["res"])
	play()

func _handle_music_stop(_args: Dictionary):
	stop()
	volume_db = 0.0

