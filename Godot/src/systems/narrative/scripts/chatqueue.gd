extends Node
class_name action_queue

var ActionQueue: Dictionary[int,Action]

var binds: Dictionary[int,Action]


func _ready():
	await get_tree().process_frame


func input(raw: String) -> int:
	var currentlocation: Address = Global.Players.info[Global.PlayerName].Location

	var timestamp = Time.get_ticks_msec()

	var action = Action.new()
	action.player_id = Global.PlayerID
	action.player_name = Global.PlayerName
	action.location = currentlocation
	action.raw_input = raw
	action.tick = Global.Worldstate.tick
	action.timestamp = timestamp
	var id = Time.get_ticks_msec()
	ActionQueue[id] = action

	return id


func send_queue(_tick: int):
	var queue: Dictionary[int,Action] = ActionQueue.duplicate()
	for i: int in queue.keys():
		Global.AIManager.referee._judge(queue[i], i)
		binds[i] = queue[i]
		ActionQueue.erase(i)
