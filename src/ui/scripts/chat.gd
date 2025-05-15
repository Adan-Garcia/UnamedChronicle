extends Control

@onready var label: Label = $MarginContainer/VBoxContainer/Panel3/Label

# Unix timestamp of your “base date” Y.
# e.g. if Y is 2025-01-01 00:00 UTC then:
const ORIGIN_UNIX := 1704067200


func _physics_process(_delta):
	# 1) get your raw tick
	var tick_seconds = Global.Worldstate.CurrentWorldState.current_time

	# 2) turn it into an actual Unix timestamp
	var ts = ORIGIN_UNIX + tick_seconds

	# 3) build a DateTime in local time
	var dt = Time.get_datetime_string_from_unix_time(ts, true)

	#
	label.text = dt.format("%A %m/%d/%Y %I:%M %p")
