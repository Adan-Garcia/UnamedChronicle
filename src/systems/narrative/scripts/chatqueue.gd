extends Node
class_name action_queue

## Actions typed by players wait here until the next world tick,
## then are handed to the Referee. `binds` holds actions under judgement.

var ActionQueue: Dictionary[int, Action]

var binds: Dictionary[int, Action]


func input(raw: String) -> int:
	var player: Player = Global.Players.info.get(Global.PlayerName)

	var action = Action.new()
	action.player_id = Global.PlayerID
	action.player_name = Global.PlayerName
	action.location = player.Location if player else null
	action.raw_input = raw
	action.tick = Global.Worldstate.tick
	action.timestamp = Time.get_ticks_msec()
	var id: int = Global.AIManager.next_id()
	ActionQueue[id] = action

	return id


func send_queue(_tick: int):
	var queue: Dictionary[int, Action] = ActionQueue.duplicate()
	for i: int in queue.keys():
		binds[i] = queue[i]
		ActionQueue.erase(i)
		Global.AIManager.referee._judge(queue[i], i)
