extends Camera2D

var magnitude := 0.0


func _impulse(Mag: float):
	magnitude += Mag


func _physics_process(delta):
	magnitude = move_toward(magnitude, 0, delta)

	offset = Vector2.from_angle(randf_range(0, 2 * PI)) * magnitude
	randomize()
