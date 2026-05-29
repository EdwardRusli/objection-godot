extends Control

var is_transitioning: bool = false
var can_start_game: bool = false

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var press_any_button: Label = $PressAnyButton
@onready var splash_rect: TextureRect = $SplashRect

func _ready():
	# 1. Music start playing (instantly)
	music_player.stream = load("res://audio/music/title.mp3")
	music_player.volume_db = 0.0
	music_player.play()
	
	# 2. Start from black
	fade_overlay.visible = true
	fade_overlay.color.a = 1.0
	splash_rect.visible = true
	press_any_button.visible = false
	
	_play_splash_sequence()

func _play_splash_sequence():
	# Wait 0.5 seconds at the very beginning after music starts
	await get_tree().create_timer(0.8).timeout
	
	# 3. 1 second fade from black to splash
	var tween1 = create_tween()
	tween1.tween_property(fade_overlay, "color:a", 0.0, 2)
	await tween1.finished
	
	# 4. 2 second wait
	await get_tree().create_timer(3.0).timeout
	
	# 5. 1 second fade to black
	var tween2 = create_tween()
	tween2.tween_property(fade_overlay, "color:a", 1.0, 2)
	await tween2.finished
	
	# Setup title screen underneath the black overlay
	splash_rect.visible = false
	press_any_button.visible = true
	press_any_button.modulate.a = 0.0
	await get_tree().create_timer(1).timeout
	# 6. 2 second fade to title screen
	var tween3 = create_tween()
	tween3.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	await tween3.finished
	
	# Fade in the Press Any Button prompt once the title screen has loaded
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(press_any_button, "modulate:a", 1.0, 1.0)
	await fade_in_tween.finished
	
	# Start pulsing "breathing" animation for the Press Any Button prompt
	_start_pulse_animation()
	can_start_game = true

var pulse_tween: Tween

# Called when any input event reaches this control node.
func _input(event: InputEvent):
	# Check if the event is a key press, click, tap, or button press
	if event.is_pressed() and not event is InputEventMouseMotion:
		# Consume the input so it doesn't propagate to other systems
		get_viewport().set_input_as_handled()
		
		# Block input if we are transitioning or the intro sequence hasn't finished
		if is_transitioning or not can_start_game:
			return
			
		_start_transition()

func _start_pulse_animation():
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(press_any_button, "modulate:a", 0.2, 1.0).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(press_any_button, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)

func _start_transition():
	is_transitioning = true
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		
	fade_overlay.visible = true
	fade_overlay.color.a = 0.0
	
	# Disable the pulsing effect during transition so it stays solid/fades out cleanly
	press_any_button.modulate.a = 1.0
	
	var tween = create_tween().set_parallel(true)
	# Fade overlay to black over 1.0 second
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	# Fade music volume to silent (-80.0 dB) over 1.0 second
	tween.tween_property(music_player, "volume_db", -80.0, 1.0)
	# Fade the prompt text out in parallel
	tween.tween_property(press_any_button, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://main.tscn")
