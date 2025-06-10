extends Node
class_name MemoryClass

@export var RAWChatlogs: Array[Dictionary]
@export var Summeries: Array[Dictionary]
@export var ChatLogs: String
var summery_interval: int = 1500


func _ready():
	$"../Aimanager/Summerizer".connect("done", summery_done)


func remember(log: Dictionary):
	pass


func memorize(log: Dictionary, timestamp: String):
	var http = HTTPRequest.new()
	add_child(http)
	var url = "http://127.0.0.1:8000/add"  # Replace with your actual FastAPI URL
	if !log.get("listeners", []):
		return
	var payload = {
		"text": log.get("content", ""),
		"listener_ids": log.get("listeners", []),
		"timestamp": timestamp
	}

	var json_body = JSON.stringify(payload)
	print(log.get("listeners", []))
	http.connect("request_completed", Callable(self, "_on_memorize_response"))
	var err = http.request(url, [], HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("HTTP request failed with error: ", err)


func _on_memorize_response(result, response_code, headers, body):
	if response_code == 200 or response_code == 201:
		print("Memory saved successfully:", body.get_string_from_utf8())

	else:
		print("Failed to save memory. Status:", response_code, "Body:", body.get_string_from_utf8())


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
