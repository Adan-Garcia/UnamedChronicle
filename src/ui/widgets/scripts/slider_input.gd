extends HBoxContainer

@export var slider_range: int
@export var value: int
@onready var manager: TabContainer = $"../../../../../"


func _ready():
	$Slider.max_value = slider_range
	value = round(slider_range / 2.0)
	$Slider.value = round(slider_range / 2.0)
	$Value.text = str(int(value))
	if slider_range <= 5:
		$Slider.tick_count = slider_range + 1
	$Slider.connect("value_changed", value_change)


func _update_value():
	$Slider.value = value


func value_change(val: float):
	if val > value:
		print(manager.total_score)
	value = int(val)
	$Value.text = str(int(val))
