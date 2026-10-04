extends Control

const PLAYER_FILE := "^PlayerStats[0-9]+(\\.[0-9]+)?\\.tres$"


func _ready():
	$%chatbutton.connect("pressed", start)
	await get_tree().process_frame
	start()


func start():
	var regex: RegEx = RegEx.new()
	regex.compile(PLAYER_FILE)
	for file_name in DirAccess.get_files_at("user://"):
		if !regex.search(file_name):
			continue
		var path := "user://%s" % file_name
		var player = load(path)
		if not player is Player:
			continue
		if player.Location == null:
			player.Location = Global.default_location()
		Global.Players.register(player, path)
		Global.PlayerName = player.Name
		Global.PlayerID = file_name.sha256_text()
		get_tree().change_scene_to_file("res://src/ui/chat.tscn")
		return
	get_tree().change_scene_to_file("res://src/ui/Character_Creator.tscn")
