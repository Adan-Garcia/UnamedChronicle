extends VBoxContainer

@export var Options: Dictionary[String,Dictionary]
var nodes: Dictionary[String,HBoxContainer]


func _ready():
	for option in Options.keys():
		var node
		var label: Label = Label.new()
		label.text = option
		add_child(label)
		if Options[option].type == "String":
			node = load("res://scenes/resources/Text_Input.tscn").instantiate()
		elif Options[option].type.contains("range"):
			node = load("res://scenes/resources/Slider_Input.tscn").instantiate()
			node.range = Options[option].range
		nodes[option] = node
		add_child(node)
