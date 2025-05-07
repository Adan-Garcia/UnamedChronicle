extends HBoxContainer

@export var slider_range: int
@export var value: int


func _ready():
	$Slider.max_value = slider_range
	$slider.tick_count = slider_range + 1
	$slider.connect("value_changed", value_change)


func value_change(val: float):
	value = int(val)
