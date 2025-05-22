extends Node
class_name chronicler
@export var ChatLog: Array[Dictionary]
const chatlogpath = "user://chatlog.json"


func _ready():
	if !FileAccess.file_exists(chatlogpath):
		print("Failed To load log")
		var temp = FileAccess.open(chatlogpath, FileAccess.WRITE_READ)
		temp.store_string("[]")
		temp.close()

	var raw = FileAccess.get_file_as_string(chatlogpath)
	var messages = str_to_var(raw)
	for rawchatmessage in messages:
		ChatLog.append(rawchatmessage)
