# ChatController.gd – Updated for improved Generator API
extends Control

@onready var generator: Generator = Generator.new()
@onready var message_scene: PackedScene = preload("res://scenes/message.tscn")
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var vbox: VBoxContainer = scroll_container.get_node("VBoxContainer")
@onready var input_line: LineEdit = $Panel/MarginContainer/HBoxContainer/LineEdit

var start_time := 0.0
var pre_message: message
var current_message: message
var generating := false

# Persona definitions
var personas := {}
var examples := {}
var memories := {}


func _ready() -> void:
	gather_saves()

	setup_generator()
	#start_conversation()


func gather_saves():
	var path = "res://Ai/personas/"
	for file_name in DirAccess.get_files_at(path):
		var file = FileAccess.open(path + file_name, FileAccess.READ)

		var text = file.get_as_text()

		personas[file_name.split(".")[0]] = text

		file.close()
	path = "res://Ai/examples/"
	for file_name in DirAccess.get_files_at(path):
		var file = FileAccess.open(path + file_name, FileAccess.READ)

		var text = file.get_as_text()

		examples[file_name.split(".")[0]] = text

		file.close()
	path = "res://Ai/memories/"
	for file_name in DirAccess.get_files_at(path):
		var file = FileAccess.open(path + file_name, FileAccess.READ)

		var text = file.get_as_text()

		memories[file_name.split(".")[0]] = text

		file.close()


func setup_generator() -> void:
	# Attach and configure Generator node
	add_child(generator)
	generator.model = "llama3.1"
	generator.character = "Artem"
	generator.story_context = "The land of Ideola teems with ancient magic and warring empires. Every forest murmurs of hidden dangers, every mountain’s shadow conceals unseen foes. You are part of this living world—its sights, sounds, and storms pulse through your veins."
	generator.persona = personas[generator.character]
	generator.examples = examples[generator.character]
	# Memories of characters
	generator.memories = memories[generator.character]

	# Output schema hints (optional)

	# Connect generator signals
	generator.connect("streamed", _on_streamed)
	generator.connect("generated", _on_generated)
	generator.connect("error", _on_error)


func start_conversation() -> void:
	# Initialize UI and start streaming from AI
	start_time = Time.get_unix_time_from_system()
	current_message = message_scene.instantiate()
	vbox.add_child(current_message)
	generator.new_messages = [{"name": "Alcides", "content": "«How did you sleep?»"}]
	generator.generate(true)
	generating = true


func _on_streamed(chunk: String) -> void:
	var dialogue = chunk

	current_message.Name = generator.character

	current_message.Message = post_process_message(dialogue)
	current_message._update_message()


func _on_generated(data) -> void:
	# Append completed response and prepare next message

	generator.new_messages.append(
		{"name": generator.character, "content": post_process_message(data)}
	)
	print(post_process_message(data))
	print(post_process_message(data))
	pre_message = current_message
	current_message = message_scene.instantiate()
	generating = false
	current_message._update_message()


func _on_error(err: String) -> void:
	push_error("Generator error: %s" % err)


func _on_user_entered_message() -> void:
	# Handle user input, append to conversation, and trigger AI
	if generating:
		return
	vbox.add_child(current_message)
	var user_input = post_process_message(input_line.text.strip_edges())

	if user_input == "":
		return

	current_message.Message = user_input
	current_message._update_message()

	input_line.text = ""
	pre_message = current_message
	current_message = message_scene.instantiate()
	vbox.add_child(current_message)
	start_time = Time.get_unix_time_from_system()
	generator.generate(true)
	generating = true


func post_process_message(text: String) -> String:
	# 1. Remove rogue curly braces
	text = text.replace("{", "").replace("}", "")

	# 2. Remove unnecessary header lines if present
	var first_line_end = text.find("\n")
	if first_line_end == -1:
		first_line_end = text.length()
	var first_line = text.substr(0, first_line_end).strip_edges()

	if (
		first_line.begins_with(generator.character)
		or first_line.begins_with("I am %s" % generator.character)
		or first_line.to_lower().find(generator.character) != -1
	):
		text = text.substr(first_line_end + 1)

	# 3. Remove unexpected non-ASCII characters
	var ascii_text = ""
	for i in text.length():
		var ascii_char = text[i]
		var codepoint = ascii_char.unicode_at(0)
		if (
			(codepoint >= 32 and codepoint <= 126)
			or (codepoint == 171)
			or (codepoint == 187)
			or (codepoint == 60)
			or (codepoint == 62)
			or (codepoint == 10)
			or (codepoint == 13)
		):
			ascii_text += ascii_char
	text = ascii_text

	# 4. Fix misplaced guillemets and extra punctuation
	text = text.replace("« ", "«")
	text = text.replace(" »", "»")
	text = text.replace("««", "«")
	text = text.replace("»»", "»")
	text = text.replace('\"', '"')
	text = fix_double_commas_in_speech(text)
	# 5. Fix broken thoughts and speech
	text = fix_bracket_pairs(text)

	# 6. Fix broken actions
	text = fix_asterisks(text)

	# 7. Trim spaces
	text = text.strip_edges(true, true)
	text = text.replace("  ", " ")

	# 8. Ensure clean ending
	if not text.ends_with(".") and not text.ends_with("»") and not text.ends_with("*"):
		text += "."
	text = fix_double_quotes_as_speech(text)
	text = fix_single_quotes_as_speech(text)
	return text


