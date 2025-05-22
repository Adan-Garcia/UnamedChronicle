extends Node

class_name GameMaster

var id: int


func _ready():
	await get_tree().process_frame
	Global.AIManager.stream_chunk.connect(_on_stream_chunk)


func _continue(action: Action):
	var prompt: String

	var personafile: bool = FileAccess.file_exists("res://assets/data/personas/core/GameMaster.txt")
	if !personafile:
		push_error("failed to load gamemaster")
		return
	prompt = (
		FileAccess.get_file_as_string("res://assets/data/personas/core/GameMaster.txt")
		% [
			"%s %s/%s/%04d %d:%s %s" % Global._get_time(),
			Global.Worldstate.CurrentWorldState.chat_queue,
			action
		]
	)
	var ref = AIModel.new()
	print(prompt)
	ref.extras["temperature"] = 1.2
	ref.Name = "hf.co/DavidAU/Llama-3.2-8X3B-MOE-Dark-Champion-Instruct-uncensored-abliterated-18.4B-GGUF:Q4_K_M"
	ref.extras["format"] = {
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
	Global.AIManager._generate(prompt, ref, Time.get_ticks_msec() * 10)


func _on_stream_chunk(request_id: int, text: String) -> void:
	if request_id == id:
		var messagesraw = str_to_var(text)["messages"]
		for msg in messagesraw:
			Global.clientside._new_message(msg["role"], msg["content"])
		Global.clientside._finish_thinking()
