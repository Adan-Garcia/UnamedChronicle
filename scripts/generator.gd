# Generator.gd – improved multi-shot prompting with persona injection and scene control
@tool
extends Node
class_name Generator

# Model configuration
@export var model: String = "llama2"

# Roleplay settings
@export var character: String = ""
@export var persona: String = ""  # Persona injection string
@export var examples: String = ""
@export var story_context: String = ""  # World or scene introduction
@export var memories: String = ""  # Character memories
@export var new_messages: Array = []  # Incoming dialogue

# Generation options
@export var options: Dictionary = {}

signal generated(data)
signal streamed(data)
signal error(message)

var client: HTTPClient = HTTPClient.new()
var streaming := false
var buffer: String = ""
var json_body
var headers
var _thread: Thread = null

var core_rules = ""


func _ready():
	var rules = FileAccess.open("res://AI/rules.txt", FileAccess.READ)
	core_rules = rules.get_as_text()
	rules.close()


func generate(stream: bool = false) -> void:
	if _thread:
		_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(_threaded_generate.bind(stream), Thread.PRIORITY_NORMAL)


# Builds a prompt with world, persona, multi-shot examples, rules, memory, and conversation
func _threaded_generate(stream: bool = false) -> void:
	var lines: Array = []

	# 1) World or story context
	lines.append("[World Context]")
	lines.append(story_context)
	lines.append("")

	# 2) Persona injection
	lines.append("[Persona - %s]" % character)
	lines.append(persona)
	lines.append("")

	#3) Multi-Shot Examples:

	# 4) Core Rules:
	lines.append("[Rules]")
	lines.append(core_rules)
	lines.append("")

	# 5) Memories
	lines.append("[%s Memory]: %s" % [character, memories])
	lines.append("")

	lines.append("[Formatting Rules]:")
	lines.append("-Stay strictly in first-person cinematic narration as %s." % character)
	lines.append("-Embed vivid physical actions, sensory details, and one inner thought per reply.")
	lines.append("-Dialogue must be inside guillemets « ».")
	lines.append("-Inner thoughts must be inside double angle brackets << >>.")
	lines.append("- Actions must be narrated naturally outside of speech quotes.")
	lines.append("- No {metadata} allowed anywhere.")
	lines.append("- Each reply must stop naturally after one cinematic moment (~100–150 words).")
	lines.append(
		"- You MUST begin with cinematic action + sensory detail, NOT inner monologue alone."
	)
	(
		lines
		. append(
			"- Every reply must begin with vivid physical action and sensory detail. No dialogue or inner thought first."
		)
	)
	lines.append("- Never use parentheses ( ) for actions. Actions must be natural narrative.")
	lines.append("- Stop after one vivid moment and natural choice — no long inner debates.")
	(
		lines
		. append(
			"- If action follows speech, close speech with a period inside guillemets: «Barely.» I grumble."
		)
	)
	(
		lines
		. append(
			"Do not summarize. DO NOT break character. DO NOT UNDER ANY CIRCUMSTANCE WRITE FOR ANOTHER CHARACTER"
		)
	)
	(
		lines
		. append(
			"Failure to format internal thoughts correctly will be treated as a critical formatting error."
		)
	)
	lines.append("Begin your response below:")

	lines.append("[examples - %s]" % character)
	lines.append(examples)
	lines.append("")

	# 6) Current conversation
	lines.append("[Starting Dialogue]:")
	for msg in new_messages:
		if msg is Dictionary and msg.has("name"):
			lines.append("[%s]: %s" % [msg["name"], msg["content"]])

	# 7) Prompt the main character

	lines.append("[%s]:" % character)

	var prompt_text: String = String("\n").join(lines)
	print(prompt_text)
	# Construct payload with creative parameters
	var payload: Dictionary = options.merged(
		{
			"model": model,
			"prompt": prompt_text,
			"stream": stream,
			"max_new_tokens": 160,
			"temperature": 0.65,
			"top_p": 0.9,
			"frequency_penalty": 0.2,
			"presence_penalty": 0.4,
			"stop": ["[", "\n\n", "[Narrator]:", "[World]:", "[System]:", "Scene:", "Location:"]
		}
	)
	json_body = JSON.stringify(payload)

	# HTTP streaming logic (unchanged)
	client.blocking_mode_enabled = false
	var err = client.connect_to_host("127.0.0.1", 11434)
	if err != OK:
		error.emit.bind("Connection failed: %s" % err).call_deferred()
		return

	buffer = ""
	headers = ["Content-Type: application/json"]
	while true:
		client.poll()
		match client.get_status():
			HTTPClient.STATUS_CONNECTED:
				if not streaming:
					streaming = true
					var r = client.request(
						HTTPClient.METHOD_POST, "/api/generate", headers, json_body
					)
					if r != OK:
						push_error("Request error: %s" % r)

			HTTPClient.STATUS_BODY:
				var chunk: PackedByteArray = client.read_response_body_chunk()
				if chunk.size() > 0:
					var raw = str_to_var(chunk.get_string_from_utf8())
					if raw:
						buffer += raw.get("response", "")

						streamed.emit.bind(buffer).call_deferred()
					if raw and raw.get("done", false):
						_finalize_response()

						break

			HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_CANT_CONNECT:
				push_error("HTTP connection failed: %s" % client.get_status())

			HTTPClient.Status.STATUS_DISCONNECTED:
				_finalize_response()
				break
		OS.delay_msec(15)


func _finalize_response() -> void:
	streaming = false

	generated.emit.bind(buffer).call_deferred()


func _on_error() -> void:
	error.emit.bind("Network error").call_deferred()
