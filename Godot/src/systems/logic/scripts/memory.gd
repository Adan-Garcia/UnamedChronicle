extends Node
class_name MemoryClass

@export var RAWChatlogs: Array[Dictionary]
@export var Summeries: Array[Dictionary]
@export var ChatLogs: String
var summery_interval: int = 15


func _ready():
	$"../Aimanager/Summerizer".connect("done", summery_done)


func _pull_save():
	if RAWChatlogs:
		var indx = 0
		for msg in RAWChatlogs:
			var key = msg.keys()[0]
			Global.clientside._new_message(key, msg[key], false, null, false)
			if (indx % summery_interval) == 0 and indx > 1:
				var trimmed = RAWChatlogs.duplicate().slice(indx - summery_interval)
				trimmed.resize(summery_interval)
				Global.AIManager.Summerizer.summerize(trimmed, indx)
			indx += 1


func _add(Name: String, Message: String):
	RAWChatlogs.append({Name: Message})

	if (RAWChatlogs.size() % summery_interval) == 0:
		Global.AIManager.Summerizer.summerize(
			RAWChatlogs.slice(RAWChatlogs.size() - summery_interval),
			RAWChatlogs.size() + summery_interval
		)

	else:
		update_logs()


func update_logs():
	ChatLogs = ""
	for summery in Summeries:
		ChatLogs += "System: " + summery.Message + "\n\n"
	var context = (
		RAWChatlogs.duplicate().slice(Summeries.back().index)
		if Summeries
		else RAWChatlogs.duplicate()
	)
	for msg: Dictionary in context:
		var usr = msg.keys()[0]
		ChatLogs += usr + ": " + msg[usr] + "\n\n"


func summery_done(msg, index):
	#add new summery to the queue with index of last 15 messages
	#print("summery done")
	Summeries.append({"Message": msg, "index": index})

	update_logs()
