extends MarginContainer

@onready var nametag_label: Label = %NametagLabel
@onready var nametag_background: TextureRect = $NametagBackground

# Called when the node enters the scene tree for the first time.
func _ready():
	ScriptManager.register_handler("nametag.set_text", _handle_nametag_set_text)
	visible = false

func _handle_nametag_set_text(args: Dictionary):
	if args.get("text", "") == "":
		visible = false
	else:
		visible = true
		nametag_label.text = args["text"]
		
		var character = args.get("character", "")
		var tex_path = "res://ui/text_box/nametag_new.PNG"
		if character == "pob":
			tex_path = "res://ui/text_box/nametag_purple.png"
		elif character == "ed":
			tex_path = "res://ui/text_box/nametag_yellow.png"
		
		nametag_background.texture = load(tex_path)
