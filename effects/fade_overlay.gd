extends ColorRect

var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	ScriptManager.register_handler("fade.to_black", _handle_fade_to_black)
	ScriptManager.register_handler("fade.from_black", _handle_fade_from_black)
	
	# Start as solid black to prevent any first-frame flash of the courtroom
	visible = true
	color = Color(0, 0, 0, 1)
	
	# Wait for the script engine to start executing.
	# If the script has a fade.from_black command, it will create a tween.
	# If no tween is active after 2 frames, hide the overlay.
	await get_tree().process_frame
	await get_tree().process_frame
	if color.a == 1.0 and (tween == null or not tween.is_valid()):
		visible = false
		color.a = 0.0

func _handle_fade_to_black(args: Dictionary):
	var duration = float(args.get("duration", "1.0"))
	visible = true
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(self, "color:a", 1.0, duration)
	if MusicPlayer.instance and MusicPlayer.instance.playing:
		tween.tween_property(MusicPlayer.instance, "volume_db", -80.0, duration)
	await tween.finished

func _handle_fade_from_black(args: Dictionary):
	var duration = float(args.get("duration", "1.0"))
	if tween:
		tween.kill()
	
	# Ensure the overlay is visible and solid black before we begin fading out
	visible = true
	if color.a < 1.0:
		color.a = 1.0
		
	tween = create_tween()
	tween.tween_property(self, "color:a", 0.0, duration)
	await tween.finished
	tween.tween_callback(func(): visible = false)
