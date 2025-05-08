extends TabContainer

@export var nodes: Dictionary[String, HBoxContainer]
var base_classes: Dictionary
var total_scoree: int = 140


func _ready():
	base_classes = str_to_var(
		FileAccess.open("res://assets/data/base_class_values.json", FileAccess.READ).get_as_text()
	)
	nodes["Class"].options = base_classes.keys()
	nodes["Class"]._update_options()


func _base_class_update(base_class):
	var base_stats: Dictionary = base_classes[base_classes.keys()[base_class]]
	for i in nodes:
		if i.contains("Name") || i.contains("Class"):
			continue
		nodes[i].value = base_stats[i]

		nodes[i]._update_value()


func _cap_scores(tester: String = "", value: int = 0) -> bool:
	var tempval: int = 0

	for i in nodes:
		if i.contains("Name") or i.contains("Class") or i.contains(tester):
			continue
		if i != "Mana":
			tempval += nodes[i].value
		else:
			tempval += nodes[i].value / 5
	if tempval <= 140 - value:
		return true
	return false
