extends Node
class_name MemoryClass

@export var RAWChatlogs: Array[Dictionary]
@export var Summeries: Array[Dictionary]
@export var ChatLogs: String
var summery_interval: int = 1500
var httpm = HTTPRequest.new()
var https = HTTPRequest.new()
var host = "http://127.0.0.1:8000"
@warning_ignore("unused_signal")
signal remember_done(result: Variant)
var threads:Array[Thread] =[]

func _ready():
	add_child(httpm)
	add_child(https)
	httpm.connect("request_completed", Callable(self, "_memories_response"))
	https.connect("request_completed", Callable(self, "_memories_response"))
	$"../Aimanager/Summerizer".connect("done", summery_done)


func remember(mlog: Dictionary, timestamp: Array) -> void:
	var thread := Thread.new()
	threads.append(thread)
	thread.start(_threaded_remember.bind(mlog, timestamp), Thread.PRIORITY_NORMAL)
func _physics_process(_delta):
	for thread in threads:
		if thread.is_alive():
			thread.wait_to_finish()
		

func _threaded_remember(mlog: Dictionary, timestamp: Array) -> void:
	var listeners: Array[String] = []
	for i in mlog.keys():
		listeners.append(str(i).to_lower())

	var payload := {"query": mlog.values()[0], "listener_ids": listeners}

	if timestamp.size() >= 7:
		payload["time_range"] = ["%s %s/%s/%04d %d:%s %s" % timestamp]

	var json_payload := JSON.stringify(payload)

	var client := HTTPClient.new()
	client.blocking_mode_enabled = true

	var url_parts = host.replace("http://", "").split(":")
	var host_name = url_parts[0]
	var port = int(url_parts[1]) if url_parts.size() > 1 else 8000

	if client.connect_to_host(host_name, port) != OK:
		call_deferred("emit_signal", "remember_done", null)
		return

	while client.get_status() == HTTPClient.STATUS_CONNECTING:
		client.poll()
		OS.delay_msec(5)

	client.request(
		HTTPClient.METHOD_POST, "/query", ["Content-Type: application/json"], json_payload
	)

	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)

	var response := ""
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() == 0:
			OS.delay_msec(5)
			continue
		response += chunk.get_string_from_utf8()
	if !response:
			return
	var result: Array = str_to_var(response).results
	print(result)
	for mem:int in result.size():
		result[mem].erase("id")
		result[mem].erase("tags")
		result[mem].erase("adjusted_score")
	if result:
		call_deferred("emit_signal", "remember_done", result)
	else:
		call_deferred("emit_signal", "remember_done", null)


func memorize(mlog: Dictionary, timestamp: String):
	var url = host + "/add"  # Replace with your actual FastAPI URL
	if !mlog.get("listeners", []):
		mlog["listeners"] = ["Adan", "Isla"]
		mlog["content"] = mlog.values()[0]
	var listeners: Array[String] = []
	for i in mlog["listeners"]:
		var lower = i.to_lower()
		listeners.append(lower)

	var payload = {
		"text": mlog.get("content", ""), "listener_ids": listeners, "timestamp": timestamp
	}
	if !mlog.get("content", ""):
		return
	var json_body = JSON.stringify(payload)

	httpm.timeout = 1
	var err = httpm.request(url, [], HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("HTTP request failed with error: ", err)


func _on_memorize_response(result, response_code, _headers, body):
	print(result.get_string_from_utf8())
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
