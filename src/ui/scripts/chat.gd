extends Control

@onready var label: Label = $MarginContainer/VBoxContainer/Panel3/Label


func _physics_process(_delta):
	# 1) get your raw tick
	label.text = "%s %s/%s/%04d %d:%s %s" % Global._get_time()
