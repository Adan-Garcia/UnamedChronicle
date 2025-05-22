extends TabContainer

@export var nodes: Dictionary[String, HBoxContainer]
var base_classes: Dictionary
var category_maxes: Dictionary[String,int]
var categories: Dictionary[String,VBoxContainer]
var filled_pages: Dictionary[String,bool]
var classselected: bool = false


func _ready():
	base_classes = str_to_var(
		FileAccess.open("res://assets/data/base_class_values.json", FileAccess.READ).get_as_text()
	)
	nodes["Class"].options = base_classes.keys()
	nodes["Class"]._update_options()


func _base_class_update(base_class):
	var base_stats: Dictionary = base_classes[base_classes.keys()[base_class]]
	classselected = true
	category_maxes.clear()
	for i in nodes:
		if i.contains("Name") || i.contains("Class"):
			continue
		nodes[i].value = base_stats[i]
		if category_maxes.has(nodes[i].category):
			category_maxes[nodes[i].category] += nodes[i].value
		else:
			category_maxes[nodes[i].category] = nodes[i].value
		nodes[i]._update_value()


func _cap_scores(tester: String = "", value: int = 0) -> bool:
	var tempval := 0
	for i in categories[nodes[tester].category].nodes.keys():
		if i.contains("Name") || i.contains("Class") or i.contains(tester):
			continue
		tempval += categories[nodes[tester].category].nodes[i].value

	if category_maxes[nodes[tester].category] >= tempval + value:
		return true

	return false


func _normalize_property(maximum: int, cur: int, property_count: int) -> int:
	return round(cur * (10 * property_count) / float(maximum))


func _process(_delta):
	if !classselected:
		current_tab = 0
	var tempval := 0
	for category in categories:
		filled_pages[category] = categories[category]._check_filled()

	for i in categories[categories.keys()[current_tab]].nodes.keys():
		if i.contains("Name") || i.contains("Class"):
			continue
		tempval += categories[categories.keys()[current_tab]].nodes[i].value
	if !filled_pages:
		for i in categories.keys():
			filled_pages[i] = false
	if current_tab != get_tab_count() - 1:
		$"../Panel/MarginContainer/HBoxContainer/Next".text = "Next"
		$"../Panel/MarginContainer/HBoxContainer/Next".disabled = (
			!filled_pages[categories.keys()[current_tab]]
			if filled_pages.has(categories.keys()[current_tab])
			else true
		)
	else:
		$"../Panel/MarginContainer/HBoxContainer/Next".disabled = (
			true if filled_pages.values().has(false) else false
		)
		$"../Panel/MarginContainer/HBoxContainer/Next".text = "Submit"
	$"../Panel/MarginContainer/HBoxContainer/Back".disabled = current_tab == 0
	$"../Panel/MarginContainer/HBoxContainer/Label".visible = current_tab != 0
	$"../Panel/MarginContainer/HBoxContainer/Label".text = (
		(
			"Points Remaining: %s, Max Points: %s"
			% [
				category_maxes[categories.keys()[current_tab]] - tempval,
				category_maxes[categories.keys()[current_tab]]
			]
		)
		if current_tab != 0
		else ""
	)


func _on_next_pressed():
	if current_tab == 3:
		print("submit")
		var normalized: Dictionary[String,int]

		for category in categories.keys():
			if category == "Background":
				continue
			for property in categories[category].nodes.keys():
				normalized[property] = _normalize_property(
					category_maxes[category],
					categories[category].nodes[property].value,
					categories[category].nodes.size()
				)

		var stats: PlayerData = PlayerData.new()
		for i in normalized.keys():
			stats.set(i, normalized[i])
		stats.Name = categories["Background"].nodes["Name"].value
		var player: Player = Player.new()
		player.Data = stats
		player.Name = stats.Name
		ResourceSaver.save(player, "user://PlayerStats%s.tres" % Time.get_unix_time_from_system())
		Global.Players.info[player.Name] = player
	else:
		current_tab += 1


func _on_back_pressed():
	current_tab -= 1
