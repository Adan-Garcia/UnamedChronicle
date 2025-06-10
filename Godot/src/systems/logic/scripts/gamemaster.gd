extends Node

class_name GameMaster

var id: int


func _ready():
	await get_tree().process_frame
	Global.AIManager.stream_done.connect(_on_stream_done)
	Global.AIManager.stream_chunk.connect(_on_stream_chunk)


func _continue():
	var persona_path := "res://assets/data/personas/core/GameMaster.txt"
	if !FileAccess.file_exists(persona_path):
		push_error("Failed to load GameMaster persona")
		return

	var system_prompt := FileAccess.get_file_as_string(persona_path).strip_edges()
	print(Global.Memory.remember(Global.Memory.RAWChatlogs.back()))
	# Build system prompt with time and player name substitutions
	var time_str := "%s %s/%s/%04d %d:%s %s" % Global._get_time()
	system_prompt = system_prompt % [Global.PlayerName, time_str]

	var messages: Array[Dictionary] = [
		{"role": "system", "content": system_prompt},
		# This assumes your chat log is a string like:
		# "Player: ... \nNPC: ... \n..." — you may need to split and tag if not
		{"role": "user", "content": Global.Memory.ChatLogs.strip_edges()}
	]

	# Set up AI model
	var master = AIModel.new()
	master.Name = "hf.co/bartowski/Cydonia-22B-v1.2-GGUF:Q4_K_M"

	master.extras["temperature"] = 0.9
	master.extras["top_p"] = 0.95
	master.extras["presence_penalty"] = 0.6
	master.extras["frequency_penalty"] = 0.4
	master.extras["repetition_penalty"] = 1.15
	master.extras["stop"] = ["Adan:"]  # optional stopping condition
	master.extras["mirostat"] = 1

	# This tells the backend you're expecting a message-style response
	master.extras["format"] = {
		"type": "object",
		"properties":
		{
			"messages":
			{
				"type": "array",
				"items":
				{
					"type": "object",
					"properties":
					{
						"role": {"type": "string", "description": "who is speaking"},
						"content": {"type": "string", "description": "the actual message"},
						"listeners":
						{
							"type": "array",
							"items": {"type": "string"},
							"description": "list of who can hear the message"
						}
					},
					"required": ["role", "content", "listeners"]
				}
			}
		},
		"required": ["messages"]
	}

	id = Time.get_ticks_msec() * 10
	Global.AIManager._generate(messages, master, id, true)


func _on_stream_chunk(request_id: int, msg: Dictionary) -> void:
	if request_id == id:
		Global.clientside._new_message(msg["role"], msg["content"])
		Global.Memory.memorize(msg, "%s %s/%s/%04d %d:%s %s" % Global._get_time())


func _on_stream_done(request_id: int, text: String) -> void:
	if request_id == id:
		Global.clientside._finish_thinking()
