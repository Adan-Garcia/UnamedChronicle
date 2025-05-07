extends HBoxContainer

@export var range: int
@export var val: int


func _ready():
	$Slider.max_value = range
	$slider.tick_count = range + 1
	$slider.connect("value_changed", value_change)


func value_change(val: float):
	val = int(val)
