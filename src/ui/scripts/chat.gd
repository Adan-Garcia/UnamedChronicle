extends Control

@onready var label: Label = $MarginContainer/VBoxContainer/Panel3/Label


#a tick is x seconds from the date y i want to set the labels text int the format day of week mm/dd/yyy h:mm am/pm
func _physics_process(_delta):
	var tick: int = Global.Worldstate.CurrentWorldState.current_time

	print(tick)
