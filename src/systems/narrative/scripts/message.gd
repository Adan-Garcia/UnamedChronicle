@tool
class_name message
extends RichTextLabel

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
	bbcode_enabled = true
	focus_mode = FocusMode.FOCUS_ALL
	set_process_input(true)


func _update_message() -> void:
	parent = get_parent()
	if parent:
		grandparent = parent.get_parent()
		grandparent.scroll_vertical = int(parent.size.y)
	# Re-render with name and converted BBCode each frame
	text = "[b]%s[/b]: %s" % [Name, custom_to_bbcode(Message)]


func _gui_input(event: InputEvent) -> void:
	# Capture key events to build Message string
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_BACKSPACE:
				if Message.length() > 0:
					Message = Message.substr(0, Message.length() - 1)
			KEY_ENTER, KEY_KP_ENTER:
				Message += "\n"
			_:
				var c = event.unicode
				if c >= 32:
					Message += char(c)


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
	converted = thought.sub(converted, "[i][color=#AAAAAA]$1[/color][/i]", true)

	# Optionally: replace actions inside *action* if you are using asterisk notation
	var action = RegEx.new()
	action.compile("\\*(.*?)\\*")
	converted = action.sub(converted, "[color=#AAAAAA]$1[/color]", true)

	return converted
