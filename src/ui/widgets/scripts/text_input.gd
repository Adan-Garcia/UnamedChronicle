extends HBoxContainer

@export var submitable: bool = true


func _ready():
	if !submitable:
		$Submit.queue_free()
