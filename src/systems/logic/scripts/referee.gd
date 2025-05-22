extends Node
class_name Referee

signal approved(id)
signal rejected(id)


func _ready():
	await get_tree().process_frame
	Global.AIManager.connect("stream_done", ValidateAction)


func _judge(action: Action, id: int):
	var prompt: String

	var personafile: bool = FileAccess.file_exists("res://assets/data/personas/core/referee.txt")
	if !personafile:
		push_error("failed to load referee")
		return -1
	var player_data = Global.Players.info[action.player_name].Data._to_json()
	prompt = (
		FileAccess.get_file_as_string("res://assets/data/personas/core/referee.txt")
		% [player_data, action.raw_input]
	)

	# AI model setup
	var ref = AIModel.new()
	ref.extras["format"] = {
		"type": "object",
		"properties":
		{
			"outcome": {"type": "string", "enum": ["approved", "rejected"]},
			"stat_changes":
			{
				"type": "object",
				"properties":
				{
					"Energy": {"type": "number"},
					"Mana": {"type": "number"},
					"Health": {"type": "number"}
				},
				"additionalProperties": false
			},
			"description": {"type": "string"}
		},
		"required": ["outcome", "description"]
	}
	ref.extras["temperature"] = 0.1
	ref.Name = "hf.co/MaziyarPanahi/Phi-3.5-mini-instruct-GGUF:Q4_K_M"

	Global.AIManager._generate(prompt, ref, id)


func ValidateAction(request_id: int, text: String):
	if request_id in Global.Queue.binds:
		var dict = str_to_var(text)
		if dict["outcome"] != "rejected":
			emit_signal("approved", request_id)
			Global.AIManager.Gamemaster._continue(Global.Queue.binds[request_id])
		else:
			emit_signal("rejected", request_id)
			print(dict)
