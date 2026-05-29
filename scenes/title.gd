extends Control

var is_transitioning: bool = false
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var music_player: AudioStreamPlayer = $MusicPlayer

func _ready():
	# Load and play the title screen music at full volume (0 dB)
	music_player.stream = load("res://audio/music/title.mp3")
	music_player.volume_db = 0.0
	music_player.play()

# Called when any input event reaches this control node.
func _input(event: InputEvent):
	# If we are already transitioning, ignore all inputs
	if is_transitioning:
		return
		
	# Check if the event is a key press, click, tap, or button press
	if event.is_pressed() and not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		_start_transition()

func _start_transition():
	is_transitioning = true
	fade_overlay.visible = true
	fade_overlay.color.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	# Fade overlay to black over 1.0 second
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	# Fade music volume to silent (-80.0 dB) over 1.0 second
	tween.tween_property(music_player, "volume_db", -80.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://main.tscn")
