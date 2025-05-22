extends TextEdit
var min_font_size: int = 24
var font_size: int = 32

signal submit


func _ready():
	add_theme_font_size_override("font_size", font_size)
	caret_changed.connect(_scroll)


func _input(event):
	if event is InputEventKey:
		_changed()
		if event.keycode == 4194309 and event.pressed:
			submit.emit()


func _scroll():
	$"..".scroll_vertical = get_caret_draw_pos().y - font_size


func _changed():
	var char_width = font_size * 0.613162

	var text_width = (text.length() + 2) * char_width
	var percent = ceil(text_width) / floor(size.x)
	font_size = clamp(font_size / percent, min_font_size, 32.25)
	if get_theme_font_size("font_size") != font_size:
		add_theme_font_size_override("font_size", font_size)

	$"../../../../../..".custom_minimum_size.y = clamp(40 + size.y, 96, 40 + font_size * 4)
	$"../../../../../..".update_minimum_size()
