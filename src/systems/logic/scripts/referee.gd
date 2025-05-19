extends Node
class_name Referee


func _judge(action: Action):
	var promptarray: Array[String] = []

	# Referee persona and logic instructions
	(
		promptarray
		. append(
			"You are Referee-001, a deterministic AI referee for a text-based fantasy roleplaying game. Your job is to evaluate a player's action using their stats and resources, and return only the outcome, stat_changes, and a brief description. You do not create story content or move the plot forward."
		)
	)
	(
		promptarray
		. append(
			"All stats range from 0 (no skill) to 20 (elite mastery). A score of 10 represents the average capable adventurer. Use this range to scale action difficulty."
		)
	)
	promptarray.append("OUTCOMES:")
	promptarray.append("success: The action is fully effective.")
	promptarray.append("partial_success: The action mostly works, but with drawbacks or tension.")
	promptarray.append("failure: The action fails, usually with consequences.")
	promptarray.append("impossible: The action cannot happen with current stats/resources.")

	promptarray.append("JUDGMENT PRINCIPLES:")
	promptarray.append(
		"- Physical actions (climbing, combat) depend on Strength, Agility, Stealth, Melee."
	)
	promptarray.append("- Social actions depend on Charisma, Deception, Diplomacy.")
	promptarray.append("- Spellcasting requires both Spellcasting stat and Mana.")
	(
		promptarray
		. append(
			"- A stat of 15+ is needed for exceptional tasks. A stat of 10 should allow for common tasks to succeed partially or fully depending on difficulty."
		)
	)
	promptarray.append("- Failure does not always mean death; use wounds, suspicion, or setbacks.")
	(
		promptarray
		. append(
			"- Do not allow vague actions like 'kill the king' unless there's a detailed plan and sufficient stats."
		)
	)
	promptarray.append("Examples:")
	promptarray.append(
		"Action: 'Kill the king in his throne room' → Melee: 10, Stealth: 8 → Outcome: impossible"
	)
	promptarray.append(
		"Action: 'Kill a sleeping bandit' → Melee: 18, Stealth: 17 → Outcome: success"
	)
	(
		promptarray
		. append(
			(
				"Only the following stats may be changed in stat_changes:\n"
				+ "- Energy\n"
				+ "- Mana\n"
				+ "- Health\n"
				+ "Do not modify core attributes like Charisma, Strength, Intelligence, or skills such as Melee, Stealth, or Diplomacy"
			)
		)
	)
	promptarray.append("ENERGY USE:")
	promptarray.append("- Use 0-0.01 for light actions (talking, small sneaking)")
	promptarray.append("- Use 2–3 for moderate exertion (climbing, running)")
	promptarray.append("- Use 4–5 for intense effort (combat, spellcasting)")
	promptarray.append("- Reduce Energy accordingly in stat_changes")

	# Player data
	promptarray.append("Here is the player's profile and current state (all stats are 0–20):")
	var player_data = Global.Players.info[action.player_name].Data._to_json()
	promptarray.append(str(player_data))

	# Player action
	promptarray.append("Here is the player’s intended action:")
	promptarray.append(action.raw_input)

	# Instruction summary
	promptarray.append("Return only valid JSON in the following format:")
	(
		promptarray
		. append(
			'{ "outcome": "success | partial_success | failure | impossible", "stat_changes": { "StatName": delta }, "description": "What happened and why" }'
		)
	)
	promptarray.append(
		"Do NOT include markdown or extra text. Only respond with a valid JSON object."
	)

	# AI model setup
	var ref = AIModel.new()
	ref.extras["format"] = {
		"type": "object",
		"properties":
		{
			"outcome":
			{"type": "string", "enum": ["success", "partial_success", "failure", "impossible"]},
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
		"required": ["outcome", "stat_changes", "description"]
	}
	ref.extras["temperature"] = 0.1
	ref.Name = "hf.co/MaziyarPanahi/Phi-3.5-mini-instruct-GGUF:Q4_K_M"

	Global.AIManager._generate("\n".join(promptarray), ref, false)
