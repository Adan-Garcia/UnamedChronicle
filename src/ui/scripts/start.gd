extends Control


func _ready():
	$%chatbutton.connect("pressed", start)


func start():
	var player_data_files = DirAccess.open("user://").get_files()
	for file_name in player_data_files:
		var regex: RegEx = RegEx.new()
		regex.compile("^PlayerStats[0-9]+\\.[0-9]+\\.tres$")
		if regex.search(file_name):
			#load the resource
			var stats = load("user://%s" % file_name)
			Global.Players.info[stats.Name] = stats
			get_tree().change_scene_to_file("res://src/ui/chat.tscn")
			return
	get_tree().change_scene_to_file("res://src/ui/Character_Creator.tscn")
