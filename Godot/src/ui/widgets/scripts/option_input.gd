extends HBoxContainer

@export var options: Array
@export var value: int
var category: String
signal updated(value: int)


func _ready():
	_update_options()
	$selector.connect("item_selected", value_change)


func _update_options():
	$selector.clear()

	for i in options:
		$selector.add_item(i)
	$selector.selected = -1


func value_change(val: int):
	value = val + 1
	emit_signal("updated", val)
