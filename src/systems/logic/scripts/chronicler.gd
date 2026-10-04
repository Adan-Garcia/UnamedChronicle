extends Node
class_name chronicler

## Watches every event in the world and keeps two records:
##  - ChatLog:  every raw event, persisted to user://chatlog.json
##  - Chapters: prose written by an AI historian every few events,
##              persisted to user://chronicle.json and user://chronicle.md

signal chapter_written(chapter: Dictionary)

const chatlogpath = "user://chatlog.json"
const chroniclepath = "user://chronicle.json"
const chronicle_md_path = "user://chronicle.md"
const PERSONA_PATH := "res://assets/data/personas/core/Chronicler.txt"

@export var ChatLog: Array[Dictionary]
@export var Chapters: Array[Dictionary]

## Index into ChatLog of the first event not yet written into a chapter.
var chronicled_until := 0
var writing_id := -1
var writing_until := 0


func _ready():
	ChatLog.assign(_load_array(chatlogpath))
	Chapters.assign(_load_array(chroniclepath))
	if !Chapters.is_empty():
		chronicled_until = int(Chapters[-1].get("until", 0))
	await get_tree().process_frame
	Global.AIManager.stream_done.connect(_on_stream_done)


func _load_array(path: String) -> Array:
	if !FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []


func _save_array(path: String, data: Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))


func record(role: String, content: String, kind: String = "message") -> void:
	(
		ChatLog
		. append(
			{
				"tick": Global.Worldstate.tick,
				"time": "%s %s/%s/%04d %d:%s %s" % Global._get_time(),
				"role": role,
				"content": content,
				"type": kind,
			}
		)
	)
	_save_array(chatlogpath, ChatLog)
	if ChatLog.size() - chronicled_until >= _events_per_chapter():
		write_chapter()


func _events_per_chapter() -> int:
	return int(Global.AIManager.config.get("chronicler", {}).get("events_per_chapter", 8))


## Ask the AI historian to turn all unchronicled events into a chapter.
func write_chapter() -> void:
	if writing_id != -1 or chronicled_until >= ChatLog.size():
		return
	if !FileAccess.file_exists(PERSONA_PATH):
		push_error("failed to load chronicler persona")
		return
	var events := PackedStringArray()
	for entry in ChatLog.slice(chronicled_until):
		events.append("[%s] %s: %s" % [entry.get("time", ""), entry["role"], entry["content"]])
	var previous: String = Chapters[-1]["text"] if !Chapters.is_empty() else "(nothing yet)"
	var prompt := FileAccess.get_file_as_string(PERSONA_PATH) % [
		previous.right(1500),
		"%s %s/%s/%04d %d:%s %s" % Global._get_time(),
		"\n".join(events),
	]
	writing_id = Global.AIManager.next_id()
	writing_until = ChatLog.size()
	Global.AIManager._generate(prompt, Global.AIManager.make_text_model("chronicler"), writing_id)


func _on_stream_done(request_id: int, text: String) -> void:
	if request_id != writing_id:
		return
	writing_id = -1
	text = text.strip_edges()
	if text == "":
		push_warning("Chronicler failed to write a chapter; will retry with the next event")
		return
	var title := text.get_slice("\n", 0).strip_edges().trim_prefix("#").strip_edges()
	var body := text.substr(text.find("\n") + 1).strip_edges() if text.contains("\n") else text
	var chapter := {
		"number": Chapters.size() + 1,
		"title": title,
		"text": body,
		"from": chronicled_until,
		"until": writing_until,
		"time": "%s %s/%s/%04d %d:%s %s" % Global._get_time(),
	}
	Chapters.append(chapter)
	chronicled_until = writing_until
	_save_array(chroniclepath, Chapters)
	_save_markdown()
	chapter_written.emit(chapter)


func _save_markdown() -> void:
	var file := FileAccess.open(chronicle_md_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("# The Chronicle\n")
	for chapter in Chapters:
		file.store_line("## Chapter %d: %s\n" % [chapter["number"], chapter["title"]])
		file.store_line("*%s*\n" % chapter.get("time", ""))
		file.store_line(chapter["text"] + "\n")
