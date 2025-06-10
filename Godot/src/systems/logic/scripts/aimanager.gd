extends Node
class_name Ai_Manager

@onready var referee: Referee = $Referee
@onready var Gamemaster: GameMaster = $GameMaster
@onready var Summerizer: summerizer = $Summerizer

@export var Models: Dictionary[String,AIModel]
var threads := {}

@warning_ignore("unused_signal")
signal stream_chunk(request_id: int, msg: Dictionary)
@warning_ignore("unused_signal")
signal stream_done(request_id: int, text: String)


func _ready():
	stream_chunk.connect(_on_stream_chunk)
	stream_done.connect(_on_stream_done)


func _generate(messages: Array[Dictionary], model: AIModel, id: int, stream: bool = false):
	var thread = Thread.new()
	threads[id] = thread
	thread.start(_threaded_generate.bind(id, messages, model, stream), Thread.PRIORITY_NORMAL)


func _threaded_generate(
	request_id, messages: Array[Dictionary], model: AIModel, stream: bool
) -> void:
	# Construct payload with creative parameters
	var options = model.extras
	var payload: Dictionary = options.merged(
		{"model": model.Name, "messages": messages, "stream": stream}
	)
	var json_body = JSON.stringify(payload)
	var client: HTTPClient = HTTPClient.new()
	# HTTP streaming logic (unchanged)
	client.blocking_mode_enabled = true

	var host = model.endpoint.split(":")[0]
	var port = int(model.endpoint.get_slice(":", 1))
	if client.connect_to_host(host, port) != OK:
		push_error("Connection failed for request %d" % request_id)
		call_deferred("emit_signal", "stream_done", request_id)
		return
	while client.get_status() == HTTPClient.STATUS_CONNECTING:
		client.poll()
		OS.delay_msec(5)
	client.request(
		HTTPClient.METHOD_POST, "/api/chat", ["Content-Type: application/json"], json_body
	)
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)
	var buffer: String = ""
	var streambuffer: String = ""
	var skipped_first := false
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()

		var chunk = client.read_response_body_chunk()
		if chunk.size() == 0:
			continue

		# defer each token back with the request ID
		var packet = str_to_var(chunk.get_string_from_utf8())

		if packet and packet.has("message"):
			var tok = packet["message"]["content"]
			# defer each token back with the request ID
			buffer += tok

			if stream:
				streambuffer += tok
				if !skipped_first:
					streambuffer = streambuffer.erase(0)
					skipped_first = true
					continue
				while skipped_first:
					var obj_start := streambuffer.find("{")
					if obj_start == -1:
						break

					var brace_count := 0
					var i := obj_start
					var found := false

					while i < streambuffer.length():
						if streambuffer[i] == "{":
							brace_count += 1
						elif streambuffer[i] == "}":
							brace_count -= 1
							if brace_count == 0:
								var json_str := streambuffer.substr(obj_start, i - obj_start + 1)
								var json_result = str_to_var(json_str)

								if json_result:
									call_deferred(
										"emit_signal", "stream_chunk", request_id, json_result
									)

								streambuffer = streambuffer.substr(i + 1)  # Trim parsed part
								found = true
								break
						i += 1

					if not found:
						break  # Wait for more data

		if packet and packet.get("done", false):
			break
	# signal completion
	call_deferred("emit_signal", "stream_done", request_id, buffer)
	# Clean up


func _on_stream_chunk(_request_id: int, _msg: Dictionary) -> void:
	pass


func _on_stream_done(request_id: int, _text: String) -> void:
	threads[request_id].wait_to_finish()
	threads.erase(request_id)
