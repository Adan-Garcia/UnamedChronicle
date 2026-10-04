extends Node
class_name Referee

## Judges player actions. The primary judge is the Jev decision model, which
## answers typed questions about the action with calibrated probabilities.
## If Jev is unreachable the text-LLM referee prompt is used instead.

## Emitted with the action id and a verdict:
## {outcome, stat_changes, description, confidence, judge}
signal approved(id: int, verdict: Dictionary)
signal rejected(id: int, verdict: Dictionary)

const PERSONA_PATH := "res://assets/data/personas/core/referee.txt"
const RECENT_CONTEXT := 8

## Only "impossible" actions are rejected; everything else is narrated.
const OUTCOMES := {
	"success": "The action fully works. The character's stats and resources comfortably cover it.",
	"partial_success":
	"The action mostly works, but with a drawback, cost, complication or rising tension.",
	"failure": "The action is attempted but fails, with a setback such as a wound, suspicion or lost time.",
	"impossible":
	"The action cannot happen at all: it is vague world-altering wishful thinking (e.g. 'kill the king' with no plan), needs resources the character lacks (spells with no mana, items they do not have), or breaks the world's logic."
}

const QUESTIONS := {
	"outcome":
	{
		"type": "choice",
		"instructions":
		"Stats range 0-20 (10 is an average capable adventurer, 15+ is needed for exceptional tasks). Given the character's stats, resources and situation, how does the attempted action resolve?",
		"criteria": OUTCOMES
	},
	"energy_cost":
	{
		"type": "score",
		"instructions": "How much physical or mental energy does attempting this action spend?",
		"criteria":
		[
			"None: talking, looking, thinking",
			"Light: walking, small sneaking, casual work",
			"Moderate: climbing, running, hard labour",
			"Heavy: a fight, a long chase",
			"Intense: sustained combat or spellcasting",
			"Exhausting: pushing far past the body's limits"
		]
	},
	"injury":
	{
		"type": "score",
		"instructions": "How badly is the character hurt as a direct result of this action?",
		"criteria":
		[
			"Unharmed",
			"Scrapes and bruises",
			"A real wound",
			"A serious injury",
			"A grievous, life-threatening injury"
		]
	},
	"mana_cost":
	{
		"type": "score",
		"instructions": "How much magical power (mana) does this action draw on?",
		"criteria":
		[
			"No magic is used",
			"A minor cantrip",
			"A standard spell",
			"A powerful spell",
			"A great ritual"
		]
	}
}

## request id sent to the AI manager -> action id from the queue
var pending_decisions: Dictionary[int, int] = {}
var pending_fallbacks: Dictionary[int, int] = {}


func _ready():
	await get_tree().process_frame
	Global.AIManager.decision_done.connect(_on_decision_done)
	Global.AIManager.stream_done.connect(_on_fallback_done)


func _judge(action: Action, id: int) -> void:
	var request: int = Global.AIManager.next_id()
	pending_decisions[request] = id
	Global.AIManager._decide(
		build_state(action), QUESTIONS, Global.AIManager.make_decision_model(), request
	)


## The block of state Jev reads: who is acting, where, what just happened, what they try.
func build_state(action: Action) -> String:
	var player: Player = Global.Players.info.get(action.player_name)
	var lines := PackedStringArray()
	if player:
		lines.append("Character sheet (stats 0-20): %s" % JSON.stringify(player.Data._to_json()))
	if action.location:
		lines.append(
			(
				"Location: %s, %s province, %s"
				% [action.location.Town, action.location.Province, action.location.Empire]
			)
		)
	var recent: String = Global.Worldstate.recent_messages(RECENT_CONTEXT)
	if recent != "":
		lines.append("Recent events:\n%s" % recent)
	lines.append("Attempted action by %s: %s" % [action.player_name, action.raw_input])
	return "\n".join(lines)


