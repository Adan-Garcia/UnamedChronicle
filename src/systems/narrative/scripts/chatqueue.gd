extends Node

var ActionQueue: Array[Dictionary]

var tick: int

var ticklength: float = 2.5
var counter: float


func _physics_process(delta):
	counter += delta
	if counter >= ticklength:
		tick += 1
		send_queue()


func input(raw: String, character: String):
	var currentlocation: Address = Global.players.info[character].location
	var timestamp = Time.get_ticks_msec()

	var action = Action.new()
	action.player_id = character
	action.location = currentlocation
	action.raw_input = raw
	action.tick = tick
	action.timestamp = timestamp
	ActionQueue.append(action)


func send_queue():
	var queue = ActionQueue.duplicate()
	for i in queue:
		ActionQueue.erase(i)
	pass
