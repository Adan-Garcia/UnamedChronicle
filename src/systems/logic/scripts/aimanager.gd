extends Node
class_name Ai_Manager

## Runs every AI request on a worker thread and reports back on the main thread.
##  - _generate(): text models (GameMaster, Chronicler, fallback Referee) via /api/generate
##  - _decide():   the Jev decision model (Referee) via /api/decide or /v1/systemone

const CONFIG_PATH := "res://assets/data/ai/ai_config.json"
const USER_CONFIG_PATH := "user://ai_config.json"

@onready var referee: Referee = $Referee
@onready var Gamemaster: GameMaster = $GameMaster

var config: Dictionary = {}
var threads := {}
var _next_id := 0

## Emitted when a text generation finishes. `text` is empty on failure.
@warning_ignore("unused_signal")
signal stream_done(request_id: int, text: String)
## Emitted when a decision finishes. `result` is empty on failure.
@warning_ignore("unused_signal")
signal decision_done(request_id: int, result: Dictionary)


func _ready():
	config = _load_config()


func _exit_tree():
	for thread: Thread in threads.values():
		thread.wait_to_finish()
	threads.clear()


## Unique id for any request that flows through the game (actions, AI calls).
func next_id() -> int:
	_next_id += 1
	return _next_id


func _load_config() -> Dictionary:
	var cfg: Dictionary = {}
	if FileAccess.file_exists(CONFIG_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if parsed is Dictionary:
			cfg = parsed
	# user://ai_config.json overrides individual keys per section
	if FileAccess.file_exists(USER_CONFIG_PATH):
		var user = JSON.parse_string(FileAccess.get_file_as_string(USER_CONFIG_PATH))
		if user is Dictionary:
			for section in user.keys():
				if user[section] is Dictionary and cfg.get(section) is Dictionary:
					cfg[section].merge(user[section], true)
				else:
					cfg[section] = user[section]
	return cfg


func make_text_model(section: String) -> AIModel:
	var model := AIModel.new()
	var cfg: Dictionary = config.get(section, {})
	model.endpoint = cfg.get("endpoint", model.endpoint)
	model.Name = cfg.get("model", model.Name)
	model.extras = {"temperature": cfg.get("temperature", 0.4)}
	return model


func make_decision_model() -> DecisionModel:
	var model := DecisionModel.new()
	var cfg: Dictionary = config.get("decision", {})
	model.endpoint = cfg.get("endpoint", model.endpoint)
	model.path = cfg.get("path", model.path)
	model.Name = cfg.get("model", model.Name)
	model.api_key_env = cfg.get("api_key_env", model.api_key_env)
	model.keep_alive = str(cfg.get("keep_alive", model.keep_alive))
	return model


func _generate(prompt: String, model: AIModel, id: int) -> void:
	var payload: Dictionary = model.extras.duplicate(true)
	# Ollama keeps sampling settings under "options"; "format" stays top level
	var options := {}
	for key in payload.keys():
		if key != "format":
			options[key] = payload[key]
			payload.erase(key)
	payload.merge({"model": model.Name, "prompt": prompt, "stream": false, "options": options})
	_start(id, _threaded_generate.bind(id, model.endpoint, payload))


func _decide(state: String, questions: Dictionary, model: DecisionModel, id: int) -> void:
	var body := model.build_body(state, questions)
	_start(id, _threaded_decide.bind(id, model.endpoint, model.path, body, model.headers()))


func _start(id: int, callable: Callable) -> void:
	var thread := Thread.new()
	threads[id] = thread
	thread.start(callable, Thread.PRIORITY_NORMAL)


func _threaded_generate(request_id: int, endpoint: String, payload: Dictionary) -> void:
	var res := _post_json(
		endpoint, "/api/generate", payload, PackedStringArray(["Content-Type: application/json"])
	)
	var text := ""
	if res.ok and res.json is Dictionary:
		text = str(res.json.get("response", ""))
	else:
		push_error("Generation %d failed: %s" % [request_id, res.error])
	_finish.call_deferred(request_id, "stream_done", text)


func _threaded_decide(
	request_id: int, endpoint: String, path: String, body: Dictionary, headers: PackedStringArray
) -> void:
	var res := _post_json(endpoint, path, body, headers)
	var result: Dictionary = {}
	if res.ok and res.json is Dictionary and res.json.has("answers"):
		result = res.json
	else:
		push_warning("Decision %d failed: %s" % [request_id, res.error])
	_finish.call_deferred(request_id, "decision_done", result)


func _finish(request_id: int, sig: String, value) -> void:
	if threads.has(request_id):
		threads[request_id].wait_to_finish()
		threads.erase(request_id)
	emit_signal(sig, request_id, value)


## Blocking JSON POST. Returns {ok, code, json, error}. Safe to call from a worker thread.
static func _post_json(
	endpoint: String, path: String, body: Dictionary, headers: PackedStringArray
) -> Dictionary:
	var result := {"ok": false, "code": 0, "json": null, "error": ""}
	var target := _parse_endpoint(endpoint)
	var client := HTTPClient.new()
	client.blocking_mode_enabled = true
	var tls: TLSOptions = TLSOptions.client() if target.tls else null
	if client.connect_to_host(target.host, target.port, tls) != OK:
		result.error = "could not connect to %s" % endpoint
		return result

	var deadline := Time.get_ticks_msec() + 15000
	while client.get_status() in [HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING]:
		client.poll()
		if Time.get_ticks_msec() > deadline:
			result.error = "timed out connecting to %s" % endpoint
			return result
		OS.delay_msec(5)
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		result.error = "could not connect to %s (status %d)" % [endpoint, client.get_status()]
		return result

	var full_path: String = target.base_path.trim_suffix("/") + path
	if client.request(HTTPClient.METHOD_POST, full_path, headers, JSON.stringify(body, "", false)) != OK:
		result.error = "request to %s failed" % full_path
		return result
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)

	var raw := PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() == 0:
			OS.delay_msec(5)
			continue
		raw.append_array(chunk)
	result.code = client.get_response_code()
	client.close()

	var text := raw.get_string_from_utf8()
	result.json = JSON.parse_string(text) if text != "" else null
	if result.code < 200 or result.code >= 300:
		result.error = "HTTP %d: %s" % [result.code, text.left(300)]
		return result
	if result.json == null:
		result.error = "invalid JSON response"
		return result
	result.ok = true
	return result


## "http://host:port/base" or bare "host:port" -> {host, port, tls, base_path}
static func _parse_endpoint(endpoint: String) -> Dictionary:
	var tls := endpoint.begins_with("https://")
	var rest := endpoint.trim_prefix("https://").trim_prefix("http://")
	var base_path := ""
	var slash := rest.find("/")
	if slash != -1:
		base_path = rest.substr(slash)
		rest = rest.substr(0, slash)
	var host := rest
	var port := 443 if tls else 80
	if rest.contains(":"):
		host = rest.get_slice(":", 0)
		port = int(rest.get_slice(":", 1))
	return {"host": host, "port": port, "tls": tls, "base_path": base_path}
