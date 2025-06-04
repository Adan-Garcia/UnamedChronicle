extends Node

class_name GameMaster

var id: int


func _ready():
	await get_tree().process_frame
	Global.AIManager.stream_chunk.connect(_on_stream_chunk)


func _continue(_action: Action):
	var prompt: String

	var personafile: bool = FileAccess.file_exists("res://assets/data/personas/core/GameMaster.txt")
	if !personafile:
		push_error("failed to load gamemaster")
		return
	prompt = (
		FileAccess.get_file_as_string("res://assets/data/personas/core/GameMaster.txt")
		% [Global.PlayerName, "%s %s/%s/%04d %d:%s %s" % Global._get_time(), Global.Memory.ChatLogs]
	)
	var master = AIModel.new()
	print(prompt)
	master.extras["temperature"] = 0.9  # Allows more creative, less predictable output
	master.extras["top_p"] = 0.95  # Nucleus sampling: consider top tokens whose combined prob ≤ 0.9
	master.extras["presence_penalty"] = 0.6  # Penalizes repeating themes or ideas
	master.extras["frequency_penalty"] = 0.4  # Penalizes exact word repetitions
	master.extras["repetition_penalty"] = 1.15  # Custom penalty — not OpenAI native, but some models accept it
	master.extras["stop"] = ["Adan:"]  # Optional: Stops before generating player lines
	master.extras["mirostat"] = 1
	master.Name = "hf.co/bartowski/Cydonia-22B-v1.2-GGUF:Q4_K_M"
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
					"properties": {"role": {"type": "string"}, "content": {"type": "string"}},
					"required": ["role", "content"]
				}
			}
		},
		"required": ["messages"]
	}
	id = Time.get_ticks_msec() * 10
	Global.AIManager._generate(prompt, master, Time.get_ticks_msec() * 10)


func _on_stream_chunk(request_id: int, text: String) -> void:
	if request_id == id:
		var messagesraw = str_to_var(text)["messages"]
		print("RESPONSE")
		for msg in messagesraw:
			Global.clientside._new_message(msg["role"], msg["content"])
			print(msg["role"] + ": " + msg["content"])
		Global.clientside._finish_thinking()
