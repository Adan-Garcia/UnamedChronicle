extends Node2D

@onready var Worldstate := $WorldState
@onready var Cord := $Cord
@onready var Data := $Datagraber
@onready var Queue := $chatqueue
@onready var Players := $players
@export var towns: Dictionary[String,TownData]
@export var sectors: Dictionary[String,SectorData]
@export var empires: Dictionary[String,EmpireData]


func _ready():
	await get_tree().process_frame

	await get_tree().process_frame
	for e: EmpireData in Worldstate.CurrentWorldState.Empires.values():
		empires[e.name] = e
		for s: SectorData in e.Sectors.values():
			sectors[s.name] = s
			for t in s.towns.values():
				towns[t.name] = t
