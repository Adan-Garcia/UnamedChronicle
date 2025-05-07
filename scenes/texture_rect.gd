extends TextureRect

@export var pos: Vector2 = Vector2(512, 248):
	set(value):
		pos = value
		queue_redraw()


func _draw():
	draw_circle(Global.Cord._get_town("Nuvuspo") / Vector2(1920, 1080) * size, 2, Color.RED, true)
