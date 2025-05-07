extends Resource
class_name SectorData

@export var id: int  # ID of province
@export var towns: Dictionary[String,TownData]  # Town Name, Town
@export var Cords: Vector2i  # Center Position
@export var name: String
