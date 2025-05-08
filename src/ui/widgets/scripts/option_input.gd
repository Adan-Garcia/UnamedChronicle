extends HBoxContainer

@export var options: Array
@export var value: int

signal updated(value: int)


func _ready():
	_update_options()
	$selector.connect("item_selected", value_change)


func _update_options():
	$selector.clear()
	for i in options:
		$selector.add_item(i)


func value_change(val: int):
	emit_signal("updated", val)
	value = val
