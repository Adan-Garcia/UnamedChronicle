extends Control

@onready var label: Label = $MarginContainer/VBoxContainer/Panel3/Label


func _process(_delta):
	var tick = Global.Worldstate.CurrentWorldState.tick
	print(tick)
