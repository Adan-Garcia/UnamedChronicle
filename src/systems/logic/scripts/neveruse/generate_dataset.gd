@tool
extends EditorScript

var personas := {}
var examples := {}
var memories := {}
var start_dialogues := []


func gather_saves():
	var path = "res://personas/"
	for file_name in DirAccess.get_files_at(path):
		var file = FileAccess.open(path + file_name, FileAccess.READ)

		var text = file.get_as_text()

		personas[file_name.split(".")[0]] = text

		file.close()
	path = "res://examples/"
	for file_name in DirAccess.get_files_at(path):
		var file = FileAccess.open(path + file_name, FileAccess.READ)

		var text = file.get_as_text()

		examples[file_name.split(".")[0]] = text

		file.close()
	path = "res://memories/"
	for file_name in DirAccess.get_files_at(path):
		var file = FileAccess.open(path + file_name, FileAccess.READ)

		var text = file.get_as_text()

		memories[file_name.split(".")[0]] = text

		file.close()
	path = "res://data/dialogue/"
	for file_name in DirAccess.get_files_at(path):
		var file = FileAccess.open(path + file_name, FileAccess.READ)

		var text = file.get_as_text()
		var split = text.split("\n", false)
		start_dialogues.append_array(split)

		file.close()


func build_dataset():
	gather_saves()

	var world_context = "The land of Ideola teems with ancient magic and warring empires. Every forest murmurs of hidden dangers, every mountain’s shadow conceals unseen foes."
	var core_rules = FileAccess.open("res://core/rules.txt", FileAccess.READ).get_as_text()

	var characters = personas.keys()
	var dataset = []

	for i in range(start_dialogues.size() * characters.size()):  # Number of samples
		var character = characters[randi() % characters.size()]
		var persona = personas[character]
		var example = examples[character]
		var memory = memories[character]
		var dialogue_context = start_dialogues[randi_range(0, start_dialogues.size() - 1)]

		# Recreate prompt
		var lines = []
		lines.append("[World Context]")
		lines.append(world_context)
		lines.append("")
		lines.append("[Persona - %s]" % character)
		lines.append(persona)
		lines.append("")
		lines.append("[Rules]")
		lines.append(core_rules)
		lines.append("")
		lines.append("[%s Memory]: %s" % [character, memory])
		lines.append("")
		lines.append("[Instructions]:")
		lines.append("-Stay strictly in first-person cinematic narration as %s." % character)
		lines.append(
			"-Embed vivid physical actions, sensory details, and one inner thought per reply."
		)
		lines.append("-Dialogue must be inside guillemets « ».")
		lines.append("-Inner thoughts must be inside double angle brackets << >>.")
		lines.append("-No *asterisks* for actions inside speech.")
		lines.append("-Actions must be narrated naturally outside of speech quotes.")
		lines.append("-No {metadata} allowed anywhere.")
		lines.append("-Each reply must stop naturally after one cinematic moment (~100–150 words).")
		lines.append(
			"-You MUST begin with cinematic action + sensory detail, NOT inner monologue alone."
		)
		lines.append(
			"-Every scene must open with vivid physical sensory action before dialogue or thoughts."
		)
		lines.append("-Never use parentheses ( ) for actions. Actions must be natural narrative.")
		lines.append("-Stop after one vivid moment and natural choice — no long inner debates.")
		(
			lines
			. append(
				"Failure to format internal thoughts correctly will be treated as a critical formatting error."
			)
		)
		lines.append("Begin your response below:")
		lines.append("[examples - %s]" % character)
		lines.append(example)
		lines.append("")
		lines.append("[Starting Dialogue]:")
		lines.append(dialogue_context)
		lines.append("[%s]:" % character)

		var prompt = "\n".join(lines)

		# Add to dataset
		dataset.append({"text": prompt})  # leave empty for supervised fine-tuning

	# Save dataset
	var file = FileAccess.open("res://data/dataset.jsonl", FileAccess.WRITE)
	for sample in dataset:
		file.store_line(JSON.stringify(sample))
	file.close()


func _run():
	build_dataset()
