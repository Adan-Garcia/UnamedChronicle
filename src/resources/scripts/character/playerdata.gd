extends Character
class_name PlayerData

# Skills unique to players
@export var Diplomacy: int = 10
@export var Deception: int = 10
@export var Insight: int = 10
@export var Crafting: int = 0
@export var Spellcasting: int = 0

# World interaction
@export var KnownLocations: Array[Address] = []
@export var Affiliations: Array[String] = []
@export var Reputation: Dictionary = {}

# Story flags and roleplay metadata
@export var PersonalGoal: String = ""
@export var Title: String = ""
@export var Milestones: Array[String] = []
@export var Oaths: Array[String] = []
@export var Secrets: Array[String] = []
