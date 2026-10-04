extends Node
class_name worldstatemanager

const SAVE_PATH := "user://world.res"
const AUTOSAVE_TICKS := 30

@export var CurrentWorldState: WorldState

signal Tick(int)
## Emitted for every message that becomes part of the shared world log.
signal message_added(role: String, content: String)

var tick: int

var tickcounter := 0.0


func _ready():
	_intialize()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		save_world()


func _physics_process(delta):
	tickcounter += delta
	if tickcounter >= 1:
		CurrentWorldState.current_time += 1
		tickcounter = 0
		tick = CurrentWorldState.current_time
		Tick.emit(tick)
		if tick % AUTOSAVE_TICKS == 0:
			save_world()


func _intialize():
	gather_saves()


func gather_saves():
	if FileAccess.file_exists(SAVE_PATH):
		CurrentWorldState = load(SAVE_PATH)
	if CurrentWorldState == null:
		_create_world()
	tick = CurrentWorldState.current_time


func save_world() -> void:
	if CurrentWorldState == null:
		return
	var err := ResourceSaver.save(CurrentWorldState, SAVE_PATH)
	if err != OK:
		push_error("Failed to save world (%d)" % err)


## Append a message to the persistent world log, the chronicle and any listening UI.
func add_message(role: String, content: String) -> void:
	CurrentWorldState.chat_queue.append({role: content})
	message_added.emit(role, content)
	if Global.Chronicler:
		Global.Chronicler.record(role, content)


## The last `count` messages as "Name: content" lines, oldest first.
func recent_messages(count: int) -> String:
	var lines := PackedStringArray()
	var history := CurrentWorldState.chat_queue
	for entry in history.slice(max(0, history.size() - count)):
		for role in entry.keys():
			lines.append("%s: %s" % [role, entry[role]])
	return "\n".join(lines)


func _create_world():
	var file = FileAccess.open("res://assets/map/heirarchy.json", FileAccess.READ)
	var text = file.get_as_text()
	var dict = str_to_var(text)
	var World = WorldState.new()

	for empire in dict["Empires"]:
		World.Empires[empire["name"]] = _dict_to_empire(empire, dict["EmpireList"])
	CurrentWorldState = World
	save_world()


func _dict_to_empire(dict: Dictionary, list: Array) -> EmpireData:
	var empire: EmpireData = EmpireData.new()
	empire.name = dict["name"]
	empire.id = dict["id"]
	empire.Cords = Vector2(dict["x"], dict["y"])
	empire.Population = round((dict["urban"] + dict["rural"]) * 1000)
	empire.Area = dict["area"]
	empire.diplomacy = {}
	empire.neighbors = []
	empire.Sectors = {}
	for state in dict["diplomacy"].size():
		empire.diplomacy[list[state]] = EmpireData.Diplomacyenum[dict["diplomacy"][state]]
	for state in dict["neighbors"]:
		empire.neighbors.append(list[state])
	for sector in dict["sectors"]:
		empire.Sectors[sector["name"]] = _dict_to_sector(sector)
	return empire


func _dict_to_sector(dict: Dictionary) -> SectorData:
	var sector: SectorData = SectorData.new()

	sector.id = dict["id"]
	sector.name = dict["name"]
	sector.Cords = Vector2(dict["x"], dict["y"])
	sector.towns = {}

	for town in dict["towns"]:
		var towndata: TownData = _dict_to_town(town)
		sector.towns[towndata.name] = towndata

	return sector


func _dict_to_town(dict: Dictionary) -> TownData:
	var town: TownData = TownData.new()

	town.id = dict["id"]
	town.name = dict["name"]
	town.Cords = Vector2(dict["x"], dict["y"])
	town.IsCapital = dict["capital"]
	town.CultureIndex = dict["culture"]
	town.Population = dict["population"] * 1000

	return town
