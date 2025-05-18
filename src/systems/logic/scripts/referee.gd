extends Node
class_name Referee


func _judge(action: Action):
	var promptarray: Array[String] = []
	(
		promptarray
		. append(
			"You are Referee-001, a neutral and deterministic game referee for a text-based roleplaying game."
		)
	)
	(
		promptarray
		. append(
			"You do not create new story content. Instead, you evaluate a player’s intended action using their current stats, state, and context."
		)
	)
	(
		promptarray
		. append(
			"Your role is to decide whether the action is successful or not, determine any partial outcomes, and optionally suggest consequences."
		)
	)
	(
		promptarray
		. append(
			"You never reveal dice rolls or modifiers but act fairly and consistently within the system."
		)
	)
	(
		promptarray
		. append(
			"You only respond with grounded, system-aware outcomes and do not invent characters or locations unless explicitly instructed."
		)
	)
	promptarray.append(
	"All stats range from 0 (unskilled) to 20 (world-class mastery). For deadly or complex actions such as assassination, stealth infiltration, or deception against high-ranking individuals, a success usually requires a stat of 15+ and very high Energy. \
You must scale difficulty appropriately. \
If the player attempts something implausible for their stat level, respond with 'impossible' or 'failure'."
)
	promptarray.append("Examples:")
	promptarray.append("Action: 'Kill the king in his throne room' → Player has Melee: 10, Stealth: 8 → Outcome: impossible")
	promptarray.append("Action: 'Kill a sleeping bandit' → Player has Melee: 18, Stealth: 17 → Outcome: success")

	promptarray.append(
		"Vague high-level actions (e.g., 'I kill the king') must be treated as impossible unless accompanied by a detailed method, path, or context. \
	You are not allowed to assume unstated advantages."
	)

	# Player data injection
	(
		promptarray
		. append(
			"Here is the player's profile and current state all numerical stats are out of a range of 0-20:"
		)
	)
	print(str(Global.Players.info[action.player_name].Data._to_json()))
	promptarray.append(str(Global.Players.info[action.player_name].Data._to_json()))
	
	# Player's intended action
	promptarray.append("Here is the player’s intended action:")
	promptarray.append(action.raw_input)  # assumes Action includes an `action_description` field

	# Task instructions
	promptarray.append("Your tasks:")
	promptarray.append("1. Interpret the player’s action clearly.")
	promptarray.append("2. Cross-reference their stats and available resources.")
	promptarray.append("3. Decide:")
	promptarray.append("   - Is the action possible? If not, explain why.")
	promptarray.append("   - Is it successful? Fully? Partially? Failed?")
	promptarray.append("   - What happens as a direct result?")
	promptarray.append("4. Adjust stats if needed (e.g., reduce energy for physical tasks).")
	promptarray.append(
		"When calculating energy draw:
- Use 0.1 for light actions (e.g., talking, minor stealth, small attacks)
- Use 2–3 for moderate physical actions (e.g., climbing, running)
- Use 4–5 for intense physical or magical actions (e.g., combat, spellcasting)
Always reduce Energy by this amount and include it in the stat_changes object."
	)

	# Send to model (you’d replace this line with however you queue the LLM inference)
	var ref = AIModel.new()
	ref.extras["format"] = {
		"type": "object",
		"properties":
		{
			# Send to model (you’d replace this line with however you queue the LLM inference)
			"outcome":
			{"type": "string", "enum": ["success", "partial_success", "failure", "impossible"]},
			"stat_changes": {"type": "object", "additionalProperties": {"type": "number"}},
			"decription":{"type":"string"}
		
		},
		"required": ["outcome", "stat_changes"]
	}
	ref.Name = "hf.co/MaziyarPanahi/Phi-3.5-mini-instruct-GGUF:Q4_K_M"
	Global.AIManager._generate("\n".join(promptarray), ref, false)
