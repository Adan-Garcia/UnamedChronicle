extends VBoxContainer

@export var category: String
@export var Options: Dictionary


func _ready():
	Options = str_to_var(
		(
			FileAccess
			. open("res://assets/data/character_creator_options.json", FileAccess.READ)
			. get_as_text()
		)
	)

	for option in Options.keys():
		if Options[option].category != category:
			Options.erase(option)

	for option in Options.keys():
		var node
		var label: Label = Label.new()
		label.text = Options[option].hint
		add_child(label)
		if Options[option].type.to_lower() == "string":
			node = load("res://src/ui/widgets/Text_Input.tscn").instantiate()
			node.submitable = false
		elif Options[option].type.to_lower() == "range":
			node = load("res://src/ui/widgets/Slider_Input.tscn").instantiate()
			node.slider_range = Options[option].range[1]
		elif Options[option].type.to_lower() == "option":
			node = load("res://src/ui/widgets/Option_Input.tscn").instantiate()
			
			if option == "Class":
				node.connect("updated", $"../../../.."._base_class_update)
		node.name = option
		$"../../../..".nodes[option] = node
		add_child(node)
