extends Node2D

@onready var Worldstate := $WorldState
@onready var Cord := $Cord
@onready var Data := $Datagraber
@onready var Queue := $chatqueue
@onready var Players := $players
@export var towns: Dictionary[String,TownData]
@export var sectors: Dictionary[String,SectorData]
@export var empires: Dictionary[String,EmpireData]
@export var PlayerID: String
@export var PlayerName: String

# Unix timestamp of your “base date” Y.
# e.g. if Y is 2025-01-01 00:00 UTC then:
const ORIGIN_UNIX := 1704067200

# our US-style weekday lookup
const WEEKDAYS := {0: "Sun", 1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat"}


func _ready():
	await get_tree().process_frame

	await get_tree().process_frame
	for e: EmpireData in Worldstate.CurrentWorldState.Empires.values():
		empires[e.name] = e
		for s: SectorData in e.Sectors.values():
			sectors[s.name] = s
			for t in s.towns.values():
				towns[t.name] = t


func _get_time():
	var tick_seconds = Worldstate.CurrentWorldState.current_time

	# 2) turn it into an actual Unix timestamp
	var ts = ORIGIN_UNIX + tick_seconds * 10

	# 3) extract a Dictionary of date components in local time
	var d = Time.get_datetime_dict_from_unix_time(ts)
	# d keys: year, month, day, hour, minute, second, weekday (0 = Sunday)

	# 4) compute 12-hour clock and AM/PM
	var hour12 = d.hour % 12
	if hour12 == 0:
		hour12 = 12
	var ampm = "PM" if d.hour >= 12 else "AM"

	# 5) build the formatted string
	var mm = String("%02d" % d.month)
	var dd = String("%02d" % d.day)
	var m = String("%02d" % d.minute)

	return [WEEKDAYS[d.weekday], mm, dd, d.year, hour12, m, ampm]
