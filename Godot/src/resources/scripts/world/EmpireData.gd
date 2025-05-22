extends Resource
class_name EmpireData

enum Diplomacyenum { x = 0, Unknown = 0, Suspicion, Neutral, Friendly, Ally, Suzerain, Vassal }
@export var Sectors: Dictionary[String, SectorData]
@export var diplomacy: Dictionary[String,Diplomacyenum]  # Sector Name, Diplomacy level
@export var Cords: Vector2i  # Center Position
@export var neighbors: Array[String]  # Empire Names
@export var Area: int  # Area the Empire Spans
@export var Population: int  # Rural + Urban rounded
@export var name: String
@export var id: int
