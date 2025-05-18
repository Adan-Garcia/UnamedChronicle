extends Node
class_name action_queue

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


func send_queue(_tick: int):
	var queue: Array[Action] = ActionQueue.duplicate()
	for i: Action in queue:
		Global.AIManager.referee._judge(i)

		ActionQueue.erase(i)
