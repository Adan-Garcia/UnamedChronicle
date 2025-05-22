extends Node
class_name Ai_Manager

@onready var referee: Referee = $Referee
@onready var Gamemaster: GameMaster = $GameMaster

@export var Models: Dictionary[String,AIModel]
var threads := {}

@warning_ignore("unused_signal")
signal stream_chunk(request_id: int, text: String)
@warning_ignore("unused_signal")
signal stream_done(request_id: int, text: String)


func _ready():
	stream_chunk.connect(_on_stream_chunk)
	stream_done.connect(_on_stream_done)


func _generate(prompt: String, model: AIModel, id: int, stream: bool = false):
	var thread = Thread.new()
	threads[id] = thread
	thread.start(_threaded_generate.bind(id, prompt, model, stream), Thread.PRIORITY_NORMAL)


func _threaded_generate(request_id, prompt_text: String, model: AIModel, stream: bool) -> void:
	# Construct payload with creative parameters
	var options = model.extras
	var payload: Dictionary = options.merged(
		{"model": model.Name, "prompt": prompt_text, "stream": stream}
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
		HTTPClient.METHOD_POST, "/api/generate", ["Content-Type: application/json"], json_body
	)
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)
	var buffer: String = ""
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()

		var chunk = client.read_response_body_chunk()
		if chunk.size() == 0:
			continue

		# defer each token back with the request ID
		var packet = str_to_var(chunk.get_string_from_utf8())
		if packet and packet.has("response"):
			var tok = packet["response"]
			# defer each token back with the request ID
			buffer += tok
			call_deferred("emit_signal", "stream_chunk", request_id, tok)
		if packet and packet.get("done", false):
			break
	# signal completion
	call_deferred("emit_signal", "stream_done", request_id, buffer)
	# Clean up


func _on_stream_chunk(_request_id: int, _text: String) -> void:
	# route to the right UI element, buffer, etc.
	pass


func _on_stream_done(request_id: int, _text: String) -> void:
	threads[request_id].wait_to_finish()
	threads.erase(request_id)
