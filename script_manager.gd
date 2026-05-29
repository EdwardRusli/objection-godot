class_name ScriptManager
extends Node

# Actions

# More sprite locations

# Verdict
# - verdict <text> <color>
# - verdict show <index>
# - verdict clear

# Gavel slam
# - gavel <frame>

signal user_click

var handlers := {
	"blip.set": _handle_blip_set,
	"sprite.set": _handle_sprite_set,
	"wait": _handle_wait,
	"wait_for_click": _handle_wait_for_click,
	"set_text_speed": _handle_set_text_speed,
}

static var instance: ScriptManager

@onready var dialogue_label: RichTextLabel = GameUI.instance.dialogue_label
@onready var nametag_label: Label = GameUI.instance.nametag_label
@onready var camera: Camera2D = %Camera

const TEXT_SPEED_DEFAULT = 30.0
var text_speed: float = TEXT_SPEED_DEFAULT

static func register_handler(tag_name: String, handler: Callable):
	if instance == null:
		Utils.print_error("ScriptManager doesn't exist")
		return
	if tag_name in instance.handlers.keys():
		Utils.print_error("Handler for \"%s\" already exists" % tag_name)
		return
	instance.handlers[tag_name] = handler

func _enter_tree():
	instance = self

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configure emoji font fallback for dialogue label using the bundled Twitter Color Emoji font
	var emoji_font = load("res://fonts/TwitterColorEmoji-SVGinOT.ttf")
	var main_font := dialogue_label.get_theme_font("normal_font")
	if main_font:
		main_font.fallbacks = [emoji_font]

	await get_tree().process_frame
	_display_text()

const EMBEDDED_SCRIPT = """<payne>
    <cast>
        <character id="k" display_name="Kay" character="kay" />
        <character id="e" display_name="Ed" character="ed" />
        <character id="p" display_name="Phoebe" character="pob" />
    </cast>
    <conversation>
        <startmusic res="res://audio/music/pwr/cross-moderato.wav"/>
        <fade.from_black />
        <dialog id="k" anim="normal">oh actually bringing back ke work force thingy</dialog>
        <dialog id="k" anim="normal">bisa argue ga kalau child nya jadi worker berarti long term family punya source of income?</dialog>
        
        <objection id="e" />
        <dialog id="e" anim="normal">tp klo dinikahin sm opa kaya this is invalid no?</dialog>
        
        <stopmusic />

        <dialog id="p" anim="shock">...</dialog>
        <dialog id="k" anim="annoyed">...</dialog>
        <dialog id="e" anim="normal">...</dialog>
        
        <objection id="p" />
        <startmusic res="res://audio/music/pwr/press.wav"/>
        <dialog id="p" anim="crying">anjing 😭</dialog>
        
        <dialog id="k" anim="normal">LMAO</dialog>
        <dialog id="k" anim="normal">LMAOOOOO</dialog>
        <dialog id="k" anim="deskslam">I CANT STOP LAUGHING</dialog>
        
        <dialog id="e" anim="crying">GBLKKKKKKKKKKKKK 😭</dialog>
        <dialog id="e" anim="crying">😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭</dialog>
        
        <dialog id="k" anim="normal">ed kalau lo fail this ethics class</dialog>
        <dialog id="k" anim="normal">jadi comedian aja dah</dialog>
        <sound res="res://audio/sound/sfx-realization.wav"/>
        <dialog id="p" anim="crying">GW SAKIT PERUT BANGSAT</dialog>
        <dialog id="p" anim="crying">SAKIT BANGET</dialog>
        
        <takethat id="e" />
        <dialog id="e" anim="normal">FAKLAH</dialog>
        <sound res="res://audio/sound/sfx-whoops.wav"/>
        <dialog id="e" anim="crying">EVEN THE NAZI EXAMPLE WAS BETTER DEFENSE THAN THIS 😭</dialog>
        
        <holdit id="k" />
        <dialog id="k" anim="normal">STOP</dialog>
        
        <dialog id="p" anim="crying">PERUT GUE</dialog>
        <dialog id="e" anim="normal">ini rado looking at me like a clinically insane man for laughing silently</dialog>
        <sound res="res://audio/sound/sfx-supershock.wav"/>
        <flash />
        <dialog id="p" anim="crying">RADO WOULD THINK YOU <color value="aa-text-red">ARE</color> A CLINICALLY INSANE MAN IF HE READ THIS BULLSHIT</dialog>
        
        <dialog id="k" anim="normal">ok bisa</dialog>
        <dialog id="k" anim="normal">gini logikanya</dialog>
        <dialog id="k" anim="pointing">do you think opa kaya bakal respect istri muda?</dialog>
        <fade.to_black />
        <stopmusic/>
    </conversation>
</payne>"""

