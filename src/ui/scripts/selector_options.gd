extends VBoxContainer

@export var category: String
@export var Options: Dictionary
@export var nodes: Dictionary[String,HBoxContainer]
@export var filled: bool = false


func _ready():
	Options = str_to_var(
		(
			FileAccess
			. open("res://assets/data/character_creator_options.json", FileAccess.READ)
			. get_as_text()
		)
	)
	$"../../../..".categories[category] = self
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
		node.category = category
		#if option != "Class":
		#	node.connect("updated", $"../../../.."._node_updated)
		node.name = option

		$"../../../..".nodes[option] = node
		nodes[option] = node
		add_child(node)


func _check_filled() -> bool:
	var state: bool = true
	for i in nodes.keys():
		if !nodes[i].value:
			state = false

	return state
