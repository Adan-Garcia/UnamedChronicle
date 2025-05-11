extends HBoxContainer

@export var slider_range: int
@export var value: int
@onready var manager: TabContainer = $"../../../../../"
var category: String
signal updated(value: int)


func _ready():
	$Slider.max_value = slider_range
	value = 0
	$Slider.value = 0
	$Value.text = str(int(value))
	if slider_range <= 5:
		$Slider.tick_count = slider_range + 1
	$Slider.connect("value_changed", value_change)


func _update_value():
	$Slider.value = value


func value_change(val: float):
	if manager._cap_scores(name, val):
		value = int(val)
		emit_signal("updated", category)
	else:
		$Slider.value = value
	$Value.text = str(int(value))