func fix_bracket_pairs(text: String) -> String:
	# Fix for <<thoughts>> and «speech»
	text = fix_stray_closing(text, "<<", ">>")
	text = fix_stray_closing(text, "«", "»")

	text = fix_unmatched_opening(text, "<<", ">>")
	text = fix_unmatched_opening(text, "«", "»")

	return text


func fix_asterisks(text: String) -> String:
	var regex = RegEx.new()
	# Only remove stray * not in a pair
	regex.compile(r"(?<!\*)\*(?![^*]+\*)")
	return regex.sub(text, "", true)


func fix_stray_closing(text: String, open: String, close: String) -> String:
	var regex_stray_close = RegEx.new()
	var escaped_open = escape_regex(open.substr(open.length() - 1))
	var escaped_close = escape_regex(close)
	regex_stray_close.compile(r"(?<!%s)%s" % [escaped_open, escaped_close])
	return regex_stray_close.sub(text, "", true)


func fix_unmatched_opening(text: String, open: String, close: String) -> String:
	var regex_open = RegEx.new()
	var escaped_open = escape_regex(open)
	var _escaped_close = escape_regex(close)
	regex_open.compile(
		(
			"(%s)([^%s%s]*)"
			% [
				escaped_open,
				escape_regex(open.substr(0, 1)),
				escape_regex(close.substr(close.length() - 1))
			]
		)
	)

	var matches = regex_open.search_all(text)

	var offset = 0
	for match in matches:
		var open_symbol = match.get_string(1)
		var content = match.get_string(2)
		var start = match.get_start()
		var end = match.get_end()

		start += offset
		end += offset

		var has_period = content.find(".") != -1

		if not has_period:
			# No period: remove opening
			text = text.substr(0, start) + content + text.substr(end)
			offset -= open_symbol.length()
		else:
			# Period exists: check if closing exists after
			var expected_close = close
			var after_content = text.substr(end, text.length() - end)
			if after_content.find(expected_close) == -1:
				# No closing exists: insert close after period
				var period_index = text.find(".", start)
				if period_index != -1:
					text = text.insert(period_index + 1, expected_close)
					offset += expected_close.length()
	return text


func escape_regex(text: String) -> String:
	var special_chars = [
		"\\", ".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|", "<", ">"
	]
	for _char in special_chars:
		text = text.replace(_char, "\\" + _char)
	return text


func fix_single_quotes_as_speech(text: String) -> String:
	var regex = RegEx.new()
	regex.compile(r"'([^'\n]{1,100}?)'")

	var matches = regex.search_all(text)
	var offset = 0

	for match in matches:
		var start = match.get_start() + offset
		var end = match.get_end() + offset
		var content = match.get_string(1)

		text = text.substr(0, start) + "«" + content + "»" + text.substr(end)
		offset += (2 + 2) - (end - start)  # Adjust for length difference

	return text


func fix_double_quotes_as_speech(text: String) -> String:
	var regex = RegEx.new()
	regex.compile(r'"([^"\n]{1,100}?)"')

	var matches = regex.search_all(text)
	var offset = 0

	for match in matches:
		var start = match.get_start() + offset
		var end = match.get_end() + offset
		var content = match.get_string(1)

		text = text.substr(0, start) + "«" + content + "»" + text.substr(end)
		offset += (2 + 2) - (end - start)

	return text


func fix_double_commas_in_speech(text: String) -> String:
	var regex = RegEx.new()
	regex.compile(r"«([^»]+)»")  # Match everything between guillemets

	var matches = regex.search_all(text)
	var offset = 0

	for match in matches:
		var full_start = match.get_start() + offset
		var full_end = match.get_end() + offset
		var content = match.get_string(1)

		var commas = []
		for i in content.length():
			if content.substr(i, 1) == ",":
				commas.append(i)

		if commas.size() >= 2:
			var second_comma_index = commas[1]

			# Split at second comma (keep spaces correct!)
			var speech = content.substr(0, second_comma_index).strip_edges()
			var narration = content.substr(second_comma_index + 1).strip_edges()

			var fixed = "«%s.» %s" % [speech, narration]

			text = text.substr(0, full_start) + fixed + text.substr(full_end)
			# Correct the offset calculation
			offset += fixed.length() - (full_end - full_start)

	return text


func _on_line_edit_gui_input(event):
	if event is InputEventKey and event.keycode == 4194309 and event.pressed:
		_on_user_entered_message()
