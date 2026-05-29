class_name SoundPlayer
extends Node

static var instance: SoundPlayer

func _enter_tree():
	instance = self

func _ready():
	ScriptManager.register_handler("sound.play", _handle_sound_play)

func _handle_sound_play(args: Dictionary):
	if "res" not in args:
		Utils.print_error("res argument not provided for sound.play command")
		return
	if "delay" in args:
		var delay_time = float(args["delay"])
		if delay_time > 0.0:
			_play_sound_delayed(args["res"], delay_time)
			return
	play_sound(args["res"])

func _play_sound_delayed(path: String, delay: float):
	await get_tree().create_timer(delay).timeout
	play_sound(path)

func play_sound(path: String):
	var new_player = AudioStreamPlayer.new()
	new_player.stream = Utils.load_audio(path)
	new_player.finished.connect(new_player.queue_free)
	add_child(new_player)
	new_player.play()
