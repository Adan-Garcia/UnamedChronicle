extends Control

class_name user_chat_manager

const HISTORY_ON_LOAD := 50
const HELP := "Type what your character does or says. Commands: /stats, /chronicle, /help"

@onready var MessageScene = preload("res://src/systems/narrative/message.tscn")
@onready var label: Label = $MarginContainer/VBoxContainer/Panel3/Label
@onready var User_Input: TextEdit = $%TextBox
@onready var Submit_Button: Button = $%Submit
@onready var MessageContainer: VBoxContainer = $%MessageContainer

## action id -> the text the player typed, while the Referee judges it
var pend: Dictionary[int, String]

var thinking: bool


func _ready():
	Submit_Button.connect("pressed", _submit)
	User_Input.connect("submit", _submit)
	await get_tree().process_frame
	Global.clientside = self
	Global.AIManager.referee.approved.connect(_approved)
	Global.AIManager.referee.rejected.connect(_rejected)
	Global.AIManager.Gamemaster.narrated.connect(_on_narrated)
	Global.Worldstate.message_added.connect(_show_message)
	Global.Chronicler.chapter_written.connect(_on_chapter_written)
	_restore_history()


func _restore_history():
	var history: Array[Dictionary] = Global.Worldstate.CurrentWorldState.chat_queue
	for entry in history.slice(max(0, history.size() - HISTORY_ON_LOAD)):
		for role in entry.keys():
			_show_message(role, entry[role])
	if history.is_empty():
		_show_message("system", HELP)


func _approved(id: int, verdict: Dictionary):
	if id not in pend:
		return
	Global.Worldstate.add_message(Global.PlayerName, pend[id])
	pend.erase(id)
	_show_message("Referee", _describe_verdict(verdict))


func _rejected(id: int, verdict: Dictionary):
	if id not in pend:
		return
	pend.erase(id)
	$AnimationPlayer.play("rejected")
	var reason: String = verdict.get("description", "")
	_show_message("Referee", "*That cannot happen.* %s" % reason)
	_finish_thinking()


func _on_narrated(_messages: Array):
	if pend.is_empty():
		_finish_thinking()


func _on_chapter_written(chapter: Dictionary):
	_show_message("Chronicler", "*A new chapter is written: %s*" % chapter["title"])


func _describe_verdict(verdict: Dictionary) -> String:
	var text := "*%s*" % str(verdict.get("outcome", "success")).replace("_", " ").capitalize()
	var confidence := float(verdict.get("confidence", 0.0))
	if confidence > 0.0:
		text += " (%d%% sure)" % roundi(confidence * 100)
	var changes: Dictionary = verdict.get("stat_changes", {})
	var parts := PackedStringArray()
	for stat in changes.keys():
		parts.append("%s %+.1f" % [stat, float(changes[stat])])
	if !parts.is_empty():
		text += " - " + ", ".join(parts)
	return text


func _submit():
	var text := User_Input.text.strip_edges()
	if thinking or text == "":
		return
	User_Input.text = ""
	if text.begins_with("/"):
		_run_command(text.to_lower())
		return
	pend[Global.Queue.input(text)] = text
	thinking = true
	%TextBox.editable = false
	$%Submit.disabled = true


func _run_command(command: String):
	match command:
		"/stats":
			var player: Player = Global.Players.info.get(Global.PlayerName)
			if player == null:
				_show_message("system", "No character loaded.")
				return
			var d := player.Data
			var where := (
				"%s, %s" % [player.Location.Town, player.Location.Empire]
				if player.Location
				else "unknown"
			)
			_show_message(
				"system",
				(
					"%s in %s - Health %.1f, Energy %.1f, Mana %d | STR %d AGI %d END %d INT %d CHA %d"
					% [
						player.Name,
						where,
						d.Health,
						d.Energy,
						d.Mana,
						d.Strength,
						d.Agility,
						d.Endurance,
						d.Intelligence,
						d.Charisma
					]
				)
			)
		"/chronicle":
			var chapters: Array[Dictionary] = Global.Chronicler.Chapters
			if chapters.is_empty():
				_show_message("Chronicler", "*The chronicle is still blank. I will begin writing.*")
				Global.Chronicler.write_chapter()
				return
			for chapter in chapters.slice(max(0, chapters.size() - 3)):
				_show_message(
					"Chronicler", "*Chapter %d: %s* %s" % [chapter["number"], chapter["title"], chapter["text"]]
				)
		_:
			_show_message("system", HELP)


## Display a message without recording it in the world log.
func _show_message(role: String, content: String):
	var Message: message = MessageScene.instantiate()
	Message.Name = role
	Message.time = Global._get_time()
	Message.Message = content
	MessageContainer.add_child(Message)


func _finish_thinking():
	thinking = false
	User_Input.text = ""
	%TextBox.editable = true
	$%Submit.disabled = false


func _physics_process(_delta):
	label.text = "%s %s/%s/%04d %d:%s %s" % Global._get_time()
