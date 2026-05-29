class_name BoxSplitter
extends Node2D

@onready var dialogue_box: RichTextLabel = %DialogueLabel

## Strip all XML tags from a string, leaving only the visible text content.
func _strip_xml_tags(text: String) -> String:
	var result: String = ""
	var inside_tag: bool = false
	for ch in text:
		if ch == "<":
			inside_tag = true
		elif ch == ">":
			inside_tag = false
		elif not inside_tag:
			result += ch
	return result

## Split text on spaces that are outside of XML tags, so inline tags like
## <color value="aa-text-red">word</color> are never torn apart.
func _split_words_preserving_tags(text: String) -> Array[String]:
	var tokens: Array[String] = []
	var current: String = ""
	var inside_tag: bool = false
	for ch in text:
		if ch == "<":
			inside_tag = true
			current += ch
		elif ch == ">":
			inside_tag = false
			current += ch
		elif ch == " " and not inside_tag:
			if current.length() > 0:
				tokens.append(current)
			current = ""
		else:
			current += ch
	if current.length() > 0:
		tokens.append(current)
	return tokens

func split_text_into_blocks(text: String) -> Array[String]:
	if dialogue_box == null:
		dialogue_box = %DialogueLabel

	var text_blocks: Array[String] = []
	var split_text: Array[String] = _split_words_preserving_tags(text)
	var current_text: String = ""

	for word in split_text:
		var new_current_text = current_text + word + " "
		# Measure only the visible characters (strip XML tags) so inline markup
		# like <color value="..."> doesn't inflate the measured line width.
		dialogue_box.text = _strip_xml_tags(new_current_text)
		if dialogue_box.get_line_count() > 4:
			current_text = current_text.strip_edges()
			text_blocks.append(current_text)
			current_text = ""
		current_text += word
		current_text += " "

	if current_text.length() > 0:
		current_text = current_text.strip_edges()
		text_blocks.append(current_text)

	return text_blocks
