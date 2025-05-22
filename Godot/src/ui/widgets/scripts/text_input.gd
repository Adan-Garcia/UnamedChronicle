extends HBoxContainer

@export var submitable: bool = true
var category: String
var value: String
signal updated(value: String)


func _ready():
	if !submitable:
		$Submit.queue_free()


func _on_textbox_text_changed(new_text):
	value = new_text
	emit_signal("updated", category)
