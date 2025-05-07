extends Resource

class_name Character
@export_category("System Only")

@export var Origin: Address
@export var CurrentLocation: Address

@export_category("Modifiable")
@export var Name: String
# Mana (only used by some, but reusable for magical entities)
@export var Mana: int = 0
@export var Energy: float = 10.0
@export var Health: float = 10.0
# Primary traits (usable by all characters including enemies)
# Range: 0–20, average is 10
@export var Strength: int = 10
@export var Agility: int = 10
@export var Endurance: int = 10
@export var Intelligence: int = 10
@export var Charisma: int = 10

# Combat skills
@export var Melee: int = 10
@export var Ranged: int = 10
@export var Defense: int = 10

# Common utility skills (for stealth, AI pathing, or challenge types)
@export var Stealth: int = 10
@export var Tracking: int = 10
@export var Tactics: int = 10
@export var Perception: int = 10
