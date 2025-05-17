extends Node

var ActionQueue: Array[Action]


func input(raw: String):
	var currentlocation: Address = Global.Players.info[Global.PlayerName].Location

	var timestamp = Time.get_ticks_msec()

	var action = Action.new()
	action.player_id = Global.PlayerID
	action.player_name = Global.PlayerName
	action.location = currentlocation
	action.raw_input = raw
	action.tick = Global.Worldstate.tick
	action.timestamp = timestamp
	ActionQueue.append(action)


func send_queue():
	var queue = ActionQueue.duplicate()
	for i in queue:
		ActionQueue.erase(i)
	pass