func _on_decision_done(request: int, result: Dictionary) -> void:
	if request not in pending_decisions:
		return
	var id: int = pending_decisions[request]
	pending_decisions.erase(request)
	var action: Action = Global.Queue.binds.get(id)
	if action == null:
		return
	if result.is_empty():
		push_warning("Jev decision model unavailable, falling back to text referee")
		_judge_with_llm(action, id)
		return
	_resolve(id, verdict_from_decision(result, action))


## Turn Jev's typed answers into a verdict the rest of the game understands.
static func verdict_from_decision(result: Dictionary, action: Action) -> Dictionary:
	var answers: Dictionary = result.get("answers", {})
	var outcome_answer: Dictionary = answers.get("outcome", {})
	var outcome: String = outcome_answer.get("choice", "failure")
	if outcome not in OUTCOMES:
		outcome = "failure"

	var energy := float(answers.get("energy_cost", {}).get("score", 0.0))
	var injury := float(answers.get("injury", {}).get("score", 0.0))
	var mana := float(answers.get("mana_cost", {}).get("score", 0.0))

	var stat_changes := {}
	if outcome != "impossible":
		if energy >= 0.5:
			stat_changes["Energy"] = -snappedf(energy, 0.1)
		if injury >= 0.5:
			stat_changes["Health"] = -snappedf(injury * 1.5, 0.1)
		if mana >= 0.5:
			stat_changes["Mana"] = -roundi(mana * 2)

	return {
		"outcome": outcome,
		"stat_changes": stat_changes,
		"confidence": float(outcome_answer.get("confidence", 0.0)),
		"probabilities": outcome_answer.get("probabilities", {}),
		"description":
		(
			"%s attempts \"%s\": %s."
			% [action.player_name, action.raw_input, outcome.replace("_", " ")]
		),
		"judge": str(result.get("model", "jev")),
	}


func _judge_with_llm(action: Action, id: int) -> void:
	if !FileAccess.file_exists(PERSONA_PATH):
		push_error("failed to load referee persona")
		_resolve(id, {"outcome": "failure", "stat_changes": {}, "description": "", "judge": "none"})
		return
	var player_data := ""
	var player: Player = Global.Players.info.get(action.player_name)
	if player:
		player_data = JSON.stringify(player.Data._to_json())
	var prompt := FileAccess.get_file_as_string(PERSONA_PATH) % [player_data, action.raw_input]

	var model: AIModel = Global.AIManager.make_text_model("referee_fallback")
	model.extras["format"] = {
		"type": "object",
		"properties":
		{
			"outcome": {"type": "string", "enum": OUTCOMES.keys()},
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
	var request: int = Global.AIManager.next_id()
	pending_fallbacks[request] = id
	Global.AIManager._generate(prompt, model, request)


func _on_fallback_done(request: int, text: String) -> void:
	if request not in pending_fallbacks:
		return
	var id: int = pending_fallbacks[request]
	pending_fallbacks.erase(request)
	var parsed = JSON.parse_string(text) if text != "" else null
	if not parsed is Dictionary:
		# No judge is reachable at all; let the action through untouched so play can go on.
		push_error("Referee could not judge action %d" % id)
		parsed = {"outcome": "success", "description": "", "judge": "none"}
	var verdict: Dictionary = parsed
	if verdict.get("outcome") not in OUTCOMES:
		verdict["outcome"] = "success"
	verdict["stat_changes"] = verdict.get("stat_changes", {})
	verdict["judge"] = verdict.get("judge", "llm")
	_resolve(id, verdict)


func _resolve(id: int, verdict: Dictionary) -> void:
	var action: Action = Global.Queue.binds.get(id)
	Global.Queue.binds.erase(id)
	if action == null:
		return
	if verdict.outcome == "impossible":
		rejected.emit(id, verdict)
		return
	Global.Players.apply_stat_changes(action.player_name, verdict.get("stat_changes", {}))
	approved.emit(id, verdict)
	Global.AIManager.Gamemaster._continue(action, verdict)
