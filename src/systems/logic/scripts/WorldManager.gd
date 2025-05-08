extends Node

@export var CurrentWorldState: WorldState


func _ready():
	_intialize()


func _intialize():
	gather_saves()


func gather_saves():
	if !FileAccess.file_exists("res://src/resources/world.res"):
		_create_world()

	else:
		CurrentWorldState = load("res://src/resources/world.res")


func _create_world():
	var file = FileAccess.open("res://assets/map/heirarchy.json", FileAccess.READ)
	var text = file.get_as_text()
	var dict = str_to_var(text)
	var World = WorldState.new()

	for empire in dict["Empires"]:
		World.Empires[empire["name"]] = _dict_to_empire(empire, dict["EmpireList"])
	CurrentWorldState = World
	ResourceSaver.save(CurrentWorldState, "res://src/resources/world.res")


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