func _display_text():
	var path: String = "res://script.xml"

	var use_payne: bool = true

	for arg in OS.get_cmdline_user_args():
		if arg == "--no-payne" or arg == "--xml":
			use_payne = false
		elif arg.begins_with("--render-script="):
			path = arg.get_slice("=", 1)
			if (path[0] == "\"" and path[-1] == "\"") or (path[0] == "'" and path[-1] == "'"):
				path = path.substr(1, path.length() - 2)

	var xml_content: String = ""
	var load_from_file: bool = false
	
	if OS.has_feature("editor") and FileAccess.file_exists(path):
		load_from_file = true
	elif path != "res://script.xml" and FileAccess.file_exists(path):
		load_from_file = true
		
	if load_from_file:
		print_rich("Running script at \"%s\"..." % path)
		var f := FileAccess.open(path, FileAccess.READ)
		xml_content = f.get_as_text()
	else:
		print_rich("Using embedded script...")
		xml_content = EMBEDDED_SCRIPT

	var xml_str: String = ""
	if use_payne:
		%PayneEngine.parse(xml_content.replace("\n", ""))
		xml_str = %PayneEngine.generate_xml()
	else:
		xml_str = xml_content.replace("\n", "")

	var text_bits := parse_xml_str(xml_str)

	# Start with a blank text box.
	dialogue_label.text = ""
	dialogue_label.clear()

	# All of the text is added to the dialogue label at once.
	var command_bits: Array[Dictionary] = []
	while not text_bits.is_empty():
		# Parse up until we get an clearbox command.
		var bit = text_bits.pop_front()

		if bit.has("text"):
			dialogue_label.append_text(bit["text"])
		elif bit.has("command"):
			if bit["command"] == "color":
				_handle_color(bit.get("args", {}), bit.get("end", false))
			elif bit["command"] == "play":
				# This box is done, so move onto the playing step.
				await _play_textbox(command_bits)
				if not text_bits.is_empty():
					dialogue_label.text = ""
					dialogue_label.clear()
					command_bits.clear()
			else:
				# This is a command to play at a certain index.
				command_bits.append(bit)
	get_tree().quit(0)


func _handle_color(args: Dictionary, is_end: bool):
	if not is_end:
		dialogue_label.push_color(Utils.get_color_from_string(args.get("value", "white"), Color.WHITE))
	else:
		dialogue_label.pop()


func _play_textbox(command_bits: Array[Dictionary]):
	dialogue_label.visible_characters = 0
	while dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		await _handle_command(command_bits)
		await get_tree().create_timer(1 / text_speed).timeout
		dialogue_label.visible_characters += 1
		VoiceBlipPlayer.instance.play_blip()
	await _handle_command(command_bits)


func _handle_command(text_bits: Array[Dictionary]):
	for bit in text_bits:
		if not bit.has("index"):
			continue
		if bit["index"] != dialogue_label.visible_characters:
			continue

		if handlers.has(bit["command"]):
			var handler: Callable = handlers[bit["command"]]
			await handler.call(bit["args"])


func _handle_blip_set(args: Dictionary):
	match args["type"]:
		"male":
			VoiceBlipPlayer.instance.start_blips(VoiceBlipPlayer.Gender.MALE)
		"female":
			VoiceBlipPlayer.instance.start_blips(VoiceBlipPlayer.Gender.FEMALE)
		"typewriter":
			VoiceBlipPlayer.instance.start_blips(VoiceBlipPlayer.Gender.TYPEWRITER)
		"none":
			VoiceBlipPlayer.instance.stop_blips()
		_:
			Utils.print_error("Invalid blip type \"%s\" provided" % args["type"])


func _handle_sprite_set(args: Dictionary):
	var sprite_to_change: CharacterSpriteContainer = CharacterSpriteContainer.sprite_containers[args["pos"]]

	if args.has("res"):
		sprite_to_change.sprite_frames = load(args["res"])
	sprite_to_change.animation = args["anim"]
	sprite_to_change.frame = 0
	sprite_to_change.play()

func _handle_wait(args: Dictionary):
	if "duration" not in args:
		Utils.print_error("duration not provided for wait")
		return
	await get_tree().create_timer(float(args["duration"])).timeout

func _handle_wait_for_click(_args: Dictionary):
	await user_click

func _input(event: InputEvent):
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept"):
		user_click.emit()

func _handle_set_text_speed(args: Dictionary):
	var new_speed := float(args.get("value", "1.0")) * TEXT_SPEED_DEFAULT
	text_speed = new_speed

static func parse_xml_str(xml_str: String) -> Array[Dictionary]:
	var p := XMLParser.new()
	var e := p.open_buffer(xml_str.to_utf8_buffer())
	var bits: Array[Dictionary] = []
	var text_index: int = 0
	while p.read() != ERR_FILE_EOF:
		match p.get_node_type():
			XMLParser.NODE_ELEMENT:
				var attributes := {}
				for attr_i in p.get_attribute_count():
					attributes[p.get_attribute_name(attr_i)] = p.get_attribute_value(attr_i)
				bits.append({ "command": p.get_node_name(), "args": attributes, "index": text_index })
				if p.get_node_name() == "play":
					text_index = 0
			XMLParser.NODE_ELEMENT_END:
				bits.append({ "command": p.get_node_name(), "end": true, "index": text_index })
			XMLParser.NODE_TEXT:
				bits.append({ "text": p.get_node_data() })
				text_index += p.get_node_data().length()
	return bits
