class_name message
extends HBoxContainer

@export_category("Chat")
@export var Name: String = ""
@export_group("Time")
@export var Day: int = 0
@export var Month: int = 0
@export var Year: int = 0
@export var Hour: int = 0
@export var Minute: int = 0

@export_group("")
@export var Message: String = ""
var parent: VBoxContainer
var grandparent: ScrollContainer


func _ready():
	# Enable BBCode parsing and allow focus for GUI input
	$Message.bbcode_enabled = true
	$Name.bbcode_enabled = true
	$Name/TextEdit2.text = Name
	$Message/TextEdit.text = Message
	_update_message()
	_update_min_size()


func _update_message() -> void:
	parent = get_parent()
	if parent:
		grandparent = parent.get_parent()
		grandparent.scroll_vertical = int(parent.size.y)
	# Re-render with name and converted BBCode each frame
	$Message.text = custom_to_bbcode(Message)
	$Name.text = "[b]%s[/b]: " % Name


# Convert custom-style text to BBCode for RichTextLabel
func custom_to_bbcode(tex: String) -> String:
	var converted: String = tex

	# Replace dialogue inside « »
	var dialogue = RegEx.new()
	dialogue.compile("«(.*?)»")
	converted = dialogue.sub(converted, "[color=#00BFFF]$1[/color]", true)

	# Replace thoughts inside << >>
	var thought = RegEx.new()
	thought.compile("<<(.*?)>>")
	converted = thought.sub(converted, "[i][color=#AAAAAA]<<$1>>[/color][/i]", true)

	# Optionally: replace actions inside *action* if you are using asterisk notation
	var action = RegEx.new()
	action.compile("\\*(.*?)\\*")
	converted = action.sub(converted, "[color=#AAAAAA]*$1*[/color]", true)

	return converted


func _on_text_edit_text_changed():
	Message = $Message/TextEdit.text
	_update_message()
	_update_min_size()


func _on_text_edit_2_text_changed():
	Name = $Name/TextEdit2.text
	_update_message()
	_update_min_size()


func _update_min_size():
	var height = max($Name/TextEdit2.size.y, $Message/TextEdit.size.y)
	$Name.custom_minimum_size.x = $Name/TextEdit2.size.x
	$Name/TextEdit2.position.x = 0
	$Name.update_minimum_size()

	custom_minimum_size.y = height
	update_minimum_size()
