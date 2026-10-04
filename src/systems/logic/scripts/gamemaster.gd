extends Node

class_name GameMaster

## Narrates how the world reacts to an action the Referee has already judged.

signal narrated(messages: Array)

const PERSONA_PATH := "res://assets/data/personas/core/GameMaster.txt"
const RECENT_CONTEXT := 30
const FORMAT := {
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

var pending: Dictionary[int, Action] = {}


func _ready():
	await get_tree().process_frame
	Global.AIManager.stream_done.connect(_on_stream_done)


func _continue(action: Action, verdict: Dictionary = {}) -> void:
	if !FileAccess.file_exists(PERSONA_PATH):
		push_error("failed to load gamemaster")
		_deliver([])
		return
	var prompt := FileAccess.get_file_as_string(PERSONA_PATH) % [
		"%s %s/%s/%04d %d:%s %s" % Global._get_time(),
		action.player_name,
		_describe_location(action.location),
		Global.Worldstate.recent_messages(RECENT_CONTEXT),
		action.raw_input,
		verdict.get("outcome", "success"),
		JSON.stringify(verdict.get("stat_changes", {})),
		verdict.get("description", ""),
	]
	var model: AIModel = Global.AIManager.make_text_model("gamemaster")
	model.extras["format"] = FORMAT
	var id: int = Global.AIManager.next_id()
	pending[id] = action
	Global.AIManager._generate(prompt, model, id)


func _describe_location(location: Address) -> String:
	if location == null:
		return "an unknown place"
	return "%s (%s province, %s)" % [location.Town, location.Province, location.Empire]


func _on_stream_done(request_id: int, text: String) -> void:
	if request_id not in pending:
		return
	pending.erase(request_id)
	var messages: Array = []
	var parsed = JSON.parse_string(text) if text != "" else null
	if parsed is Dictionary and parsed.get("messages") is Array:
		for msg in parsed["messages"]:
			if msg is Dictionary and msg.has("role") and msg.has("content"):
				messages.append({"role": str(msg["role"]), "content": str(msg["content"])})
	if messages.is_empty():
		push_warning("GameMaster returned no usable narration")
		messages.append(
			{"role": "system", "content": "*The world holds its breath. Nothing seems to answer.*"}
		)
	_deliver(messages)


func _deliver(messages: Array) -> void:
	for msg in messages:
		Global.Worldstate.add_message(msg["role"], msg["content"])
	narrated.emit(messages)
	Global.Worldstate.save_world()
