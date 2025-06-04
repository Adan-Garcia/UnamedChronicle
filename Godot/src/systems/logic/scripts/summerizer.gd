extends Node

class_name summerizer

var ids: Dictionary[int,int]

signal done(summery: String, idx: int)


func _ready():
	await get_tree().process_frame
	Global.AIManager.stream_done.connect(_on_stream_done)


func summerize(chatlogs: Array[Dictionary], index: int):
	var prompt: String

	var personafile: bool = FileAccess.file_exists("res://assets/data/personas/core/Summerizer.txt")
	if !personafile:
		push_error("failed to load Summerizer")
		return
	prompt = (
		FileAccess.get_file_as_string("res://assets/data/personas/core/Summerizer.txt") % [chatlogs]
	)
	var ref = AIModel.new()

	ref.extras["temperature"] = 1.2
	ref.Name = "hf.co/mradermacher/Llama-3.2-3B-Instruct-uncensored-GGUF:Q4_K_M"
	ref.extras["format"] = {
		"type": "object", "properties": {"Summery": {"type": "string"}}, "required": ["Summery"]
	}
	var id = Time.get_ticks_msec() * 100
	ids[id] = index
	Global.AIManager._generate(prompt, ref, id)


func _on_stream_done(request_id: int, text: String) -> void:
	if ids.has(request_id):
		var msg = str_to_var(text)

		emit_signal("done", msg["Summery"], ids[request_id])
		ids.erase(request_id)
